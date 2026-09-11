-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MultiPlayerWorldListPanel, superClass = CreateUIBehaviour("MultiPlayerWorldListPanel")
local super = superClass
local ESlateVisibility = import("ESlateVisibility")
local PlayWorldData = ModelManager:GetModel("PlayWorldData")
local InteractionTable = GetTableDefine("InteractionTable")
local PlayWorldNet = ModelManager:GetModel("PlayWorldNet")
local MPlayerPermissionModel = ModelManager:GetModel("MPlayerPermissionModel")
local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
local FriendIntimacyModel = ModelManager:GetModel("FriendIntimacyModel")
local NewFeaturesUnlockMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)
local Timer = require "GameCore.GameEvent.Timer";

local world_page_type = InteractionTable.WorldPageType
local PANEL_STATE = {
    None = 0,
    Refresh = 1,
    Filter = 2,
    Search = 3,
}
local MAX_TAB_NUM = 6
local REFRESH_CD_NUM = 0.2
local REFRESH_INTERNAL = 2
local PanelSetting =
{
    Elements =
    {
        { Name = "UIBtnRefresh", Handles = { OnClicked = "OnRefreshClicked", }, },
        { Name = "UIBtnSearch", Handles = { OnClicked = "OnSearchClicked", }, },
        { Name = "UIRefreshAndSearchBlock", },
        { Name = "UIInputBoxSearch", Type = "CommonInputBox", },
        { Name = "UITotalWorldListGroup", },
        { Name = "UIBtnFilter", Handles = { OnClicked = "OnTagFilterClick", }, },
        { Name = "EmptyLabel", },
        { Name = "UITotalWorldSwitcher", },
        { Name = "RobotContent",},
        { Name = "AssistPlayerTip",},
        { Name = "RobotWorldItem",},
        { Name = "UITotalWorldSearchSwitch"}
    },
    Behaviours =
    {
        { Name = "UITotalWorldListGroup", Type = "MultiPlayerWorldList", },
		{ Name = "UITabs", Count = MAX_TAB_NUM, },
        { Name = "RobotWorldItem", Type = "MultiPlayerWorldItem"}
    },
    Events =
    {
        ["NetEvent_PlayWorld_WorldBriefDataListReceived"] = "OnWorldBriefDataListReceived",
        ["NetEvent_PlayWorld_OnWorldHistoryListSaved"] = "OnWorldHistoryListChanged",
        ["NetEvent_PlayWorld_WorldFavoriteListChangeFinished"] = "OnWorldFavoriteListChanged",
        ["PullWorldDataByWorldType"] = "OnPullWorldDataByWorldType",
        ["NetEvent_PlayWorld_WorldTraceDataListReceived"] = "OnWorldTraceDataListReceived",
        ["mppme.CONFIRM_FILTER_TAG"] = "OnTagFilterConfirm", -- 选中筛选控件
        ["PlayWorldData_OnOnWatchPrivateBuildCountAllRsp"] = "OnWatchPrivateBuildCountAllRsp",
		["EventIntimacyDetailReceived"] = "OnIntimacyDetailReceived",
        ["OnWorldAssistRobotUpdated"] = "OnWorldAssistRobotUpdated"
    },
    Timers = {
        {
            Name = "RefreshCDTimer",
            Timer = Timer:Always(REFRESH_CD_NUM),
            Handler = "OnRefreshCD"
        }
    }
}

local total_world_switcher_type =
{
	search_group = 0, 
	empty_group = 1,
}
function MultiPlayerWorldListPanel:_init(go)
    super._init(self, go, PanelSetting)
    self.m_CurTabID = world_page_type.WorldBriefListPage
    self.m_NeedAppendTipsForNoResult = false
    self.m_RefreshCD = 0
end
function MultiPlayerWorldListPanel:OnInitialize()
	self:InitTab()
	
    self.UITotalWorldListGroup.ParentPanel = self
    self:SetActiveWidgetSearch()
    self.state = PANEL_STATE.None
    self.UIInputBoxSearch.UIEditText.OnTextChanged:Add(function()
        self:OnInputTextChanged()
    end)
