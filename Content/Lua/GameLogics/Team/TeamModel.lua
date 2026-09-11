-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamModel, super = ModelManager:CreateModel("TeamModel")
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext)
local ResRdungeonmainConfig = ConfigManager.GetTable("ResRdungeonmainConfig")
local GameLuaLibrary = UE4.PzGameLuaLibrary

local setting = {
    Events = {
        ["OnTeamFullDataSync"] = "OnTeamFullDataSync",
        ["OnKickoutFromTeam"] = "OnKickoutFromTeam",
        ["OnMatchedTeamFullDataSync"] = "OnMatchedTeamFullDataSync",
        ["RefreshTracePlayer"] = "OnRefreshTracePlayer",
        ["OnCreateTeamSuccess"] = "OnCreateTeamSuccess",
        ["OnMainPlayerJoinTeam"] = "OnMainPlayerJoinTeam",
        ["OnLeaveTeamSuccess"] = "OnLeaveTeamSuccess",
        ["OnTeamBCDismiss"] = "OnTeamBCDismiss",
        ["OnNotifyEnterMatchingConfirmStage"] = "OnNotifyEnterMatchingConfirmStage",
        ["OnTeamRelationListSync"] = "OnTeamRelationListSync",
        ["OnTeamBCChangeTeamMatch"] = "OnTeamMatchingStateChanged",
        ["PZ_EVENT_PVP_MATCH_TIMEOUT"] = "UpdateTeamFrameViewState",
        ["PZ_EVENT_ON_WORLDINFO_UPDATE"] = "OnChangeMap",
        ["OnInviteActorRejected"] = "OnInviteActorRejected",
        ["OnPlayerChangeReadyState"] = "UpdateTeamFrameViewState",
		
		["OnTeamMatchingWatchCompleted"] = "OnTeamMemberInfoUpdate",
		["OnTeamBCLeave"] = "OnTeamBCLeave",
        ["OnChangeTeamTargetNotify"] = "OnChangeTeamTargetNotify",
        ["PZ_EVENT_LOADING_END"] = "UpdateTeamFrameViewState",
    }
}

local TeamMatchingFrame_Path =
    "WidgetBlueprint'/Game/UI/Panel/Ranks/WBP_Rank_Invite_Frame.WBP_Rank_Invite_Frame_C'"
local TeamMatchingConfirmFrame_Path =
    "WidgetBlueprint'/Game/UI/Panel/Ranks/WBP_Rank_MatchingSuccessful.WBP_Rank_MatchingSuccessful_C'"
local TeamMatchingNoticeFrame_Path =
    "WidgetBlueprint'/Game/UI/Panel/Ranks/WBP_Rank_HUD_Matching.WBP_Rank_HUD_Matching_C'"

function TeamModel:_init()
    super._init(self, setting)
    self.matchingFrameID = nil
    self.prepareFrameID = nil
    self.noticeFrameID = nil
    self.myTeamRid = 0
    self.myMatchedTeamRid = 0
    self.myTeamLeaderRid = 0
    self.myMatchedTeamLeaderRid = 0
    self.myTeamTargetRid = 0
    self.recentTeammates = {};
    self.teamStage = TeamTypes.TeamStage.None
    self.showingTeamFrame = false

    self.gm_team_must_four = true
end
function TeamModel:CanTracePlayer(TargetId)
    -- Implementation omitted.
end
function TeamModel:CanCancelTrace(TargetId)
    -- Implementation omitted.
end
function TeamModel:TracePlayer(TargetId)
    -- Implementation omitted.
end
function TeamModel:UnTracePlayer(TargetId)
    -- Implementation omitted.
end
function TeamModel:OnRefreshTracePlayer() end
function TeamModel:SetTeamRid(teamRid)
	local oldTeamRid = self.myTeamRid
    self.myTeamRid = teamRid
    if self.teamStage == TeamTypes.TeamStage.None and teamRid > 0 then
        self:SetTeamStage(TeamTypes.TeamStage.TeamState)
    end

	if oldTeamRid ~= teamRid and teamRid ~= 0 and teamRid ~= 1 then
		self:CreateChatTeamSession(teamRid)
	end
end
function TeamModel:SetMatchedTeamRid(teamRid)
    self.myMatchedTeamRid = teamRid
	
end
function TeamModel:SetTeamStage(teamStage)
    self.teamStage = teamStage
    self:UpdateTeamFrameViewState()
    EventSystem.Fire("OnTeamStageChanged")
