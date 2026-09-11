-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MultiPlayerWorldItem, superClass = CreateUIBehaviourFromListItem("MultiPlayerWorldItem")
local super = superClass
local ESlateVisibility = import("ESlateVisibility")
local InteractionTable = GetTableDefine("InteractionTable")
local PlayWorldData = ModelManager:GetModel("PlayWorldData")
local PlayWorldNet = ModelManager:GetModel("PlayWorldNet")
local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
local FriendModel = ModelManager:GetModel("FriendModel")
local MultiPlayerModel = ModelManager:GetModel("MultiPlayerModel")
local MultiPlayerWorldTable = GetTableDefine("MultiPlayerWorldTable")
local FriendIntimacyModel = ModelManager:GetModel("FriendIntimacyModel")
local MPlayerPermissionModel = ModelManager:GetModel("MPlayerPermissionModel")
local PvpFairRobotTable = ConfigManager.GetTable("ResPvpFairRobotCfg")
local PanelSetting =
{
    Elements =
    {
        { Name = "UITotalGroup", },
        { Name = "UIWorldName", },
        { Name = "UIVisitorCount", },
        { Name = "UIMaxVisitor", },
        { Name = "UISettlerCount", },
        { Name = "UIMaxSettler", },
        { Name = "UICollectImage", },
        { Name = "UITimeStr", },
        { Name = "UICollectBtnGroup", },
        { Name = "TagText", },
        { Name = "UIInviteVisitBtnGroup", Type = UE4.WidgetSwitcher },
        { Name = "loading", },
        { Name = "UIBtnCollect", Handles = { OnClicked = "OnCollectClicked", }, },
        { Name = "UIBtnNoCollect", Handles = { OnClicked = "OnNoCollectClicked", }, },
        { Name = "UIBtnSelect", Handles = { OnClicked = "OnSelectClicked", }, },
        { Name = "UIBtnVisit", Handles = { OnClicked = "OnVisitClicked", }, },
        { Name = "UIBtnRequestVisit", Handles = { OnClicked = "OnRequestVisitClicked", }, },
        { Name = "VisitorDescBtn", Handles = { OnClicked = "OnVisitorDescClicked", }, },
        { Name = "SettlerDescBtn", Handles = { OnClicked = "OnSettlerDescClicked", }, },
        { Name = "UIBtnAddFriend", Handles = { OnClicked = "OnAddFriendClicked", }, },
        { Name = "UIAlreadyFriend", },
        { Name = "UIAddFriendSwitch", },
        { Name = "UIReqAssistSwitcher"},
        { Name = "UIPlayerIntimacyGroup", },
        { Name = "UIPlayerIntimacyIcon", },
        { Name = "UIPlayerIntimacy", },
        { Name = "UIGenderImg", },
        { Name = "HintBtn", Handles = { OnClicked = "OnHintClick", }, },
        { Name = "UIBtnRequestAssist", Handles = { OnClicked = "OnRequestAssist"}},
        {
            Name = "UIPlayerIntimacyBtn",
            Handles =
            {
                OnClicked = "OnBtnOpenIntimacyDesc",
            },
        },
        { Name = "VisitorInfo", },
        { Name = "SettlerInfo", },
        { Name = "UIRejected", },
        { Name = "UIInMyWorld", },
        { Name = "UIOffLine", },
    },
    Behaviours =
    {
        { Name = "PlayerLabelContainer", Type = "PlayerLabelContainer", },
		{ Name = "UIHeadIconPanel" },
    },
    Events =
    {
        ["NetEvent_PlayWorld_WorldFavoriteListChangeFinished"] = "OnWorldFavoriteListChangeFinished",
        ["NetEvent_PlayWorld_OnMyZoneCanVisitRecordsChanged"] = "OnMyZoneCanVisitRecordsChanged",
        ["NetEvent_PlayWorld_OnMyZoneVisitApplyRecordsChanged"] = "RefreshWaitAnim",
        ["NetEvent_PlayWorld_SettlementInfoUpdated"] = "RefreshWaitAnim",

        ["FriendAddEvent"] = "OnFriendChanged",
        ["FriendDelete"] = "OnFriendChanged",
        ["FriendSendReqListChanged"] = "OnSendReqListChanged",
        ["PlayWorldData_OnWatchTombCountAllRsp"] = "OnWatchTombCountAllRsp",
        ["PlayWorldData_OnMyVisitNotify"] = "OnMyVisitNotify",
        ["OnInviteAssistRefresh"] = "OnInviteAssistRefresh",
        ["FriendUpdateEvent"] = "OnFriendUpdateEvent", -- 玩家信息更新
        ["PlayWorldData_OnOnWatchPrivateBuildCountAllRsp"] = "OnWatchPrivateBuildCountAllRsp",
        ["OnWorldAssistRobotUpdated"] = "OnWorldAssistRobotUpdated",

		["NetEvent_PlayWorld_DelFavoriteSucceeded"] = "OnFavoriteDelSucceeded",
		["NetEvent_PlayWorld_AddFavoriteSucceeded"] = "OnFavoriteAddSucceeded",
    }
}

