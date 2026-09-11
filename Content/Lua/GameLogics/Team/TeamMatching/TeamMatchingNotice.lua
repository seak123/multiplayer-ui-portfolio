-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamMatchingNotice, super = CreateUIBehaviour("TeamMatchingNotice")
local ESlateVisibility = import("ESlateVisibility")
local TeamManager = UE4.PzTeamFunctionLibrary.GetTeamManager(_G.GlobalContext)
local TeamModel = ModelManager:GetModel("TeamModel")
local MatchMgr = UE4.PzPVPLibrary.GetClientMatchManager(_G.GlobalContext)
local Timer = require "GameCore.GameEvent.Timer"

local setting = {
    Elements = {
        {Name = "NoticeText"},
        {Name = "CloseBtn", Handles = {OnClicked = "OnClose"}},
        {Name = "NoticeBtn", Handles = {OnClicked = "OnClickNoticeBtn"}},
        {Name = "StateTxt"}, {Name = "StateImg"},
        {Name = "TimeTxt",},
        {Name = "Fx_Group"}
    },
    Events = {
        ["OnTeamStageChanged"] = "OnTeamStageChanged",
        ["OnTeamHUDStageChanged"] = "OnTeamStageChanged",
        ["OnUpdateTeamFrameViewState"] = "OnUpdateTeamFrameViewState",
        ["PZ_ON_CULTURE_CHANGED"] = "UpdateState",

    },
    Timers = {
		{
			Name = "MatchNoticeTimer",
			Timer = Timer:Always(0.5),
			Handler = "OnMatchNoticeTimerUpdate",
		}
	}                  
}

function TeamMatchingNotice:_init(go)
    super._init(self, go, setting)
    self:Init()
end

function TeamMatchingNotice:Init()
    self.teamStage = TeamTypes.TeamStage.None
    UIUtil.SetWidgetVisible(self.CloseBtn, false)
    UIUtil.SetWidgetVisible(self.TimeTxt, false)
    self:UpdateState()
    self._target:PlayAnimation(self._target["Loop"], 0, 0, UE4.EUMGSequencePlayMode.Forward, 1, false)
end

function TeamMatchingNotice:Hide() self._target:Hide() end

function TeamMatchingNotice:OnDestroy()
    TeamModel:OnTeamMatchingNoticeFrameHide()
end
function TeamMatchingNotice:UpdateState()
    local HUDStateCfg = TeamTypes.HUDStateCfg[TeamModel.HUDState]

    local DungeonModel = ModelManager:GetModel("DungeonModel")
    local DungeonCfg = DungeonModel:GetRDungeonCfgByTeamTargetId(
                           TeamModel.myTeamTargetRid)
    if DungeonCfg then
        self.NoticeText:SetText(string.format(HUDStateCfg.NoticeText,
        LocalizationFText.FromStr(DungeonCfg.RdungeonName).str))
    end
    
    self.StateTxt:SetText(LocalizationFText.FromStr(HUDStateCfg.StateText))

    if TeamModel.HUDState == TeamTypes.HUDState.AllReady and TeamModel:IsPVPTeam() then
        self.StateTxt:SetText(FText.FromStringTableShort("开始匹配"))
    end

    UIUtil.SetImagePathAsync(self.StateImg, HUDStateCfg.BGPath, false)
    self._target:PlayLoopAnim(HUDStateCfg.HUDAnim)

    local targetId = TeamModel.myTeamTargetRid
    if TeamModel:IsPVPTeam() then
        local PvpcsqId = FKBinPVPTable.GetCSQIdByTeamTargetId(_G.GlobalContext, targetId)
        self.NoticeText:SetText(LocalizationFText.FromStr(TeamTypes.CSQIdToStr[PvpcsqId]).str)
    end
    if TeamTypes.GetTeamTargetType(targetId) == ResMacros.E_RES_TEAM_TARGET_CATE_NIGHTMARE then
        local NightmareModel = ModelManager:GetModel("NightmareModel")
        local NightmareCfg = NightmareModel:GetNightmareCfgByTeamTargetId(targetId)
        if NightmareCfg then
            self.NoticeText:SetText(LocalizationFText.FromStr(NightmareCfg.InstanceName).str)
        end
    end
    if TeamModel:IsMultiArena() then
        self.NoticeText:SetText(LocalizationFText.FromStr(TeamTypes.MultiArenaHUDNoticeStr).str)
    end
    self:OnMatchNoticeTimerUpdate()
end
function TeamMatchingNotice:OnClose()
    local stage = TeamModel.teamStage

    if TeamModel:IsMatching() then
        local MessageBoxParam = {
            DescText = FText.FromStringTableShort("退出匹配吗"),
            ButtonLayout = "ok_cancel",
            ConfirmBtnText = FText.FromStringTableShort("确认"),
            CancelBtnText = FText.FromStringTableShort("取消"),
            IsBGClickedAutoHide = true,
            ConfirmLambda = function() TeamModel:CancelMatchReq() end,
            CancelLambda = function() end
        }
        EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
    elseif stage == TeamTypes.TeamStage.TeamState then
        local MessageBoxParam = {
            DescText = FText.FromStringTableShort("退出组队吗"),
            ButtonLayout = "ok_cancel",
            ConfirmBtnText = FText.FromStringTableShort("确认"),
            CancelBtnText = FText.FromStringTableShort("取消"),
            IsBGClickedAutoHide = true,
            ConfirmLambda = function()
                if TeamManager:IsInTeam() then
                    UE4.PzTeamFunctionLibrary.Svr_SendLeaveReq(_G.GlobalContext,
                                                               TeamModel.myTeamRid)
                else
                    TeamModel:RemoveTeamMatchingNoticeFrame()
                end
            end,
            CancelLambda = function() end
        }
        EventSystem.Fire("UIEvent_MessageBox_Show", MessageBoxParam)
    end
end

function TeamMatchingNotice:OnClickNoticeBtn()
    local bSingePVP = UE4.PzPVPLibrary.IsSingleMatching(_G.GlobalContext)
    if bSingePVP then
        KG.PVPModel:AddEnterFrame()
    else
        if TeamModel:GetTeamRid() ~= 0 then
            TeamModel:RemoveTeamMatchingNoticeFrame()
            TeamModel:RecoverTeamPanel() 
        end
    end
end
function TeamMatchingNotice:OnTeamStageChanged(e, r) self:UpdateState() end

function TeamMatchingNotice:OnMatchNoticeTimerUpdate()
    if TeamModel:IsPVPTeam() then --PVP匹配时，显示已进行了匹配的时间
        local HasWaitTime = MatchMgr:GetHasWaitMatchTime()
        if HasWaitTime>0 then
            UIUtil.SetWidgetVisible(self.TimeTxt, true)
            local Minute = math.floor(HasWaitTime / 60)
            local Second = HasWaitTime - 60 * Minute
            local TimeStr = string.format("%02d:%02d", Minute, Second)
            self.TimeTxt:SetText(TimeStr)
            return            
        end        
    end

    UIUtil.SetWidgetVisible(self.TimeTxt, false)
end

return TeamMatchingNotice;
