-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamMatchingMainFrame, super = CreateUIBehaviour("TeamMatchingMainFrame");
local ESlateVisibility = import("ESlateVisibility");
local TeamModel = ModelManager:GetModel("TeamModel");
local PlayWorldData = ModelManager:GetModel("PlayWorldData")
local EPzChatChannelType = UE4.EPzChatChannelType
local ArenaModel = ModelManager:GetModel("ArenaModel");
local ArenaLibrary = UE4.PzArenaLibrary
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext);
local Timer = require "GameCore.GameEvent.Timer";

local setting = {
    Elements = {
        {Name = "TitlePart"},
        {Name = "UITabItem_1", Handles = {OnClicked = "OnClickTab_1"}},
        {Name = "UITabItem_2", Handles = {OnClicked = "OnClickTab_2"}},
        {Name = "UITabItem_3", Handles = {OnClicked = "OnClickTab_3"}},
        {Name = "UITabItem_4", Handles = {OnClicked = "OnClickTab_4"}},
        {Name = "CloseBtn", Handles = {OnClicked = "OnCloseFrame"}},
        {Name = "InviteList", Type = UE4.ListView},
        {Name = "MatchingPlayerBtn", Handles = {OnClicked = "OnMatchingPlayer"}},
        {Name = "StartTargetBtn", Handles = {OnClicked = "OnStartTarget"}},
        {Name = "LeaveTeamBtn", Handles = {OnClicked = "OnLeavingTeam"}},
        {Name = "RewardContent"},
        {Name = "RewardNumText"},
        {Name = "StateSwitcher"}, {Name = "RewardNumGroup"},
        {Name = "DegreeSelectBtn", Handles = {OnClicked = "OnDegreeSelect"}},
        {Name = "DegreeSelectContent"},
        {Name = "SelectBGButton", Handles = {OnClicked = "OnSelectBGButton"}},
        {Name = "ShareButton", Handles = {OnClicked = "OnShare"}},
        {Name = "DegreeList", Type = UE4.ListView},
        {Name = "RewardNumGroup"},
    },
    Behaviours = {
        {Name = "UITabItem_1", Type = "BuildCategoryItem"},
        {Name = "UITabItem_2", Type = "BuildCategoryItem"},
        {Name = "UITabItem_3", Type = "BuildCategoryItem"},
        {Name = "UITabItem_4", Type = "BuildCategoryItem"},
        {Name = "TeamMemberItem_1", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_2", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_3", Type = "TeamMemberItem"},
        {Name = "TeamMemberItem_4", Type = "TeamMemberItem"}
    },
    Events = {
        ["OnTeamFullDataSync"] = "UpdateFrameContent",
        ["OnTeamMatchingWatchCompleted"] = "OnTeamMatchingWatchCompleted",
        ["OnTeamStageChanged"] = "OnTeamStageChanged",
        ["OnTeamHUDStageChanged"] = "OnTeamHUDStageChanged",
        ["NetEvent_PlayWorld_WorldBriefDataListReceived"] = "OnRecommendListRecieved",
        ["OnChangeInstanceDifficultLevel"] = "OnChangeInstanceDifficultLevel",
        ["OnChangeTeamTargetNotify"] = "OnChangeTeamTargetNotify"
    },
    Timers = {
        {
            Name = "ReqPlayersDetails",
            Timer = Timer:Always(5),
            Handler = "ReqPlayersDetails"
        },
        {
            Name = "RefreshUrgeBtnTimer",
            Timer = Timer:Always(0.5),
            Handler = "OnRefreshUrgeBtnTimer"
        }
    }
};
function TeamMatchingMainFrame:_init(go)
    super._init(self, go, setting);
    self:Init();