local WorldVisitSwitchType =
{
    Loading = 0,
    Visit = 1,
    RequestVisit = 2,
    Invite = 3,
    AlreadyInvite = 4,
    AlreadyJoined = 5,
    AlreadyRequested = 6,
    Rejected = 7,
    ShowTime = 8,
    Forbiden = 9,
    InMyWorld = 10,
}
function MultiPlayerWorldItem:_init(go)
    super._init(self, go, PanelSetting)
    self.data = {}
    self.IsBtnJoin = true
    self.IsNoNeedAccept = false --是否无需申请直接前往
    self.IsInMoreBtnCD = false --按钮是否处于CD中，防止点击太快
    self.RobotID = 0 --用于支援机器人的假Item
end
function MultiPlayerWorldItem:OnDataSet(itemData)
    self.IsInMoreBtnCD = false

    self.data = itemData or {}
    self.VisitorInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.SettlerInfo:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.data.WorldGUID == nil and self.RobotID == 0 then
    	return
    end

	self.UITotalGroup:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
	self.UIWorldName:SetText(string.format("<D28>%s</>", self.data.PlayerName))
	local genderPath = GetGenderIcon(self.data.OwnerGender)
	UIUtil.SetImagePathAsync(self.UIGenderImg, genderPath, false)
    if self.RobotID == 0 then
        self.PlayerLabelContainer:SetDataByPlayerId(self.data.OwnerRID,
            OtherPlayerTable.EGatherClientType.MultiplayerManagerPanel)
    end

	self:RefreshVisitoHistoryDesc()
	self.UIVisitorCount:SetText(tostring(self.data.MemberTotalCount))
	self.UIMaxVisitor:SetText(tostring(PlayWorldData.m_MaxVisitorCount))
	self.UISettlerCount:SetText(tostring(self.data.SettlerCount))
	self.UIMaxSettler:SetText(tostring(PlayWorldData.m_MaxSettlerCount))
	local headIconParams = {}
	if self.data.IconIdx ~= nil then
		headIconParams.Icon = self.data.IconIdx
	end
	if self.data.OwnerLevel ~= nil then
		headIconParams.Level = self.data.OwnerLevel
	end
	if self.data.IsOnline ~= nil then
		headIconParams.IsOnline = self.data.IsOnline
	end
	self.UIHeadIconPanel:RefreshPanel(headIconParams)
	
	if self.data.VisitTimestamp ~= 0 then
		self.UITimeStr:SetText(InteractionTable.GetVisitTimeString(self.data.VisitTimestamp) .. LocalizationFText.FromStr("访问过").str)
	elseif self.data.LastOnlineTime ~= 0 then
		self.UITimeStr:SetText(InteractionTable.GetVisitTimeString(self.data.LastOnlineTime) .. LocalizationFText.FromStr("在线").str)
	else
		self.UITimeStr:SetText("")
	end

	self:ResetHoveredAnim()
	self:RefreshWaitAnim()
	self:RefreshCollectImage()
	self:RefreshFriendBtnVisible()
	self:RefreshHintBtn()
	self:RefreshAssistGroup()
