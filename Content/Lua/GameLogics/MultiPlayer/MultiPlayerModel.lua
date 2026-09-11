-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local MultiPlayerModel, superClass = ModelManager:CreateModel("MultiPlayerModel")
local super = superClass
local MultiPlayerMgr = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext)
local NewFeaturesUnlockMgr = UE4.PzGameLuaLibrary.GetNewFeaturesManager(_G.GlobalContext)
local MultiPlayerWorldTable = GetTableDefine("MultiPlayerWorldTable")
local setting =
{
    Events =
    {
        ["LogicEvent_PlayWorld_PreSendTPReq"] = "OnPreTPWorld",
        ["LogicEvent_PlayWorld_PreTPWorld"] = "OnPreTPWorld",
        ["LogicEvent_Tribe_OpenTribeCreatePanel"] = "AddTribeCreateFrame",
        ["NetEvent_PlayWorld_TribeCreateSucceeded"] = "AddTribeChatFrame",
        ["NetEvent_PlayWorld_TribeInviteReqReceived"] = "OnInviteMemberSendFinished",
        ["OnRequestOpenAssistPanel"] = "OnRequestOpenAssistPanel",
        ["PZ_GAME_PLAYER_STATE_CLIENT_INITIALIZE"] = "OnPlayerStateInit",
		["OnSystemFunctionStatusUnlock"] = "OnSysFuncUnlock",
		["OnSystemFunctionStatusUpdate"] = "OnSysFuncSync",
    },
}
local MultiPlayerPanel_Path = "WidgetBlueprint'/Game/UI/Panel/MultiPlayer/WBP_MPlayer_Frame.WBP_MPlayer_Frame_C'"
local SettlementPanel_Path = "WidgetBlueprint'/Game/UI/Panel/Settlement/WBP_Settlement_Frame.WBP_Settlement_Frame_C'"
local MultiPlayerChangeNamePanel_Path = "WidgetBlueprint'/Game/UI/Panel/Settlement/WBP_Settlement_ChangeNamePanel.WBP_Settlement_ChangeNamePanel_C'"
local TribeCreatePanel_Path = "WidgetBlueprint'/Game/UI/Panel/Tribe/TribeCreate/WBP_TribeCreate_Frame.WBP_TribeCreate_Frame_C'"
local TribeListPanel_Path = "WidgetBlueprint'/Game/UI/Panel/Tribe/WBP_Tribe_ListPanel.WBP_Tribe_ListPanel_C'"
local CommonRewardPanel_Path = "WidgetBlueprint'/Game/UI/Panel/Common/Reward/WBP_Common_SingleRewardBox.WBP_Common_SingleRewardBox_C'"
local CommunityChat_Path = "WidgetBlueprint'/Game/UI/Panel/Community/WBP_Community_Chat_Frame.WBP_Community_Chat_Frame_C'"
local SettlementInvite_Path = "WidgetBlueprint'/Game/UI/Panel/Settlement/A9Settlement/WBP_Settlement_InvitePanel.WBP_Settlement_InvitePanel_C'"
function MultiPlayerModel:_init()
    super._init(self, setting)
    self.HeadIconIndexCache = {}
    self:MyResetData()
end
function MultiPlayerModel:MyResetData()
end
function MultiPlayerModel:OnPlayerStateInit()
    MultiPlayerMgr:Svr_ReqSyncPersonalSettlementData()
end
function MultiPlayerModel:AddMultiPlayerFrame(tabIndex)
    UIUtil.AddUniqueFrameAsync(MultiPlayerPanel_Path, function(frame)
        if frame then
            local targetID = frame:GetUniqueID()
            local Panel = __BehaviourManager:GetBehaviour(targetID)
            Panel.m_BindModel = self
            Panel:OnMyShowPanel(tabIndex)

            if UE4.PzGameLuaLibrary.GetPlayerPrefsIntWithDefault(_G.GlobalContext, self:GetMultiplayerRedHintTypes(), -1) == 1 then
                UE4.PzGameLuaLibrary.SetPlayerPrefsInt(_G.GlobalContext, self:GetMultiplayerRedHintTypes(), 2)
            end
            RedUtil.UpdateHintCount(self:GetMultiplayerRedHintTypes(), 0)

        end
    end)
