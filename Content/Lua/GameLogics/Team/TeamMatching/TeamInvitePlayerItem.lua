-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamInvitePlayerItem, super = CreateUIBehaviourFromListItem(
                                        "TeamInvitePlayerItem")
local ESlateVisibility = import("ESlateVisibility")
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext)
local TeamModel = ModelManager:GetModel("TeamModel")
local FriendModel = ModelManager:GetModel("FriendModel")
local RelationMgr = UE4.PzRelationLibrary.GetRelationManager(_G.GlobalContext)
local Timer = require "GameCore.GameEvent.Timer"

local setting = {
    Elements = {
        {Name = "Hand"}, {Name = "NameText"}, {Name = "Lv"},
        {Name = "OnlineSwitcher"},
        {Name = "InviteBtn", Handles = {OnClicked = "OnInvited"}},
        {Name = "BGButton", Handles = {OnClicked = "OnClickBG"}},
        {Name = "AddFriendBtn", Handles = {OnClicked = "OnAddFriend"}}
    },
    Timers = {
        {
            Name = "RefreshInviteBtnTimer",
            Timer = Timer:Always(1),
            Handler = "OnRefreshInviteBtn"
        }
    },
    Events = {
        ["OnInviteActorSuccess"] = "OnInviteActorSuccess",
        ["OnTeamMatchingWatchCompleted"] = "OnTeamMatchingWatchCompleted",
        ["FriendAddCheckResp"] = "OnFriendAddCheckResp",
    }
}

function TeamInvitePlayerItem:_init(go)
    super._init(self, go, setting)
    self:Init()
end

function TeamInvitePlayerItem:Init()
    self.roleId = 0
    self.inviteInterval = 0
    self.bOnline = false
end

function TeamInvitePlayerItem:OnDataSet(data)
    self.name = data.name
    self.bOnline = data.isOnline
    self.roleId = data.roleId
    self.iconIndex = data.iconIndex
    self.level = data.level
    local attrCache = OtherPlayerModel.GetPlayerAttrInCache(self.roleId)
        if attrCache then
            self.name = attrCache.Name
            self.iconIndex = attrCache.IconIdx
            self.bOnline = attrCache.IsOnline
            self.level = attrCache.Level
        end
    self:UpdateBaseInfo()
    self:UpdateIcon()
    self:UpdateState()
    self.inviteInterval = math.ceil(TeamManager:GetInviteCoolDown(self.roleId))
    self:UpdateInviteBtn()
end

function TeamInvitePlayerItem:OnInvited()
    if self.inviteInterval <= 0 then
        UE4.PzTeamFunctionLibrary.Svr_InviteActorReq(_G.GlobalContext,
                                                     self.roleId,
                                                     TeamModel.myTeamTargetRid);
    end
end

function TeamInvitePlayerItem:OnInviteActorSuccess()
    self.inviteInterval = math.ceil(TeamManager:GetInviteCoolDown(self.roleId))
    self:UpdateInviteBtn()
end

function TeamInvitePlayerItem:UpdateBaseInfo()
    self.NameText:SetText(self.name)
    self.Lv:SetText(self.level)
end

function TeamInvitePlayerItem:UpdateIcon()
    local iconPath = GetHeadIconPath(self.iconIndex)
    self.Hand:SetHead(iconPath)
end

function TeamInvitePlayerItem:UpdateState()
    self.OnlineSwitcher:SetActiveWidgetIndex(self.bOnline and 0 or 2)
    local TeamData = TeamManager:GetTeamData()
    local InTeam = false
    for i = 1, TeamData.Member:Num() do
        if TeamData.Member:Get(i - 1).ActorRid == self.roleId then
            self.OnlineSwitcher:SetActiveWidgetIndex(1)
            InTeam = true
        end
    end
    if self.bOnline and not InTeam then
        UIUtil.SetWidgetVisible(self.InviteBtn, true, true)
    else
        UIUtil.SetWidgetVisible(self.InviteBtn, false)
    end
    local isFriend = FriendModel:IsMyFriend(self.roleId)
    UIUtil.SetWidgetVisible(self.AddFriendBtn, not isFriend)
end

function TeamInvitePlayerItem:UpdateInviteBtn()
    if self.inviteInterval > 0 then
        self.InviteBtn:SetText(tostring(self.inviteInterval) .. "s")
        self.InviteBtn:SetIsEnabled(false)
    else
        self.InviteBtn:SetIsEnabled(true)
        self.InviteBtn:SetText("邀请")
    end
end

function TeamInvitePlayerItem:OnRefreshInviteBtn()
    self.inviteInterval = self.inviteInterval - 1
    self:UpdateState()
    self:UpdateInviteBtn()
end

function TeamInvitePlayerItem:OnTeamMatchingWatchCompleted()
    local attrCache = OtherPlayerModel.GetPlayerAttrInCache(self.roleId)

    if attrCache then
        self.name = attrCache.Name
        self.level = attrCache.Level
        self.iconIndex = attrCache.IconIdx
        self.bOnline = attrCache.IsOnline
        self:UpdateBaseInfo()
        self:UpdateIcon()
        self:UpdateState()
    end
end

function TeamInvitePlayerItem:OnClickBG()
    GameUtil.ClickOtherNameShowTargetPanel(self.roleId,
                                           TargetMenu.PresetMenu.Default, nil,
                                           nil)
end

function TeamInvitePlayerItem:OnAddFriend()
    RelationMgr:AddFriendReq(self.roleId)
end

function TeamInvitePlayerItem:OnFriendAddCheckResp(e,r, otherPlayerRid, retCode, bAccept)
    if retCode == 0 then
		if otherPlayerRid == self.roleId and bAccept then
            UIUtil.SetWidgetVisible(self.AddFriendBtn, false)
        end
    end
end

return TeamInvitePlayerItem;
