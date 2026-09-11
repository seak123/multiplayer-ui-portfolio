-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MultiPlayerPanel, superClass = CreateUIBehaviour("MultiPlayerPanel")
local super = superClass
local PlayWorldData = ModelManager:GetModel("PlayWorldData")
local InteractionTable = GetTableDefine("InteractionTable")
local WorldProgressModel = ModelManager:GetModel("WorldProgressModel")
local NewFeaturesUnlockMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)
local MPlayerPermissionModel = ModelManager:GetModel("MPlayerPermissionModel")
local SocialModel = ModelManager:GetModel("SocialModel")
local Timer = require "GameCore.GameEvent.Timer"
local MyScope = GScope.Scope.Create("globe.ui.MultiPlayerPanel")
local LOADING_TIMER = "mpp.LOADING_TIMER"
local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
local PanelSetting =
{
    Elements =
    { -- tab
        { Name = "TabGroup", },
        { Name = "UIBtnClose", Handles = { OnClicked = "OnCloseClicked", }, },
        { Name = "UIBtnBGClose", Handles = { OnClicked = "OnBtnBGClose", }, },

        { Name = "UICurTabText", },
        { Name = "ContentSwitcher", },
        { Name = "LoadingGroup", },
        {
            Name = "WorldAccessPermissionsCheckBox",
            Handles =
            {
                OnCheckStateChanged = "OnWorldAccessPermissionsStateChanged",
            }
        },
        { Name = "WorldAccessPermissionsTitle", },
        { Name = "UIMultiplayerTitle", },
        { Name = "WorldAccessPermissionsGroup", },
        { Name = "ReturnToMyWorldGroup", },
        { Name = "UIBtnReturnToMyWorld", Handles = { OnClicked = "OnRetureMyWorld", }, },
        { Name = "ReturnToSettledWorldGroup", },
        { Name = "UIBtnReturnToSettledWorld", Handles = { OnClicked = "OnRetureToSettledWorld", }, },
        { Name = "WorldListTagFilterCloseBtn", Handles = { OnClicked = "OnTagFilterClose", }, },
        { Name = "WorldListTagFilterGroup", },

    },
    Behaviours =
    {
        { Name = "UIWorldListPanel", Type = "MultiPlayerWorldListPanel", }, --世界列表总界面
        { Name = "SettlementManagePanel", },
        { Name = "UIFriendListPanel", }, --好友列表
        { Name = "WBP_MPlayer_TagFilterList", },

    },
    Events =
    {
        ["Multiplayer_SwtichToWorldList"] = "SwitchToWorldList",
        ["NetEvent_PlayWorld_OnQuitSettlement"] = "OnCloseClicked",
        ["OnSystemFunctionStatusUnlock"] = "OnSysFuncUnlock",
        ["OnSystemFunctionStatusUpdate"] = "OnSysFuncSync",
        ["NetEvent_PlayWorld_MyWorldDataSaved"] = "RefreshWorldAccessPermission",
    }
}

local TabGroupData =
{
    {
        CustomName = "MyWorldManage",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.MyWorldManage,
        VisibleCond = function()
            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
            return bUnlock
        end,
    },
    {
        CustomName = "WorldListPanel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.WorldListPanel,
        VisibleCond = function()
            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
            return bUnlock
        end,
    },
    {
        CustomName = "FriendListPanel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.FriendListPanel,
        RedHintType = function()
			local hintTypes = {}
			
			local relationModel = ModelManager:GetModel("RelationModel")
			table.insert(hintTypes, relationModel:GetRelationEnergyHintType())
			
			return hintTypes
        end,
    },
    {
        CustomName = "WorldLevel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.WorldLevel,
        RedHintType = function()
            return WorldProgressModel:GetLevelEntranceRedHintTypes()
        end,
        VisibleCond = function()
            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_WORLDPROGRESS)
            return bUnlock
        end,
    },
}