end

function MultiPlayerWorldItem:SetAssistRobot(RobotID)
    self.RobotID = RobotID
    local RobotCfg = PvpFairRobotTable:GetRowByKey(self.RobotID)
    local itemData = {}

	itemData.Index = 0
    itemData.IsShowRecommendPlayer = true
	itemData.OwnerName = RobotCfg.BotName

	itemData.WorldName = RobotCfg.BotName
	itemData.OwnerLevel = RobotCfg.BotLevel
	itemData.OwnerGender = RobotCfg.BotGender
	
	itemData.IsOnline = true
    itemData.IconIdx = RobotCfg.BotIcon
	itemData.PlayerName = RobotCfg.BotName
	
    self:OnDataSet(itemData)
    if self.RobotID > 0 then
        self.UICollectBtnGroup:SetVisibility(ESlateVisibility.Collapsed)
    end
end
function MultiPlayerWorldItem:RefreshHintBtn(byEvent)
    -- Implementation omitted.
end

function MultiPlayerWorldItem:RefreshVisitoHistoryDesc()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnSelected(isSelected)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:RefreshCollectImage()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnWorldFavoriteListChangeFinished()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnMyZoneCanVisitRecordsChanged(e, r, RealmIds)
    -- Implementation omitted.
end

function MultiPlayerWorldItem:OnMyVisitNotify(e, r, RealmId)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:ResetHoveredAnim()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:RefreshWaitAnim(event, response, ...)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnVisitClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnRequestVisitClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnSelectClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnCollectClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnNoCollectClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:RefreshItem()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnVisitorDescClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnSettlerDescClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnWorldFavoriteListChanged(e, r, WorldGUID, IsFavorite)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:RefreshCollectBtnGroup()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:RefreshAssistGroup()
    if self.data == nil then return end
    if self.data.IsShowRecommendPlayer then
        self.UIInviteVisitBtnGroup:SetVisibility(ESlateVisibility.Collapsed)
        self.UIAddFriendSwitch:SetVisibility(ESlateVisibility.Collapsed)
        self.UIReqAssistSwitcher:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.UIInviteVisitBtnGroup:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.UIAddFriendSwitch:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.UIReqAssistSwitcher:SetVisibility(ESlateVisibility.Collapsed)
    end
     if self.data.IsShowRecommendPlayer then
        if self.RobotID > 0 then
            local CurExsitRob = UE4.PzTeamFunctionLibrary.GetCurrentRobotID(_G.GlobalContext)
            if CurExsitRob > 0 then
                self.UIReqAssistSwitcher:SetActiveWidgetIndex(2)
                return
            end
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(0) 
            return
        end
        self:RefreshAssistState()
        local playerId = self.data.OwnerRID
        OtherPlayerModel.OnPlayerAttrReq({ playerId }, function()
            local record = OtherPlayerModel.GetPlayerAttrInCache(playerId)
            if record then
                self:RefreshAssistState()
            end
        end, true)
    end
end