end
function MultiPlayerWorldListPanel:OnDestroy()
    self._visibleScope:CloseEvent("MultiplayerPresearchTimer")
    self.UIInputBoxSearch.UIEditText.OnTextChanged:Clear()
    self:HandleLoadingGroup(false)
end
function MultiPlayerWorldListPanel:InitTab()
	for i = 1, #InteractionTable.WorldTabTable do
		local data = InteractionTable.WorldTabTable[i]
		if MAX_TAB_NUM >= i then
			self.UITabs[i]:SetTabText(data.text)
			self.UITabs[i]:SetIndex(i)
			self.UITabs[i]:SetClickCallback(function(index)
				self:OnTabClicked(index)
			end)
		end
	end
end
function MultiPlayerWorldListPanel:SetActiveWidgetSearch()
	self.UITotalWorldSwitcher:SetActiveWidgetIndex(total_world_switcher_type.search_group)
end
function MultiPlayerWorldListPanel:SetActiveWidgetEmpty()
	self.UITotalWorldSwitcher:SetActiveWidgetIndex(total_world_switcher_type.empty_group)
end

function MultiPlayerWorldListPanel:SetActivePlayerListSearch()
    UIUtil.SetWidgetVisible(self.UITotalWorldSearchSwitch,true)
end

function MultiPlayerWorldListPanel:SetActivePlayerListEmpty()
    UIUtil.SetWidgetVisible(self.UITotalWorldSearchSwitch,false)
end

function MultiPlayerWorldListPanel:OnRefreshClicked()
    if self.m_RefreshCD > 0 then
        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("操作过于频繁"))
        return
    end
	
 	self:QuitSearchState()
    self:ResetRefreshCD()
end
function MultiPlayerWorldListPanel:OnDataSet(bFromAssist)
	self:ShowWorldListByTab(world_page_type.WorldBriefListPage)
    if bFromAssist then
        local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
        if bUnlock == false then
            self:SwitchRobotAssistType(true)
        end
    end
	self:UpdateDataByReqServer()
end
function MultiPlayerWorldListPanel:FillWorldList(SubTabID, IsVisitBtn, itemDatas)
	self.UITotalWorldListGroup:FillWorldList(SubTabID, IsVisitBtn, self.ParentPanel.bFromAssist, itemDatas)
    self:HandleLoadingGroup(false)
end

function MultiPlayerWorldListPanel:OnTabClicked(index)
	if self.m_CurTabID ~= index then
		self:ShowWorldListByTab(index)
		self:OnTabChanged()
	end
end

function MultiPlayerWorldListPanel:OnTabChanged()
	if self.m_CurTabID == world_page_type.WorldPlayerListPage or
		self.m_CurTabID == world_page_type.WorldIntimacyListPage then
		self:UpdateDataByReqServer()
	end
end

function MultiPlayerWorldListPanel:OnInputTextChanged()
    self._visibleScope:CloseEvent("MultiplayerPresearchTimer")
    self._visibleScope:ListenEvent("MultiplayerPresearchTimer", Timer:Once(0.3),
    function()
        self:OnSearchClicked()
        self.m_NeedAppendTipsForNoResult = false
    end)

end
function MultiPlayerWorldListPanel:OnRefreshCD()
    if self.m_RefreshCD > 0 then
        self.m_RefreshCD = self.m_RefreshCD - REFRESH_CD_NUM
    end
end

function MultiPlayerWorldListPanel:MarkRefreshDirty()
	self.state = PANEL_STATE.Refresh
end

function MultiPlayerWorldListPanel:MarkSearchDirty()
	self.state = PANEL_STATE.Search
end

function MultiPlayerWorldListPanel:ResetRefreshCD()
    self.m_RefreshCD = REFRESH_INTERNAL
end

function MultiPlayerWorldListPanel:IsSearch()
	return self.state == PANEL_STATE.Search