local TabAssistGroupData =
{
    {
        CustomName = "MyWorldManage",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.MyWorldManage,
        VisibleCond = function()
            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_MULTIPLAYER)
            return bUnlock
        end,
    },
    {
        CustomName = "WorldListPanel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.WorldListPanel,
        VisibleCond = function()
            return true --支援界面里，玩家列表必须显示
        end,
    },
    {
        CustomName = "FriendListPanel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.FriendListPanel,
        RedHintType = function()
			local hintTypes = {}
			
			local relationModel = ModelManager:GetModel("RelationModel")
			table.insert(hintTypes, relationModel:GetRelationEnergyHintType())
			
			return hintTypes
        end,
    },
    {
        CustomName = "WorldLevel",
        CustomTabId = InteractionTable.MultiplayerPanelContentType.WorldLevel,
        RedHintType = function()
            return WorldProgressModel:GetLevelEntranceRedHintTypes()
        end,
        VisibleCond = function()
            local bUnlock = NewFeaturesUnlockMgr:IsFeatureUnlock(ResMacros.E_SYS_FUNC_UNLOCK_WORLDPROGRESS)
            return bUnlock
        end,
    },
}

local content_switcher_type =
{
	world_manager_panel = 0, -- 权限管理
	world_list_panel = 1, -- 玩家列表
	friend_list_panel = 2, -- 好友列表
}
function MultiPlayerPanel:_init(go)
    super._init(self, go, PanelSetting)
    self.m_BindModel = nil
    self.m_LastLoadingStartTime = 0
end
function MultiPlayerPanel:OnInitialize()
    self.UIWorldListPanel.TagFliterPanel = self.WBP_MPlayer_TagFilterList
    self.UIWorldListPanel.TagFilterGroup = self.WorldListTagFilterGroup
    self.UIWorldListPanel.ParentPanel = self
    self.UIFriendListPanel.ParentPanel = self
    self.SettlementManagePanel.ParentPanel = self
    self.WorldListTagFilterGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.WorldAccessPermissionsGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    TabUtil.SetTabGroupData(self.TabGroup, TabGroupData)
    self.bFromAssist = false --由支援交互进入

    self.TabGroup.OnSelectTabChange:Add(
        function(index)
            self:OnSelectTabChange(index)
        end
    )
end

function MultiPlayerPanel:OnStart()
    self.RefreshHanging = false
end
function MultiPlayerPanel:OnDestroy()
    MPlayerPermissionModel:ClearModel()
    SocialModel:ClearModel()
    self.TabGroup.OnSelectTabChange:Clear()
end
function MultiPlayerPanel:OnMyShowPanel(tabIndex, fromAssist)
    PlayWorldData.RefusedCache = {}
    if fromAssist then
        self.bFromAssist = true
        TabUtil.SetTabGroupData(self.TabGroup, TabAssistGroupData)
    else
        self.bFromAssist = false
    end
    if tabIndex then
        self:SelectTabId(tabIndex)
    else
        if not PlayWorldData:IsSingleWorld() or PlayWorldData:AmISettled() then
            self:SelectTabId(InteractionTable.MultiplayerPanelContentType.MyWorldManage)
        else
            self:SelectTabId(InteractionTable.MultiplayerPanelContentType.WorldListPanel)
        end
    end
    MultiPlayerMgr:PullMyWorldReq()
    MultiPlayerMgr:PullSettledWorldReq()
    MultiPlayerMgr:PullPlayWorldReq()

end

function MultiPlayerPanel:RefreshWorldAccessPermission()
    -- Implementation omitted.
end
function MultiPlayerPanel:OnMyHidePanel()
end
function MultiPlayerPanel:RefreshTitleText()
    local TabName = self.TabGroup:GetSelectedTab().NormalShowText.Text
    self.UICurTabText:SetText(TabName)
    if PlayWorldData:CanBackToOriginalWorld() then
        self.ReturnToMyWorldGroup:SetVisibility(UE4.ESlateVisibility.Visible)
    else
        self.ReturnToMyWorldGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
    if PlayWorldData:CanBackToSettledWorld() then
        self.ReturnToSettledWorldGroup:SetVisibility(UE4.ESlateVisibility.Visible)
    else
        self.ReturnToSettledWorldGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
