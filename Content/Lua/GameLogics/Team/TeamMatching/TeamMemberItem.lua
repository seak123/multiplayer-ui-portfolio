-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamMemberItem, super = CreateUIBehaviourFromListItem("TeamMemberItem")
local ESlateVisibility = import("ESlateVisibility")
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext)
local TeamModel = ModelManager:GetModel("TeamModel")

local setting = {
    Elements = {
        {Name = "QueueIcon"}, {Name = "Hand"}, {Name = "NameText"},
        {Name = "Lv"}, {Name = "ConfirmSwitcher"}, {Name = "Content"},
        {Name = "BGButton", Handles = {OnClicked = "OnClickBG"}},
        {Name = "KickButton", Handles = {OnClicked = "OnKick"}}
    },
    Events = {
        ["OnPlayerChangeReadyState"] = "OnPlayerChangeReadyState",
        ["OnTeamMemberUpdateConfirmState"] = "OnTeamMemberUpdateConfirmState",
        ["OnPlayerJoinTeam"] = "OnPlayerJoinTeam",
        ["OnTeamMatchingWatchCompleted"] = "OnTeamMatchingWatchCompleted"
    }
}

function TeamMemberItem:_init(go)
    super._init(self, go, setting)
    self:Init()
end

function TeamMemberItem:Init()
    self.roleId = 0
    self.bLeader = false
    self.bAgreed = false
    self.bReady = false
    self.frameState = TeamTypes.TeamStage.None
    self.ConfirmSwitcher:SetActiveWidgetIndex(1)
end

function TeamMemberItem:SetMemberData(data)
    self.roleId = data.ActorRid
    self.NameText:SetText(data.ActorName)
    self.Lv:SetText(data.CurLevel)
    if self.frameState == TeamTypes.TeamStage.TeamState then
        self:SetReady(data.bReady)
    end
    if self.frameState == TeamTypes.TeamStage.TeamState then
        if self.roleId ~= 0 and self.roleId ~= GameUtil.GetMyPlayerRID() and GameUtil.GetMyPlayerRID() == TeamModel.myTeamLeaderRid then
            UIUtil.SetWidgetVisible(self.KickButton, true)
        else
            UIUtil.SetWidgetVisible(self.KickButton, false)
        end
    else
        UIUtil.SetWidgetVisible(self.KickButton, false)
    end
    self:OnTeamMatchingWatchCompleted()
end

function TeamMemberItem:SetContentVisible(bVisible)
    UIUtil.SetWidgetVisible(self.Content, bVisible)
end

function TeamMemberItem:SetFrameState(frameState) self.frameState = frameState end

function TeamMemberItem:SetLeader(IsLeader)
    self.bLeader = IsLeader
    UIUtil.SetWidgetVisible(self.QueueIcon, IsLeader, false, true)
end

function TeamMemberItem:SetReady(bReady)
    self.bReady = bReady;
    self.ConfirmSwitcher:SetActiveWidgetIndex(bReady and 0 or 1)
end

function TeamMemberItem:SetOnline(isOnline)
end

function TeamMemberItem:SetIcon(iconIndex)
    local iconPath = GetHeadIconPath(iconIndex)
    self.Hand:SetHead(iconPath)
end

function TeamMemberItem:OnPlayerChangeReadyState(e, r, actorRid, bReady)
    if self.frameState == TeamTypes.TeamStage.TeamState then
        if actorRid == self.roleId then
            self.ConfirmSwitcher:SetActiveWidgetIndex(bReady and 0 or 1)
            self.bReady = bReady
        end
    end
end

function TeamMemberItem:OnTeamMemberUpdateConfirmState(e, r, actorRid, bAgreed)
    if self.frameState == TeamTypes.TeamStage.Matching then
        if actorRid == self.roleId then
            self.ConfirmSwitcher:SetActiveWidgetIndex(bAgreed and 0 or 1)
            self.bAgreed = bAgreed
            EventSystem.Fire("OnTeamMemberItemChangeState")
        end
    end
end

function TeamMemberItem:OnPlayerJoinTeam(e, r, actorRid, is_matching)
    if self.frameState == TeamTypes.TeamStage.TeamState and is_matching then
        if actorRid == self.roleId then
            self.ConfirmSwitcher:SetActiveWidgetIndex(bReady and 0 or 1)
            self.bReady = bReady
        end
    end
end

function TeamMemberItem:OnTeamMatchingWatchCompleted()
    local attrCache = OtherPlayerModel.GetPlayerAttrInCache(self.roleId)
    if attrCache then
        self:SetOnline(attrCache.IsOnline)
        self:SetIcon(attrCache.IconIdx)
        self.Lv:SetText(attrCache.Level)
    end

end
function TeamMemberItem:IsReady() return self.bReady or self.bLeader end
function TeamMemberItem:IsAgreed() return self.bAgreed end

function TeamMemberItem:OnClickBG()
    if self.frameState == TeamTypes.TeamStage.Matching then
        return
    end
    GameUtil.ClickOtherNameShowTargetPanel(self.roleId,
                                           TargetMenu.PresetMenu.TeamMember,
                                           nil, nil)
end

function TeamMemberItem:OnKick()
    local MessageBoxParam = {
        DescText = FText.FromStringTableShort("确认踢出?"),
        ButtonLayout = "ok_cancel",
        ConfirmBtnText = FText.FromStringTableShort("确认"),
        CancelBtnText = FText.FromStringTableShort("取消"),
        IsBGClickedAutoHide = true,
        ConfirmLambda = function()
            UE4.PzTeamFunctionLibrary.Svr_SendKickOutReq(_G.GlobalContext, self.roleId, TeamModel.myTeamRid)
        end,
        CancelLambda = function() end
    }
    EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
end

return TeamMemberItem;