function MultiPlayerWorldItem:RefreshAssistState()
    if self.data == nil or self.data.OwnerRID == nil then return end
    if self.data.VisitTimestamp ~= 0 then
		self.UIOffLine:SetText(InteractionTable.GetVisitTimeString(self.data.VisitTimestamp) .. LocalizationFText.FromStr("访问过").str)
	elseif self.data.LastOnlineTime ~= 0 then
		self.UIOffLine:SetText(InteractionTable.GetVisitTimeString(self.data.LastOnlineTime) .. LocalizationFText.FromStr("在线").str)
	else
		self.UIOffLine:SetText(LocalizationFText.FromStr("离线"))
	end

    self.UIReqAssistSwitcher:SetActiveWidgetIndex(4)
    local record = OtherPlayerModel.GetPlayerAttrInCache(self.data.OwnerRID)
    if self.data.IsOnline ~= nil then
		if self.data.IsOnline then
            if record.CurrentMapId ~= nil then
                local NeedMarked = UE4.PzGameLuaLibrary.IsMarkedMapBusy(_G.GlobalContext, record.CurrentMapId)
                if NeedMarked then
                    self.UIReqAssistSwitcher:SetActiveWidgetIndex(3)
                else
                    local bAssistValid = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):IsAssistPlayerValid(self.data.OwnerRID)
                    if bAssistValid then
                        self.UIReqAssistSwitcher:SetActiveWidgetIndex(0)
                        self._target:StopAnimation(self._target["BtnWaiting"])
                    else
                        self.UIReqAssistSwitcher:SetActiveWidgetIndex(1)
                        self._target:PlayAnimation(self._target["BtnWaiting"], 0, 0, UE4.EUMGSequencePlayMode.Forward, 1, false)
                    end
                end
            end
        end
    end
end

function MultiPlayerWorldItem:OnWorldAssistRobotUpdated()
    self:RefreshAssistGroup()
end
local friend_switcher_type =
{
    none = 0,
    friend = 1,
    send_request = 2,
}
function MultiPlayerWorldItem:RefreshFriendBtnVisible()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnAddFriendClicked()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnFriendChanged(e, r, relationId, playerId)
    -- Implementation omitted.
end

function MultiPlayerWorldItem:OnSendReqListChanged(e, r, playerRID)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnHintClick()
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnBtnOpenIntimacyDesc()
    -- Implementation omitted.
end

function MultiPlayerWorldItem:OnWatchTombCountAllRsp(e, r, ...)
    -- Implementation omitted.
end

function MultiPlayerWorldItem:OnWatchPrivateBuildCountAllRsp(e, r, ...)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnRequestAssist(e, r)
    if self.RobotID > 0 then
        local MultiModel = ModelManager:GetModel("MultiPlayerModel")
        UE4.PzMultiPlayerLibrary.GenerateAssistRobotReq(_G.GlobalContext, MultiModel.AssistId)
    else
        if UE4.PzBlueprintLibrary.IsFakeDS() then
            local MessageBoxParam = {
                DescText = LocalizationFText.FromStr("对方接受邀请后会有<D26>短暂加载</>,确定邀请吗?"),
                ButtonLayout = "ok_cancel",
                ConfirmBtnText = LocalizationFText.FromStr("确认"),
                CancelBtnText = LocalizationFText.FromStr("取消"),
                IsBGClickedAutoHide = true,
                ConfirmLambda = function()
                    local MultiModel = ModelManager:GetModel("MultiPlayerModel")
                    UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):RequestAssistPlayer(self.data.OwnerRID, MultiModel.AssistId)
                end,
                CancelLambda = function() end
            }
            EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
        else
            local MultiModel = ModelManager:GetModel("MultiPlayerModel")
            UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):RequestAssistPlayer(self.data.OwnerRID, MultiModel.AssistId)
        end
    end
end

function MultiPlayerWorldItem:OnInviteAssistRefresh(e,r)
    if self.RobotID > 0 then
        local CurExsitRob = UE4.PzTeamFunctionLibrary.GetCurrentRobotID(_G.GlobalContext)
        if CurExsitRob > 0 then
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(2)
            return
        end 
    else
        self:RefreshAssistState()
    end
end
function MultiPlayerWorldItem:OnFriendUpdateEvent(_, _, relationId, playerId)
    if self.data and self.data.OwnerRID == playerId then
        self:RefreshFriendBtnVisible()
    end
end
function MultiPlayerWorldItem:OnFavoriteDelSucceeded(_,_,realmId)
    -- Implementation omitted.
end
function MultiPlayerWorldItem:OnFavoriteAddSucceeded(_,_,realmId)
    -- Implementation omitted.
end
return MultiPlayerWorldItem