end
function TeamMatchingMainFrame:Init()
    self.targetId = 0;
    self.isLeader = false;
    self.doMatch = false;
    self.isReady = false;
    self.inviteTabs = {
        self.UITabItem_1, self.UITabItem_2, self.UITabItem_3, self.UITabItem_4
    };
    self.memberItems = {
        self.TeamMemberItem_1, self.TeamMemberItem_2, self.TeamMemberItem_3,
        self.TeamMemberItem_4
    };
    self.inviteTabDataFuncTable = {};
    self.showListIndex = 0;
    self.TeamPlayerCount = 0;
    for i = 1, #self.memberItems do
        self.memberItems[i]:SetFrameState(TeamTypes.TeamStage.TeamState)
    end
end
function TeamMatchingMainFrame:Hide() self._target:Hide() end

function TeamMatchingMainFrame:OnDestroy()
    TeamModel:HideTeamMatchingFrame()
end
function TeamMatchingMainFrame:InitFrameContent(inviteTabs)
    for i = 1, 4 do
        if inviteTabs[i] then
            UIUtil.SetWidgetVisible(self.inviteTabs[i]._target, true, true);
            self.inviteTabs[i]:SetText(LocalizationFText.FromStr(inviteTabs[i].Title).str);
            table.insert(self.inviteTabDataFuncTable,
                         inviteTabs[i].GetMembersFunc);
        else
            UIUtil.SetWidgetVisible(self.inviteTabs[i]._target, false);
        end
    end
    UIUtil.SetWidgetVisible(self.DegreeSelectContent, false)
    UIUtil.SetWidgetVisible(self.DegreeList, false)
    self:OnClickTab_1();
    self:UpdateFrameContent()
    UE4.PzTeamFunctionLibrary.Svr_TeamMatchRelationTopNReq(_G.GlobalContext, 10)
    local manager = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
    UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):PullInstanceRecommendData(TeamModel.myTeamTargetRid)
end
function TeamMatchingMainFrame:UpdateInviteList()
    for i = 1, 4 do self.inviteTabs[i]:OnSelected(false); end
    self.inviteTabs[self.showListIndex]:OnSelected(true);
    self.InviteList:ClearListItems();
    local memberDatas = self.inviteTabDataFuncTable[self.showListIndex]();
    if #memberDatas > 0 then
        for i = 1, #memberDatas do
            local uobject = DataObjectPool:Get(memberDatas[i]);
            self.InviteList:AddItem(uobject);
        end
        self:ReqPlayersDetails()
        self.StateSwitcher:SetActiveWidgetIndex(0)
    else
        self.StateSwitcher:SetActiveWidgetIndex(1)
    end
end

function TeamMatchingMainFrame:UpdateFrameContent()
    local memberNum = 1
    if TeamManager:IsInTeam() then
        memberNum = #self.memberItems
        for i = 1, #self.memberItems do
            self.memberItems[i]:SetContentVisible(false)
            self.memberItems[i]:SetLeader(false)
        end
        local TeamData = TeamManager:GetTeamData()
        for i = 1, TeamData.Member:Num() do
            local bLeader = TeamData.Member:Get(i - 1).ActorRid ==
                                TeamData.LeaderRid
            self.memberItems[i]:SetMemberData(TeamData.Member:Get(i - 1))
            self.memberItems[i]:SetContentVisible(true)
            self.memberItems[i]:SetLeader(bLeader)
            if bLeader then self.memberItems[i]:SetReady(true) end
            if TeamData.Member:Get(i - 1).ActorRid == GameUtil.GetMyPlayerRID() then
                self.isReady = TeamData.Member:Get(i - 1).bReady
            end
        end
        self.TeamPlayerCount = TeamData.Member:Num()
        self.targetId = TeamData.TeamTarget;
        self.isLeader = TeamData.LeaderRid == GameUtil.GetMyPlayerRID()
        self.doMatch = TeamData.DoMatch

    else
        for i = 1, #self.memberItems do
            self.memberItems[i]:SetContentVisible(false)
            self.memberItems[i]:SetLeader(false)
        end
        local fakeData = {}
        fakeData.ActorRid = GameUtil.GetMyPlayerRID()
        fakeData.ActorName = GameUtil.GetPlayerName()
        fakeData.OnlineState = 1
        fakeData.CurLevel = GameUtil.GetMyPlayerLevel()
        self.memberItems[1]:SetMemberData(fakeData)
        self.memberItems[1]:SetContentVisible(true)
        self.memberItems[1]:SetLeader(true)
        self.memberItems[1]:SetReady(true)
        self.TeamPlayerCount = 1
        self.targetId = TeamModel.myTeamTargetRid
        self.isLeader = true
        self.doMatch = false
    end
    self:ReqPlayersDetails()
    self:UpdateFrameBtns()
    self:UpdateFrameTitle()
    self:UpdateRewardTimeText()

    UIUtil.SetWidgetVisible(self.ShareButton, memberNum <= 4 and true or false)