end
function TeamModel:GetTeamRid()
    if self.myMatchedTeamRid ~= 0 then
        return self.myMatchedTeamRid
    else
        return self.myTeamRid
    end
end
function TeamModel:GetLeaderRid()
    if self.myMatchedTeamLeaderRid ~= 0 then
        return self.myMatchedTeamLeaderRid
    else
        return self.myTeamLeaderRid
    end
end
function TeamModel:OpenTeamMatchingFrame(inviteTabs)
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.matchingFrameID)
    self.showingTeamFrame = true
    if not frameBehaviour then
        UIUtil.AddUniqueFrameAsync(TeamMatchingFrame_Path, function(frame)
            self.matchingFrameID = frame:GetUniqueID()
            local behaviour = __BehaviourManager:GetBehaviour(
                                  self.matchingFrameID)
            behaviour:InitFrameContent(inviteTabs)
            self:UpdateTeamFrameViewState()
        end)
    else
        frameBehaviour:InitFrameContent(inviteTabs)
    end
end

function TeamModel:RemoveTeamMatchingFrame()
    self.showingTeamFrame = false
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.matchingFrameID)
    if frameBehaviour ~= nil then 
        frameBehaviour:Hide() 
        self.matchingFrameID = 0
    end
end

function TeamModel:HideTeamMatchingFrame()
    self:RemoveTeamMatchingFrame()
    self:UpdateTeamFrameViewState()
end

function TeamModel:OnTeamMatchingFrameHide()
    self.showingTeamFrame = false
    self.matchingFrameID = 0
end
function TeamModel:UpdateTeamFrameViewState()
    if self:IsMatching() then
        self.HUDState = TeamTypes.HUDState.Matching
    else
        if TeamManager:IsInTeam() then
            if self:IsLeader() then
                if TeamManager:IsAllMemberReady() and TeamManager:GetTeamMemberNum() > 1 then
                    self.HUDState = TeamTypes.HUDState.AllReady
                else
                    self.HUDState = TeamTypes.HUDState.Ready
                end
            else
                if TeamManager:IsSelfReady() then
                    self.HUDState = TeamTypes.HUDState.Ready
                else
                    self.HUDState = TeamTypes.HUDState.UnReady
                end
            end
        else
            self.HUDState = TeamTypes.HUDState.Ready
        end
    end
    local bVisible = GameLuaLibrary.IsCurrentMapShowTeamState(
                         _G.GlobalContext)
    if bVisible then
        local bSingleMatching = UE4.PzPVPLibrary.IsSingleMatching(_G.GlobalContext)
        if self:GetTeamRid() ~= 0 or bSingleMatching then
            local frameBehaviour = __BehaviourManager:GetBehaviour(
                                       self.matchingFrameID)
            local noticeBehaviour = __BehaviourManager:GetBehaviour(
                                        self.noticeFrameID)
            local bAutoShowNotice = not frameBehaviour or self:IsMatching()
            if bAutoShowNotice and not noticeBehaviour then
                self:OpenTeamMatchingNoticeFrame()
            end
            if frameBehaviour and not self:IsMatching() and noticeBehaviour then
                self:RemoveTeamMatchingNoticeFrame()
            elseif self.teamStage == TeamTypes.TeamStage.None and noticeBehaviour then
                self:RemoveTeamMatchingNoticeFrame()
            end
        else
            self:RemoveTeamMatchingFrame()
            self:RemoveTeamMatchingNoticeFrame()
        end
    else
        self:RemoveTeamMatchingFrame()
        self:RemoveTeamMatchingNoticeFrame()
    end
    
    EventSystem.Fire("OnUpdateTeamFrameViewState")
    EventSystem.Fire("OnTeamHUDStageChanged")
end
function TeamModel:OpenTeamMatchingPrepareFrame()
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.prepareFrameID)
    if not frameBehaviour then
        UIUtil.AddUniqueFrameAsync(TeamMatchingConfirmFrame_Path,
                                   function(frame)
            self.prepareFrameID = frame:GetUniqueID()
            EventSystem.Fire("UIEvent_MessageBox_CleanUp")
            self:UpdateTeamFrameViewState()
        end)
    else
        frameBehaviour:Init()
        EventSystem.Fire("UIEvent_MessageBox_CleanUp")
    end
end