end
function MultiPlayerPanel:ShowTab(NewTabID)
    if NewTabID == InteractionTable.MultiplayerPanelContentType.MyWorldManage then
        self.UIMultiplayerTitle:SetText(LocalizationFText.FromStr("多人游戏"))
        self.ContentSwitcher:SetActiveWidgetIndex(content_switcher_type.world_manager_panel)
        self.SettlementManagePanel:OnMyShowPanel()
        self:HandleLoadingGroup(false)
    elseif NewTabID == InteractionTable.MultiplayerPanelContentType.WorldListPanel then
        self.UIMultiplayerTitle:SetText(LocalizationFText.FromStr("多人游戏"))
        self.ContentSwitcher:SetActiveWidgetIndex(content_switcher_type.world_list_panel)
        self.UIWorldListPanel:OnDataSet(self.bFromAssist)
    elseif NewTabID == InteractionTable.MultiplayerPanelContentType.FriendListPanel then
        self.UIMultiplayerTitle:SetText(LocalizationFText.FromStr("多人游戏"))
        self.ContentSwitcher:SetActiveWidgetIndex(content_switcher_type.friend_list_panel)
        self.UIFriendListPanel:RefreshView()
        self:HandleLoadingGroup(false)
    end
    self:RefreshTitleText()
end
function MultiPlayerPanel:SelectTabId(tabId)
    for i = 1, #TabGroupData do
        local tabConfig = TabGroupData[i]
        if tabConfig.CustomTabId == tabId then
            self:SelectTabIndex(i)
        end
    end
end
function MultiPlayerPanel:SwitchToWorldList()
    self:SelectTabId(InteractionTable.MultiplayerPanelContentType.WorldListPanel)
end
function MultiPlayerPanel:SelectTabIndex(index)
    if index then
        local realIndex = TabUtil.CheckTabGroupSelectIndexValid(self.TabGroup, index)
        self.TabGroup:SetSelectTabIndex(realIndex)
    end
end
function MultiPlayerPanel:OnSelectTabChange(index)
    local tabConfig = TabGroupData[index]
    if tabConfig then
        self:ShowTab(tabConfig.CustomTabId)
    end
end
function MultiPlayerPanel:OnCloseClicked()
    self._target:Hide()
    local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
    MultiPlayerMgr:SetWorldSearchStart(0)
end
function MultiPlayerPanel:OnBtnBGClose()
    self:OnCloseClicked()
end
function MultiPlayerPanel:OnSysFuncUnlock(e, r, id)
    TabUtil.UpdateTabGroupVisibilityAll(self.TabGroup)
end

function MultiPlayerPanel:OnSysFuncSync()
    TabUtil.UpdateTabGroupVisibilityAll(self.TabGroup)
end

function MultiPlayerPanel:OnWorldAccessPermissionsStateChanged()
    -- Implementation omitted.
end

function MultiPlayerPanel:OnRetureMyWorld()
    -- Implementation omitted.
end

function MultiPlayerPanel:OnRetureToSettledWorld()
    -- Implementation omitted.
end

function MultiPlayerPanel:OnTagFilterClose()
    self.WorldListTagFilterGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function MultiPlayerPanel:HandleLoadingGroup(bool)
	MyScope:CloseEvent(LOADING_TIMER)
	if bool then
		if self.RefreshHanging == false then
			self.m_LastLoadingStartTime = os.clock()
		end

		self.RefreshHanging = true
		if self.LoadingGroup then
			self.LoadingGroup:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
			self._target:PlayAnimation(self._target["Laoding"], 0, 0, UE4.EUMGSequencePlayMode.Forward, 1, false)
			MyScope:ListenEvent(LOADING_TIMER, Timer:Once(5), function()
				self:HandleLoadingGroup(false)
			end)
		end
	else
		if self.LoadingGroup then
			local contentIndex = self.ContentSwitcher:GetActiveWidgetIndex()
			if contentIndex ~= 1 then
				if self._target then
					self._target:StopAnimation(self._target["Laoding"])
				end
				self.LoadingGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
				self.RefreshHanging = false
			else
				local delay = 0.3 - os.clock() + self.m_LastLoadingStartTime
				if delay > 0 then
					MyScope:ListenEvent(LOADING_TIMER, Timer:Once(delay), function()
						if self._target then
							self._target:StopAnimation(self._target["Laoding"])
						end
						self.LoadingGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
						self.RefreshHanging = false
					end)
				else
					if self._target then
						self._target:StopAnimation(self._target["Laoding"])
					end
					self.LoadingGroup:SetVisibility(UE4.ESlateVisibility.Collapsed)
					self.RefreshHanging = false
				end
			end
		else
			self.RefreshHanging = false
		end
	end
end
return MultiPlayerPanel