end
function TeamMatchingMainFrame:UpdateFrameBtns()
    if self.isLeader then
        UIUtil.SetWidgetVisible(self.MatchingPlayerBtn, true, true)
        if TeamManager:IsInTeam() and not TeamManager:IsAllMemberReady() then
            self.StartTargetBtn:SetText(FText.FromStringTableShort("催促准备"))
        else
            self.StartTargetBtn:SetText(FText.FromStringTableShort("开始挑战"))
            self.StartTargetBtn:SetIsEnabled(true)
        end
        
        if TeamModel:IsPVPTeam() then
            self.MatchingPlayerBtn:SetText(
            TeamModel:IsMatching() and FText.FromStringTableShort("取消匹配") or FText.FromStringTableShort("开始匹配"))
        else
            self.MatchingPlayerBtn:SetText(
            TeamModel:IsMatching() and FText.FromStringTableShort("取消匹配") or FText.FromStringTableShort("匹配"))
        end
        self.LeaveTeamBtn:SetText(FText.FromStringTableShort("解散队伍"))
        UIUtil.SetWidgetVisible(self.LeaveTeamBtn, true)
        UIUtil.SetWidgetVisible(self.StartTargetBtn, not TeamModel:IsPVPTeam())
        UIUtil.SetWidgetVisible(self.DegreeSelectBtn, true, true)
    else
		UIUtil.SetWidgetVisible(self.StartTargetBtn, true)
        UIUtil.SetWidgetVisible(self.MatchingPlayerBtn, false)
        self.StartTargetBtn:SetText(TeamModel:IsMatching() and FText.FromStringTableShort("取消匹配") or
                                        (self.isReady and FText.FromStringTableShort("取消准备") or
                                            FText.FromStringTableShort("准备")))
        self.LeaveTeamBtn:SetText(FText.FromStringTableShort("离开队伍"))
        UIUtil.SetWidgetVisible(self.LeaveTeamBtn, true)
        UIUtil.SetWidgetVisible(self.DegreeSelectBtn, false)
    end
    UIUtil.SetWidgetVisible(self.MatchingText,
                            TeamModel:IsMatching() and true or false)
    if TeamModel:IsPVPTeam() or TeamModel:IsMultiArena() then
        UIUtil.SetWidgetVisible(self.DegreeSelectBtn, false)
    else
        local DungeonModel = ModelManager:GetModel("DungeonModel")
        local DungeonCfg = DungeonModel:GetRDungeonCfgByTeamTargetId(
                           self.targetId)
        if DungeonCfg ~= nil then
            local MaxLevel = DungeonModel:GetTableCfgHighestDiffcult(DungeonCfg.Id)
            local LowLevel = DungeonModel:GetTableCfgLowestDiffcult(DungeonCfg.Id)
            if MaxLevel == LowLevel then
                UIUtil.SetWidgetVisible(self.DegreeSelectBtn, false)
            end
        end
    end