function TeamModel:RemoveTeamMatchingPrepareFrame()
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.prepareFrameID)
    if frameBehaviour ~= nil then 
        frameBehaviour:Hide() 
        self.prepareFrameID = 0
    end
end

function TeamModel:OnTeamMatchingPrepareFrameHide()
    self.prepareFrameID = 0
end
function TeamModel:OpenTeamMatchingNoticeFrame()
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.noticeFrameID)
    if not frameBehaviour then
        UIUtil.AddUniqueFrameAsync(TeamMatchingNoticeFrame_Path, function(frame)
            self.noticeFrameID = frame:GetUniqueID()
            self:UpdateTeamFrameViewState()
        end)
    else
        frameBehaviour:Init()
    end
end

function TeamModel:RemoveTeamMatchingNoticeFrame()
    local frameBehaviour = __BehaviourManager:GetBehaviour(self.noticeFrameID)
    if frameBehaviour ~= nil then 
        frameBehaviour:Hide() 
        self.noticeFrameID = 0
    end
end

function TeamModel:OnTeamMatchingNoticeFrameHide()
    self.noticeFrameID = 0
end
function TeamModel:RecoverTeamPanel()
    self:OpenTeamMatchingFrame(TeamTypes.TabType.Instance)
end
function TeamModel:OnTeamFullDataSync(e, r)
    local TeamData = TeamManager:GetTeamData()
    if TeamData.TeamRid ~= 0 then
        self:SetTeamRid(TeamData.TeamRid)
        self.myTeamLeaderRid = TeamData.LeaderRid
        self.myTeamTargetRid = TeamData.TeamTarget
    else
        self:SetTeamRid(0) 
        self.myTeamLeaderRid = 0
        self.myTeamTargetRid = 0
    end
    self:UpdateTeamFrameViewState()
    self:ReqPlayersDetails()
end

function TeamModel:OnChangeMap(e,r,mapId)
    local DungeonModel = ModelManager:GetModel("DungeonModel")
    self:UpdateTeamFrameViewState()
end
   
function TeamModel:OnMatchedTeamFullDataSync(e, r)
    local MatchedTeamData = TeamManager:GetMatchedData()
    if MatchedTeamData.TeamRid ~= 0 then
        self:SetMatchedTeamRid(MatchedTeamData.TeamRid)
        self.myMatchedTeamLeaderRid = MatchedTeamData.LeaderRid
    else
        self:SetMatchedTeamRid(0)
        self.myMatchedTeamLeaderRid = 0
    end
    self:ReqPlayersDetails()
end

function TeamModel:OnKickoutFromTeam()
    self:SetTeamRid(0)
    self.myTeamLeaderRid = 0
    self:UpdateTeamFrameViewState()
	
	self:DeleteChatTeamSession()
end
function TeamModel:OnNotifyInvitedJoinTeam(e, r, name, targetId, inviterRid,
                                           teamRid)
    local MessageBoxParam = {
        DescText = name .. FText.FromStringTableShort(" 邀请你进入队伍"),
        ButtonLayout = "ok_cancel",
        ConfirmBtnText = FText.FromStringTableShort("同意"),
        CancelBtnText = FText.FromStringTableShort("拒绝"),
        IsBGClickedAutoHide = true,
        ConfirmLambda = function()
            UE4.PzTeamFunctionLibrary.Svr_ActorReplyInviteReq(_G.GlobalContext,
                                                              true, targetId,
                                                              inviterRid,
                                                              teamRid)
        end,
        CancelLambda = function()
            UE4.PzTeamFunctionLibrary.Svr_ActorReplyInviteReq(_G.GlobalContext,
                                                              false, targetId,
                                                              inviterRid,
                                                              teamRid)
        end
    }
    EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
end
function TeamModel:OnCreateTeamSuccess(e, r, cb_data, actorRid)
    self:OpenTeamMatchingFrame(TeamTypes.TabType.Instance)
end
function TeamModel:OnMainPlayerJoinTeam(e, r)
    self:OpenTeamMatchingFrame(TeamTypes.TabType.Instance)
end
function TeamModel:OnLeaveTeamSuccess(e, r, actorRid, teamRid)
    self:RemoveTeamMatchingFrame()
    self:RemoveTeamMatchingNoticeFrame()
	
	self:DeleteChatTeamSession()