end
function MultiPlayerWorldListPanel:ShowWorldListByTab(SubTabID)
    self.m_CurTabID = SubTabID
	for i = 1, MAX_TAB_NUM do
		self.UITabs[i]:SetUnSelected()
	end
	self.UITabs[SubTabID]:SetSelected()
	local configData = InteractionTable.WorldTabTable[SubTabID]
	if configData then
		if configData.showSearch == true then
			self.UIRefreshAndSearchBlock:SetVisibility(ESlateVisibility.Visible)
		else
			self.UIRefreshAndSearchBlock:SetVisibility(ESlateVisibility.Hidden)
		end
	end

    UIUtil.SetWidgetVisible(self.RobotContent,false)
    UIUtil.SetWidgetVisible(self.AssistPlayerTip,false)
    
    self:SetActivePlayerListSearch()
	
    if SubTabID == world_page_type.WorldBriefListPage 
		or SubTabID == world_page_type.WorldPlayerListPage then
		self.UITabs[world_page_type.WorldBriefListPage]:SetSelected()
		self.UITabs[world_page_type.WorldPlayerListPage]:SetSelected()
        self:FillWorldList(SubTabID, true)
        if self.ParentPanel.bFromAssist then
            local MultiModel = ModelManager:GetModel("MultiPlayerModel")
            local ResInviteAssistConfig = ConfigManager.GetTable("ResInviteAssist")
            local AssistCfg = ResInviteAssistConfig:GetRowByKey( MultiModel.AssistId)
            local bCanReqBot = false
            for index = 0, 4 do
                if AssistCfg.BotId[index] > 0 then
                    bCanReqBot = true
                end
            end
            if bCanReqBot then
                UIUtil.SetWidgetVisible(self.RobotContent,true)
                UIUtil.SetWidgetVisible(self.AssistPlayerTip,true)
                local CurExsitRob = UE4.PzTeamFunctionLibrary.GetCurrentRobotID(_G.GlobalContext)
                if CurExsitRob > 0 then
                    self.RobotWorldItem:SetAssistRobot(CurExsitRob)
                else
                    self.RobotWorldItem:SetAssistRobot(AssistCfg.BotId[0])
                end
            else
                UIUtil.SetWidgetVisible(self.RobotContent,false)
                UIUtil.SetWidgetVisible(self.AssistPlayerTip,false)
            end

            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
            if bUnlock == false then
               self:SetActivePlayerListEmpty()
            end
        end
    elseif SubTabID == world_page_type.WorldFavoriteListPage then
        self:FillWorldList(SubTabID, true)
        
    elseif SubTabID == world_page_type.WorldHistoryListPage then
        self:FillWorldList(SubTabID, false)
        
	elseif SubTabID == world_page_type.WorldIntimacyListPage then
		self:FillWorldList(SubTabID, true)
		
    elseif SubTabID == world_page_type.WorldTraceDataListPage then
        local MultiPlayerComponent = UE4.PzMultiPlayerLibrary.GetMultiPlayerComponent(_G.GlobalContext)
        local worldIdList = {}
        local worldIdCache = {}
        local worldTombBriefs = MultiPlayerComponent:GetWorldTombBriefs()
        local len = worldTombBriefs:Num()
        for i = 1, len do
            local tempBrief = worldTombBriefs:Get(i - 1)
            if tempBrief.TombCnt > 0 then
                if worldIdCache[tempBrief.RealmId] == nil then
                    table.insert(worldIdList, tempBrief.RealmId)
                    worldIdCache[tempBrief.RealmId] = true
                end
            end
        end
        local worldPrivateBuildBriefs = MultiPlayerComponent:GetWorldPrivateBuildBriefs()
        len = worldPrivateBuildBriefs:Num()
        for i = 1, len do
            local tempBrief = worldPrivateBuildBriefs:Get(i - 1)
            if tempBrief.BuildCnt > 0 then
                if worldIdCache[tempBrief.RealmId] == nil then
                    table.insert(worldIdList, tempBrief.RealmId)
                    worldIdCache[tempBrief.RealmId] = true
                end
            end
        end
        if #worldIdList > 0 then
            self:ReqServerData(InteractionTable.WorldServerReqType.Trace, worldIdList)
        else
            self:FillWorldList(SubTabID, true)
        end
    end