end
function TeamMatchingMainFrame:UpdateFrameTitle()
    if TeamModel:IsPVPTeam() then
        self.TitlePart:SetFirstTitle(FText.FromStringTableShort("远古竞技场"))
        local PvpcsqId = FKBinPVPTable.GetCSQIdByTeamTargetId(_G.GlobalContext, self.targetId)
        self.TitlePart:SetSecondTitle(LocalizationFText.FromStr(TeamTypes.CSQIdToStr[PvpcsqId]).str)
        return
    end
    if TeamTypes.GetTeamTargetType(self.targetId) == ResMacros.E_RES_TEAM_TARGET_CATE_TTT then
        self.TitlePart:SetFirstTitle(FText.FromStringTableShort("同心试炼"))
        local level = ArenaLibrary.GetFloorIndexByTargetID(_G.GlobalContext, self.targetId)
        local titleTxt = string.format(FText.FromStringTableShort("第%d层"),level)
        self.TitlePart:SetSecondTitle(titleTxt)
        return
    end
    if TeamTypes.GetTeamTargetType(self.targetId) == ResMacros.E_RES_TEAM_TARGET_CATE_NIGHTMARE then
        local NightmareModel = ModelManager:GetModel("NightmareModel")
        local NightmareCfg = NightmareModel:GetNightmareCfgByTeamTargetId(
                           self.targetId)
        if NightmareCfg then
            self.TitlePart:SetFirstTitle(LocalizationFText.FromStr(NightmareCfg.InstanceName).str)
            self.TitlePart:SetSecondTitle("")
            return
        end
    end
    local DungeonModel = ModelManager:GetModel("DungeonModel")
    local DungeonCfg = DungeonModel:GetRDungeonCfgByTeamTargetId(
                           self.targetId)
    if DungeonCfg then
        self.TitlePart:SetFirstTitle(LocalizationFText.FromStr(DungeonCfg.RdungeonName).str)
        self.TitlePart:SetSecondTitle(LocalizationFText.FromStr(DungeonModel:GetLevelName(
                                          DungeonCfg.RdungeonDifficult)).str)
    end
end
function TeamMatchingMainFrame:UpdateRewardTimeText()
    -- Implementation omitted.
end
function TeamMatchingMainFrame:OnClickTab_1()
    self.showListIndex = 1;
    self:UpdateInviteList();
end
function TeamMatchingMainFrame:OnClickTab_2()
    self.showListIndex = 2;
    self:UpdateInviteList();
end
function TeamMatchingMainFrame:OnClickTab_3()
    self.showListIndex = 3;
    self:UpdateInviteList();
end
function TeamMatchingMainFrame:OnClickTab_4()
    self.showListIndex = 4;
    self:UpdateInviteList();
end
function TeamMatchingMainFrame:OnCloseFrame()
    if not TeamModel:IsMatching() then
        if TeamModel:IsPVPTeam() and TeamManager:IsInTeam() == false then
            TeamModel:RemoveTeamMatchingFrame()
            return
        end
    end
    EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, FText.FromStringTableShort("组队界面已最小化"))
    TeamModel:HideTeamMatchingFrame()
end
function TeamMatchingMainFrame:OnMatchingPlayer()
    if self.isLeader then
        local allReady = true
        for i = 1, self.TeamPlayerCount do
            allReady = allReady and self.memberItems[i]:IsReady()
        end
        if not allReady then
            EventSystem.Fire("AppendNotice", EKGNoticeType.Normal,
                             FText.FromStringTableShort("有成员还未准备"));
            return
        end
    end

    if TeamModel:IsMatching() then
        TeamModel:CancelMatchReq()
    else
        TeamModel:TeamMatchReq(self.TeamPlayerCount)
    end