end
function TeamModel:OnTeamBCDismiss(e, r)
    self:RemoveTeamMatchingFrame()
    self:RemoveTeamMatchingNoticeFrame()

	self:DeleteChatTeamSession()
end
function TeamModel:OnNotifyEnterMatchingConfirmStage(e, r)
    self.MatchingConfirmTimeStamp = GameLuaLibrary.GetTimeStampNow()
    self:OpenTeamMatchingPrepareFrame()
end
function TeamModel:OnTeamRelationListSync(e, r, RelationList)
    self.recentTeammates = {};
    if RelationList:Num() > 0 then
        for i = 0, RelationList:Num() - 1 do
            table.insert(self.recentTeammates, RelationList:Get(i))
        end
        OtherPlayerModel.OnPlayerAttrReq(self.recentTeammates, function()
            EventSystem.Fire("OnTeamMatchingWatchCompleted")
        end)
    end
end
function TeamModel:OnTeamMatchingStateChanged(e, r, bMatch)
    if bMatch then
        self:SetTeamStage(TeamTypes.TeamStage.Matching)
    else
        if self.myTeamRid > 0 then
            self:SetTeamStage(TeamTypes.TeamStage.TeamState)
        else
            self:SetTeamStage(TeamTypes.TeamStage.None)
        end
    end
end
function TeamModel:OnInviteActorSuccess(e, r, actorRid)
    if actorRid == GameUtil.GetMyPlayerRID() then
        self:OpenTeamMatchingFrame(TeamTypes.TabType.Instance)
    end
end

function TeamModel:OnInviteActorRejected(e,r,actorRid)
    OtherPlayerModel.OnPlayerAttrReq({actorRid}, function()
        local cacheInfo = OtherPlayerModel.GetPlayerAttrInCache(actorRid)
        if cacheInfo ~= nil then
            EventSystem.Fire("AppendNotice", EKGNoticeType.Normal,
            cacheInfo.Name..FText.FromStringTableShort("拒绝了你的组队邀请"));
        end
    end)
end

function TeamModel:OnChangeTeamTargetNotify(e, r, NewTargetId)
    self.myTeamTargetRid = NewTargetId
end
function TeamModel:ReqPlayersDetails()
    local watchPlayers = {};
    table.insert(watchPlayers, GameUtil.GetMyPlayerRID())
    local TeamData = TeamManager:GetTeamData()
    for i = 1, TeamData.Member:Num() do
        local memberRid = TeamData.Member:Get(i - 1).ActorRid
        if memberRid ~= GameUtil.GetMyPlayerRID() then
            table.insert(watchPlayers, memberRid)
        end
    end
    local MatchedData = TeamManager:GetMatchedData()
    for i = 1, MatchedData.Member:Num() do
        local memberRid = MatchedData.Member:Get(i - 1).ActorRid
        if memberRid ~= GameUtil.GetMyPlayerRID() then
            table.insert(watchPlayers, memberRid)
        end
    end
    OtherPlayerModel.OnPlayerAttrReq(watchPlayers, function()
        EventSystem.Fire("OnTeamMatchingWatchCompleted")
    end)
end
function TeamModel:IsMatching()
    local MatchMgr = UE4.PzPVPLibrary.GetClientMatchManager(_G.GlobalContext)
    return self.teamStage == TeamTypes.TeamStage.Matching or
               MatchMgr:GetCurrentCSQTid() > 0
end
function TeamModel:IsLeader()
    return GameUtil.GetMyPlayerRID() == self.myTeamLeaderRid
end
function TeamModel:IsInstanceTeam()
    return TeamTypes.GetTeamTargetType(self.myTeamTargetRid) == ResMacros.E_RES_TEAM_TARGET_CATE_INST
end
function TeamModel:IsPVPTeam()
    return TeamTypes.GetTeamTargetType(self.myTeamTargetRid) == ResMacros.E_RES_TEAM_TARGET_CATE_PVP
end
function TeamModel:IsMultiArena()
    return TeamTypes.GetTeamTargetType(self.myTeamTargetRid) == ResMacros.E_RES_TEAM_TARGET_CATE_TTT
end
function TeamModel:IsNightmare()
    return TeamTypes.GetTeamTargetType(self.myTeamTargetRid) == ResMacros.E_RES_TEAM_TARGET_CATE_NIGHTMARE