end
function MultiPlayerWorldListPanel:SwitchRecommendType(bRecommendWorld)
    self.UITabs[world_page_type.WorldBriefListPage]._target:SetVisibility(bRecommendWorld
		and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
	self.UITabs[world_page_type.WorldPlayerListPage]._target:SetVisibility(bRecommendWorld
		and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
end

function MultiPlayerWorldListPanel:SwitchRobotAssistType(bRobotAssist)
    self.UITabs[world_page_type.WorldIntimacyListPage]._target:SetVisibility(bRobotAssist
		and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
    self.UITabs[world_page_type.WorldFavoriteListPage]._target:SetVisibility(bRobotAssist
    and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
    self.UITabs[world_page_type.WorldHistoryListPage]._target:SetVisibility(bRobotAssist
    and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
    self.UITabs[world_page_type.WorldTraceDataListPage]._target:SetVisibility(bRobotAssist
    and ESlateVisibility.Collapsed or ESlateVisibility.Visible)
end
function MultiPlayerWorldListPanel:OnWorldBriefDataListReceived()
	if self:IsSearch() then
		self:EndSearch(PlayWorldData.m_WorldBriefDataList)
	end
	
    if self.m_CurTabID == world_page_type.WorldBriefListPage or self.m_CurTabID == world_page_type.WorldPlayerListPage then
        self:ShowWorldListByTab(world_page_type.WorldBriefListPage)
        self:FillWorldList(self.m_CurTabID, true)
    end
   
    local rid = GameUtil.GetMyPlayerRID()
    MultiPlayerMgr:Svr_ReqWatchTombCountAll(rid)
    MultiPlayerMgr:Svr_ReqWatchPrivateBuildCountAll(rid)
end

function MultiPlayerWorldListPanel:OnWorldHistoryListChanged()
    if self.m_CurTabID == world_page_type.WorldHistoryListPage then
        self:FillWorldList(self.m_CurTabID, true)
    end
end

function MultiPlayerWorldListPanel:OnWorldFavoriteListChanged()
    if self.m_CurTabID == world_page_type.WorldFavoriteListPage then
        self:FillWorldList(self.m_CurTabID, true)
    end
end

function MultiPlayerWorldListPanel:OnWorldTraceDataListReceived()
    if self.m_CurTabID == world_page_type.WorldTraceDataListPage then
        self:FillWorldList(self.m_CurTabID, true)
    end
end

function MultiPlayerWorldListPanel:OnIntimacyDetailReceived()
	if self.m_CurTabID == world_page_type.WorldIntimacyListPage then
		self:FillWorldList(self.m_CurTabID, true)
	end
end
function MultiPlayerWorldListPanel:UpdateDataByReqServer()
	if self.m_CurTabID == world_page_type.WorldBriefListPage or
		self.m_CurTabID == world_page_type.WorldPlayerListPage then
		local bFromAssist = self.ParentPanel.bFromAssist
		if bFromAssist then
			self:ReqServerData(InteractionTable.WorldServerReqType.Assist)
		else
			self:ReqServerData(InteractionTable.WorldServerReqType.Default)
		end
		self:SwitchRecommendType(not bFromAssist)
	elseif self.m_CurTabID == world_page_type.WorldIntimacyListPage then
		self:ReqServerData(InteractionTable.WorldServerReqType.IntimacyDetail)
	end
end
function MultiPlayerWorldListPanel:ReqServerData(dataType, param)
    if dataType == InteractionTable.WorldServerReqType.Default then
        if self.ParentPanel.RefreshHanging then
        else
            PlayWorldNet:PullWorldBriefList_Default()
            self:HandleLoadingGroup(true)
        end
    elseif dataType == InteractionTable.WorldServerReqType.World_Search then
        PlayWorldNet:PullWorldBriefList_OwnerName(param)
        self:HandleLoadingGroup(true)
    elseif dataType == InteractionTable.WorldServerReqType.Trace then
        PlayWorldNet:PullWorldTraceList_Default(param)
        self:HandleLoadingGroup(true)
    elseif dataType == InteractionTable.WorldServerReqType.Assist then
        local MultiModel = ModelManager:GetModel("MultiPlayerModel")
        local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
        if bUnlock == true then
            UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):PullAssistRecommendData(MultiModel.AssistId)
            self:HandleLoadingGroup(true)
        end
	elseif dataType == InteractionTable.WorldServerReqType.Intimacy_Search then
		local results = FriendIntimacyModel:OnIntimacyNameSearch(param)
		self:EndSearch(results)
	elseif dataType == InteractionTable.WorldServerReqType.IntimacyDetail then
		local bResult = FriendIntimacyModel:UpdateIntimacyDetail()
		if bResult then
			self:HandleLoadingGroup(true)
		else
			self:OnIntimacyDetailReceived()
		end
    end
	
    PlayWorldData:ForceRefreshFavoriteAndHistoryList()
end

function MultiPlayerWorldListPanel:HandleLoadingGroup(bool)
	if bool == true then
		self:FillWorldList(-1)
	end
    self.ParentPanel:HandleLoadingGroup(bool)
end
function MultiPlayerWorldListPanel:OnSearchClicked()
	local searchText = self.UIInputBoxSearch:GetInputText()
	
	if string.isNilOrEmpty(searchText) then
		self:QuitSearchState()
		return
	end
	
	self:SetSearchState(searchText)
end
function MultiPlayerWorldListPanel:SetSearchState(searchText)
	self:MarkSearchDirty()

	if self.m_CurTabID == world_page_type.WorldBriefListPage or
		self.m_CurTabID == world_page_type.WorldPlayerListPage then
		
		self:ReqServerData(InteractionTable.WorldServerReqType.World_Search, searchText)
	elseif self.m_CurTabID == world_page_type.WorldIntimacyListPage then
		
		self:ReqServerData(InteractionTable.WorldServerReqType.Intimacy_Search, searchText)
	end
	self.m_NeedAppendTipsForNoResult = true
end

function MultiPlayerWorldListPanel:EndSearch(results)
	if not results then
		return
	end
	if not next(results) and self.m_NeedAppendTipsForNoResult then
		EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, InteractionTable.TipsForNoSearchResult)
		self.m_NeedAppendTipsForNoResult = false
	end
	
	if self.m_CurTabID == world_page_type.WorldIntimacyListPage then
		self:FillWorldList(self.m_CurTabID, true, results)
	end
end
function MultiPlayerWorldListPanel:QuitSearchState()
	self:MarkRefreshDirty()
	self:UpdateDataByReqServer()
end

function MultiPlayerWorldListPanel:OnTagFilterClick()
    -- Implementation omitted.
end

function MultiPlayerWorldListPanel:OnTagFilterConfirm()
    -- Implementation omitted.
end

function MultiPlayerWorldListPanel:OnWorldAssistRobotUpdated()
    if self.ParentPanel.bFromAssist then
        local MultiModel = ModelManager:GetModel("MultiPlayerModel")
        local ResInviteAssistConfig = ConfigManager.GetTable("ResInviteAssist")
        local AssistCfg = ResInviteAssistConfig:GetRowByKey( MultiModel.AssistId)
        local bCanReqBot = false
        for index = 0, 4 do
            if AssistCfg.BotId[index] > 0 then
                bCanReqBot = true
            end
        end
        if bCanReqBot then
            local CurExsitRob = UE4.PzTeamFunctionLibrary.GetCurrentRobotID(_G.GlobalContext)
            if CurExsitRob > 0 then
                self.RobotWorldItem:SetAssistRobot(CurExsitRob)
            else
                self.RobotWorldItem:SetAssistRobot(AssistCfg.BotId[0])
            end
        end
    end
end

function MultiPlayerWorldListPanel:SetTagFilterState(curTagList)
    -- Implementation omitted.
end

function MultiPlayerWorldListPanel:OnPullWorldDataByWorldType(worldType)
    if worldType == UE4.PullZoneDataWorldType.TAG_FILTER then
        self:ShowWorldListByTab(world_page_type.WorldBriefListPage)
    end
    if worldType == UE4.PullZoneDataWorldType.DEFAULT and self.ParentPanel.bFromAssist then
        self:ShowWorldListByTab(world_page_type.WorldBriefListPage)
    end
end

function MultiPlayerWorldListPanel:OnWatchPrivateBuildCountAllRsp(e, r, ...)
    -- Implementation omitted.
end
return MultiPlayerWorldListPanel