end
function TeamMatchingMainFrame:OnStartTarget()
    if self.isLeader then
        if TeamManager:IsInTeam() and not TeamManager:IsAllMemberReady() then
            TeamManager:UrgeMemebrsRequest()
            return
        end
       
        local MessageBoxParam = {
            DescText = FText.FromStringTableShort("您将以当前队伍开启挑战,是否确认?"),
            ButtonLayout = "ok_cancel",
            ConfirmBtnText = FText.FromStringTableShort("确认"),
            CancelBtnText = FText.FromStringTableShort("取消"),
            IsBGClickedAutoHide = true,
            ConfirmLambda = function()
                if TeamModel:IsInstanceTeam() and self.TeamPlayerCount == 1 then
                    local DungeonModel = ModelManager:GetModel("DungeonModel")
                    local DungeonCfg =
                        DungeonModel:GetRDungeonCfgByTeamTargetId(
                            self.targetId)
                    if DungeonCfg then
                        UE4.PzDungeonLibrary.ClientStartRDungeonSingleReq(
                            _G.GlobalContext, DungeonCfg.Id,
                            DungeonCfg.RdungeonDifficult)
                    end
                else
                    local ResTeamTargetCfg = ConfigManager.GetTable("ResTeamTargetCfg")
                    local Cfg = ResTeamTargetCfg:GetRowByKey(TeamModel.myTeamTargetRid)
                    local LimitNumber = Cfg.LimitMemberNum
                    if LimitNumber > 0 and TeamModel.gm_team_must_four and self.TeamPlayerCount < LimitNumber then
                        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal,
                         FText.FromStringTableShort("必须满员才可开始挑战"));
                    else
                        UE4.PzTeamFunctionLibrary.Svr_TeamLeaderEnterReq(
                            _G.GlobalContext, TeamModel.myTeamRid,
                            TeamModel.myTeamTargetRid)
                    end
                end
            end,
            CancelLambda = function() end
        }
        EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
    else
        if TeamModel:IsMatching() then
            TeamModel:CancelMatchReq()
            return
        end
        if self.isReady then
            print("[TeamMatchingMainFrame]Svr_TeamMemberReadyReq teamRid:" ..
                      tostring(TeamModel.myTeamRid) .. " targetRid:" ..
                      tostring(TeamModel.myTeamTargetRid) .. " false")
            UE4.PzTeamFunctionLibrary.Svr_TeamMemberReadyReq(_G.GlobalContext,
                                                             TeamModel.myTeamRid,
                                                             TeamModel.myTeamTargetRid,
                                                             false)
        else
            print("[TeamMatchingMainFrame]Svr_TeamMemberReadyReq teamRid:" ..
                      tostring(TeamModel.myTeamRid) .. " targetRid:" ..
                      tostring(TeamModel.myTeamTargetRid) .. " true")
            UE4.PzTeamFunctionLibrary.Svr_TeamMemberReadyReq(_G.GlobalContext,
                                                             TeamModel.myTeamRid,
                                                             TeamModel.myTeamTargetRid,
                                                             true)
        end
    end
end
function TeamMatchingMainFrame:OnLeavingTeam()
    if self.isLeader then
        if TeamModel:IsMatching() then
            EventSystem.Fire("AppendNotice", EKGNoticeType.Normal,
                             FText.FromStringTableShort("请先退出匹配"));
            return
        end
        local MessageBoxParam = {
            DescText = FText.FromStringTableShort("确认解散队伍吗?"),
            ButtonLayout = "ok_cancel",
            ConfirmBtnText = FText.FromStringTableShort("确认"),
            CancelBtnText = FText.FromStringTableShort("取消"),
            IsBGClickedAutoHide = true,
            ConfirmLambda = function()
                if TeamManager:IsInTeam() then
                    print(
                        "[TeamMatchingMainFrame]Svr_SendDismissReq teamRid:" ..
                            tostring(TeamModel.myTeamRid))
                    UE4.PzTeamFunctionLibrary.Svr_DismissTeamReq(
                        _G.GlobalContext, TeamModel.myTeamRid)
                else
                    TeamModel:SetTeamRid(0)
                    TeamModel:RemoveTeamMatchingFrame()
                    TeamModel:UpdateTeamFrameViewState()
                end
            end,
            CancelLambda = function() end
        }
        EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
    else
        local MessageBoxParam = {
            DescText = FText.FromStringTableShort("确认离开队伍吗?"),
            ButtonLayout = "ok_cancel",
            ConfirmBtnText = FText.FromStringTableShort("确认"),
            CancelBtnText = FText.FromStringTableShort("取消"),
            IsBGClickedAutoHide = true,
            ConfirmLambda = function()
                print("[TeamMatchingMainFrame]Svr_SendLeaveReq teamRid:" ..
                          tostring(TeamModel.myTeamRid))
                UE4.PzTeamFunctionLibrary.Svr_SendLeaveReq(_G.GlobalContext,
                                                           TeamModel.myTeamRid)
            end,
            CancelLambda = function() end
        }
        EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
    end