end
function TeamModel:TeamMatchingForInstance(targetId)
    local bSingePVP = UE4.PzPVPLibrary.IsSingleMatching(_G.GlobalContext)
    if bSingePVP then
        GameUtil.Notice(LocalizationFText.FromStr("已经在其他副本队伍中"))
        return
    end
    if self:GetTeamRid() ~= 0 then
        if targetId ~= self.myTeamTargetRid then
            if TeamManager:IsInTeam() then
                UE4.PzTeamFunctionLibrary.Svr_ChangeTeamTargetReq(_G.GlobalContext, targetId, 0)
            else
                self.myTeamTargetRid = targetId
            end
        end

        self:RecoverTeamPanel()
        return
    end
    
    UE4.PzTeamFunctionLibrary.Svr_CreateTeamReq(_G.GlobalContext, targetId, 0, false)
    self.myTeamTargetRid = targetId
end

function TeamModel:TeamMatchingForPVP(targetId)
    if self:GetTeamRid() ~= 0 then
        self:RecoverTeamPanel()
        return
    end
    UE4.PzTeamFunctionLibrary.Svr_CreateTeamReq(_G.GlobalContext, targetId, 0, false)
    local MatchMgr = UE4.PzPVPLibrary.GetClientMatchManager(_G.GlobalContext)
    if MatchMgr:GetCurrentCSQTid() > 0 then
        self:SetTeamStage(TeamTypes.TeamStage.Matching)
    else
        self:SetTeamStage(TeamTypes.TeamStage.TeamState)
    end
    self.myTeamTargetRid = targetId
    self:OpenTeamMatchingFrame(TeamTypes.TabType.Instance)
end

function TeamModel:TeamMatchReq(playerCount)
    if self:IsPVPTeam() then
        local PvpCsqId = FKBinPVPTable.GetCSQIdByTeamTargetId(_G.GlobalContext, self.myTeamTargetRid)
        if playerCount == 1 then
            UE4.PzPVPLibrary.ClientSoloMatchReq(_G.GlobalContext,PvpCsqId)
        else
            UE4.PzPVPLibrary.ClientTeamMatchReq(_G.GlobalContext,PvpCsqId)
        end
    else
        UE4.PzTeamFunctionLibrary.Svr_TeamMatchReq(_G.GlobalContext, true,
                                                   self.myTeamTargetRid, false)
    end
end
function TeamModel:CancelMatchReq()
    if self:IsPVPTeam() then
        if TeamManager:IsInTeam() == false then
            self:RemoveTeamMatchingNoticeFrame()
        end
        UE4.PzPVPLibrary.ClientCancelMatchReq(_G.GlobalContext)
    else
        UE4.PzTeamFunctionLibrary.Svr_TeamMatchReq(_G.GlobalContext, false,
                                                   self.myTeamTargetRid, false)
    end
end
function TeamModel:GetMembersInfo()
	local datas = {}
	local watchers = {}
	local TeamData = TeamManager:GetTeamData()
	for i = 1, TeamData.Member:Num() do
		local memberInfo = TeamData.Member:Get(i - 1)
		local actorId = memberInfo.ActorRid
		local data =
		{
			Id = actorId,
			Name = memberInfo.ActorName,
			Icon = 0,
		}
		local record = OtherPlayerModel.GetPlayerAttrInCache(actorId)
		if not record then
			table.insert(watchers, actorId)
		else
			data.Icon = record.IconIdx
		end
		table.insert(datas, data)
	end
	if #watchers > 0 then
		OtherPlayerModel.OnPlayerAttrReq(watchers)
	end
	return datas
end
function TeamModel:GetMemberDataById(roleId)
	local data = TeamManager:GetMemberDataByRid(roleId)
	if data.ActorRid == 0 then
		return nil
	end
	return data
end
function TeamModel:OnTeamMemberInfoUpdate()
	self.memberInfo = {}
	
	local TeamData = TeamManager:GetTeamData()
	for i = 1, TeamData.Member:Num() do
		local memberRid = TeamData.Member:Get(i - 1).ActorRid
		local record = OtherPlayerModel.GetPlayerAttrInCache(memberRid)
		if record then
			
			local data =
			{
				Id = memberRid,
				Name = record.Name,
				Icon = record.IconIdx,
			}
			table.insert(self.memberInfo, data)
		else
		end
	end
end
function TeamModel:DeleteChatTeamSession()
    -- Implementation omitted.
end

function TeamModel:CreateChatTeamSession(teamId)
    -- Implementation omitted.
end

return TeamModel
