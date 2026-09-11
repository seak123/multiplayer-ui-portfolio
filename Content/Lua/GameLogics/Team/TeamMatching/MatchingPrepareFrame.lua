-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MatchingPrepareFrame, super = CreateUIBehaviour("MatchingPrepareFrame")
local ESlateVisibility = import("ESlateVisibility")
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext)
local TeamModel = ModelManager:GetModel("TeamModel")
local Timer = require "GameCore.GameEvent.Timer"
local GameLuaLibrary = UE.UGameLuaLibrary

local setting = {
    Elements = {
        {Name = "Time"}, {Name = "ConfirmInfo"},
        {Name = "ConfirmBtn", Handles = {OnClicked = "OnClickConfirmBtn"}}
    },
    Timers = {
        {
            Name = "RefreshLastTimer",
            Timer = Timer:Always(0.2),
            Handler = "OnRefreshLastTimer"
        }
    },
    Behaviours = {
        {Name = "TeamMemberItem_1", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_2", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_3", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_4", Type = "TeamMemberItem"}
    },
    Events = {
        ["OnTeamMemberItemChangeState"] = "UpdateConfirmContent",
        ["OnMatchedTeamFullDataSync"] = "OnMatchedTeamFullDataSync",
        ["OnTeamBCDismiss"] = "OnTeamBCDismiss",
        ["OnTeamBCLeave"] = "OnTeamBCLeave"
    }
}

function MatchingPrepareFrame:_init(go)
    super._init(self, go, setting)
    self:Init()
end

function MatchingPrepareFrame:Init()
    self.memberItems = {
        self.TeamMemberItem_1, self.TeamMemberItem_2, self.TeamMemberItem_3,
        self.TeamMemberItem_4
    };
    for i = 1, #self.memberItems do
        self.memberItems[i]:SetFrameState(TeamTypes.TeamStage.Matching)
    end
    self.TeamPlayerCount = 0
    self.bIAlreadyConfirm = false
    self.EndTimeStamp = 10 + TeamModel.MatchingConfirmTimeStamp
    self:UpdateFrameContent()
end

function MatchingPrepareFrame:Hide() self._target:Hide() end

function MatchingPrepareFrame:OnDestroy()
    TeamModel:OnTeamMatchingPrepareFrameHide()
end
function MatchingPrepareFrame:UpdateFrameContent()
    for i = 1, #self.memberItems do
        self.memberItems[i]:SetContentVisible(false)
        self.memberItems[i]:SetLeader(false)
    end
    local MatchedTeamData = TeamManager:GetMatchedData()
    if MatchedTeamData.Member:Num() > 0 then
        self.TeamPlayerCount = MatchedTeamData.Member:Num()
        for i = 1, MatchedTeamData.Member:Num() do
            self.memberItems[i]:SetMemberData(MatchedTeamData.Member:Get(i - 1))
            self.memberItems[i]:SetContentVisible(true)
            self.memberItems[i]:SetLeader(
                MatchedTeamData.Member:Get(i - 1).ActorRid ==
                    MatchedTeamData.LeaderRid)
        end
    else
        local TeamData = TeamManager:GetTeamData()
        self.TeamPlayerCount = TeamData.Member:Num()
        for i = 1, TeamData.Member:Num() do
            self.memberItems[i]:SetMemberData(TeamData.Member:Get(i - 1))
            self.memberItems[i]:SetContentVisible(true)
            self.memberItems[i]:SetLeader(
                TeamData.Member:Get(i - 1).ActorRid == TeamData.LeaderRid)
        end
    end
    local last_time = math.floor(self.EndTimeStamp - GameLuaLibrary.GetTimeStampNow())
    self.Time:SetText(tostring(last_time))
    self:UpdateConfirmContent()
end
function MatchingPrepareFrame:UpdateConfirmContent()
    local agreedNum = 0
    for i = 1, self.TeamPlayerCount do
        if self.memberItems[i]:IsAgreed() then agreedNum = agreedNum + 1 end
        if self.memberItems[i].roleId == GameUtil.GetMyPlayerRID() then
            self.bIAlreadyConfirm = self.memberItems[i]:IsAgreed()
        end
    end
    self.ConfirmInfo:SetText(tostring(agreedNum) .. "/" ..
                                 tostring(self.TeamPlayerCount))
    self.ConfirmBtn:SetText("确认")
    if self.bIAlreadyConfirm then
        self.ConfirmBtn:SetVisibility(ESlateVisibility.Hidden)
    else
        self.ConfirmBtn:SetIsEnabled(true)
    end
end
function MatchingPrepareFrame:OnClickConfirmBtn()
    if self.bIAlreadyConfirm then
        UE4.PzTeamFunctionLibrary.Svr_TeamMemberConfirmReq(_G.GlobalContext,
                                                           TeamModel:GetLeaderRid(),
                                                           TeamModel:GetTeamRid(),
                                                           false, false)
    else
        UE4.PzTeamFunctionLibrary.Svr_TeamMemberConfirmReq(_G.GlobalContext,
                                                           TeamModel:GetLeaderRid(),
                                                           TeamModel:GetTeamRid(),
                                                           true, false)
    end
end
function MatchingPrepareFrame:OnRefreshLastTimer()
    local last_time = math.floor(self.EndTimeStamp - GameLuaLibrary.GetTimeStampNow())
    self.Time:SetText(tostring(last_time))
   
    if last_time < 0 then
        self.Time:SetText("0")
        TeamModel:RemoveTeamMatchingPrepareFrame() 
    end
end
function MatchingPrepareFrame:OnMatchedTeamFullDataSync()
    local last_time = math.floor(self.EndTimeStamp - GameLuaLibrary.GetTimeStampNow())
    if last_time > 0 then self:UpdateFrameContent() end
end
function MatchingPrepareFrame:OnTeamBCDismiss()
    TeamModel:RemoveTeamMatchingPrepareFrame()
end
function MatchingPrepareFrame:OnTeamBCLeave()
    TeamModel:RemoveTeamMatchingPrepareFrame()
end
return MatchingPrepareFrame;