end
function MultiPlayerModel:AddSettlementFrame()
    -- Implementation omitted.
end
function MultiPlayerModel:AddMultiPlayerChangeNameFrame(TribeId)
    -- Implementation omitted.
end
function MultiPlayerModel:AddSettlementInviteFrame()
    -- Implementation omitted.
end
function MultiPlayerModel:AddRewardBoxFrame(rewardBoxId)
    -- Implementation omitted.
end
function MultiPlayerModel:AddTribeCreateFrame()
    -- Implementation omitted.
end
function MultiPlayerModel:AddTribeChatFrame(_, _, TribeId)
    -- Implementation omitted.
end
function MultiPlayerModel:OnInviteMemberSendFinished()
    -- Implementation omitted.
end
function MultiPlayerModel:AddTribeListFrame()
    -- Implementation omitted.
end
local TribeChangeDeclarationPanel_Path = "WidgetBlueprint'/Game/UI/Panel/Tribe/WBP_Tribe_ChangeDeclarationPanel.WBP_Tribe_ChangeDeclarationPanel_C'"
function MultiPlayerModel:AddChangeTribeDeclarationFrame(TribeId)
    -- Implementation omitted.
end
local TribeChangeNamePanel_Path = "WidgetBlueprint'/Game/UI/Panel/Tribe/WBP_Tribe_ChangeNamePanel.WBP_Tribe_ChangeNamePanel_C'"
function MultiPlayerModel:AddChangeTribeNameFrame(TribeId)
    -- Implementation omitted.
end
local TribeChangeTagPanel_Path = "WidgetBlueprint'/Game/UI/Panel/Tribe/WBP_Tribe_ChangeTagPanel.WBP_Tribe_ChangeTagPanel_C'"
function MultiPlayerModel:AddChangeTribeTagFrame(TribeId)
    -- Implementation omitted.
end
function MultiPlayerModel:OnPreTPWorld()
    -- Implementation omitted.
end
function MultiPlayerModel:GetSocialRedHintTypes()
    -- Implementation omitted.
end
function MultiPlayerModel:GetMultiplayerRedHintTypes()
    -- Implementation omitted.
end
function MultiPlayerModel:OnSysFuncUnlock(_, _, id)
    -- Implementation omitted.
end
function MultiPlayerModel:OnSysFuncSync()
    -- Implementation omitted.
end
function MultiPlayerModel:RefreshIntimacyUI(score, level, uiGroup, uiIcon, uiLabel)
    -- Implementation omitted.
end
function MultiPlayerModel:GMShowAssistItem(AssistID)
    -- Implementation omitted.
end
function MultiPlayerModel:RequestAssist(AssistID)
    self.AssistId = AssistID
    local ResInviteAssistConfig = ConfigManager.GetTable("ResInviteAssist")
    local AssistCfg = ResInviteAssistConfig:GetRowByKey(AssistID)
    if AssistCfg == nil then
        EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, tostring(AssistID)..LocalizationFText.FromStr("不是有效的支援ID").str)
    else
        for index = 0, 4 do
            if AssistCfg.NeedAchivements[index] > 0 then
                local AchvMgr = UE4.PzAchvManagerLibrary.GetAchvManager(_G.GlobalContext)
                local isCompleted = AchvMgr:IsAchvFinish(AssistCfg.NeedAchivements[index])
                if not isCompleted then
                    EventSystem.Fire("AppendNotice", EKGNoticeType.Normal, LocalizationFText.FromStr("提升超控核心等级，才能解锁请求支援").str)
                    return
                end
            end
        end 
    end
    UIUtil.AddUniqueFrameAsync(MultiPlayerPanel_Path, function(frame)
        if frame then
            local targetID = frame:GetUniqueID()
            local Panel = __BehaviourManager:GetBehaviour(targetID)
            Panel.m_BindModel = self
            Panel:OnMyShowPanel(1, true)
        end
    end)
end
function MultiPlayerModel:OnRequestOpenAssistPanel(e,r,AssistID)
    self:RequestAssist(AssistID)
end
function MultiPlayerModel:AddTribeCommunityChatFrame(channelId, bTip)
    -- Implementation omitted.
end
function MultiPlayerModel:GetTribeNum()
    -- Implementation omitted.
end
return MultiPlayerModel