end
function TeamMatchingMainFrame:ReqPlayersDetails()
    local memberDatas = self.inviteTabDataFuncTable[self.showListIndex]();
    local watchPlayers = {};
    for i = 1, #memberDatas do
        table.insert(watchPlayers, memberDatas[i].roleId)
    end
    table.insert(watchPlayers, GameUtil.GetMyPlayerRID())
    local TeamData = TeamManager:GetTeamData()
    for i = 1, TeamData.Member:Num() do
        local memberRid = TeamData.Member:Get(i - 1).ActorRid
        if memberRid ~= GameUtil.GetMyPlayerRID() then
            table.insert(watchPlayers, memberRid)
        end
    end
    OtherPlayerModel.OnPlayerAttrReq(watchPlayers, function()
        EventSystem.Fire("OnTeamMatchingWatchCompleted")
    end, true)
end
function TeamMatchingMainFrame:OnTeamMatchingWatchCompleted()
end
function TeamMatchingMainFrame:OnChangeTeamTargetNotify(e,r,targetId)
    self.targetId = targetId
end
function TeamMatchingMainFrame:OnPlayerChangeReadyState(e, r, actorRid, isReady)
    if actorRid == GameUtil.GetMyPlayerRID() then
        self.isReady = isReady
        self:UpdateFrameBtns()
    end
end
function TeamMatchingMainFrame:OnTeamStageChanged()
    if TeamModel:IsMatching() then self.isReady = true end
    self:UpdateFrameBtns()
end
function TeamMatchingMainFrame:OnTeamHUDStageChanged()
    self:UpdateFrameBtns()
end
function TeamMatchingMainFrame:OnRefreshUrgeBtnTimer()
    if self.isLeader and TeamManager:IsInTeam() and not TeamManager:IsAllMemberReady() then
        local coolDown = TeamManager:GetUrgeMemebrCoolDown()
        if coolDown == 0 then
            self.StartTargetBtn:SetText(FText.FromStringTableShort("催促准备"))
            self.StartTargetBtn:SetIsEnabled(true)
        else
            self.StartTargetBtn:SetText(FText.FromStringTableShort("催促准备").."("..tostring(math.ceil(coolDown)).."s)")
            self.StartTargetBtn:SetIsEnabled(false)
        end
    end
end
function TeamMatchingMainFrame:OnRecommendListRecieved()
    if self.showListIndex == 1 then
        self:UpdateInviteList();
    end
end
function TeamMatchingMainFrame:OnDegreeSelect()
    -- Implementation omitted.
end
function TeamMatchingMainFrame:OnSelectBGButton()
    -- Implementation omitted.
end
function TeamMatchingMainFrame:OnChangeInstanceDifficultLevel(e,r,uniqueId)
    -- Implementation omitted.
end
function TeamMatchingMainFrame:OnShare()
    -- Implementation omitted.
end

return TeamMatchingMainFrame;
