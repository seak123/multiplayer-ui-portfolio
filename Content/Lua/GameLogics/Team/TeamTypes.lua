-- PORTFOLIO SOURCE EXCERPT | original file/module names retained.
-- Implementation map: docs/source-manifest.json.
-- Not a standalone game: original framework/assets/services are external.
local TeamTypesScope = GScope.Scope.Create("globe.model.TeamTypes")

TeamTypes = {}
function TeamTypes.GetMemberList_World()
    local PlayWorldData = ModelManager:GetModel("PlayWorldData")
    local worldMembers = PlayWorldData:GetPlayWorldMemberList()
    local MyRoleId = UE.UGameLuaLibrary.GetMyPlayerRID(_G.GlobalContext)
    local list = {}
    for i = 1, #worldMembers do
        if worldMembers[i].RoleId ~= MyRoleId then
            local info = {}
            info.roleId = worldMembers[i].RoleId
            info.level = worldMembers[i].Level
            info.name = worldMembers[i].Name
            info.isOnline = worldMembers[i].IsOnline
            info.iconIndex = 0
            local attrCache = OtherPlayerModel.GetPlayerAttrInCache(info.roleId)
            if attrCache then
                info.name = attrCache.Name
                info.iconIndex = attrCache.IconIdx
                info.bOnline = attrCache.IsOnline
                info.level = attrCache.Level
            end
            if info.roleId ~= GameUtil.GetMyPlayerRID() then
                table.insert(list, info)
            end
        end
    end
    return list
end

function TeamTypes.GetMemberList_Friend()
    local FriendModel = ModelManager:GetModel("FriendModel")
    local friends = FriendModel:GetFriendInfo()
    local list = {}
    for i = 1, #friends do
        local info = {}
        info.roleId = friends[i].PlayerRoleId
        info.level = 1 -- 暂时缺少等级
        info.name = friends[i].Name
        info.isOnline = friends[i].IsOnline
        info.iconIndex = 0
        local attrCache = OtherPlayerModel.GetPlayerAttrInCache(info.roleId)
        if attrCache then
            info.name = attrCache.Name
            info.iconIndex = attrCache.IconIdx
            info.bOnline = attrCache.IsOnline
            info.level = attrCache.Level
        end
        if info.roleId ~= GameUtil.GetMyPlayerRID() then
            table.insert(list, info)
        end
    end
    return list
end

function TeamTypes.GetMemberList_Recent()
    local list = {}
    local TeamModel = ModelManager:GetModel("TeamModel")
    for i = 1, #TeamModel.recentTeammates do
        local info = {}
        info.roleId = TeamModel.recentTeammates[i]
        local newRecord = OtherPlayerModel.GetPlayerAttrInCache(
                              TeamModel.recentTeammates[i])
        if newRecord ~= nil then
            info.level = newRecord.Level
            info.name = newRecord.Name
            info.isOnline = newRecord.IsOnline
            info.iconIndex = newRecord.IconIdx
        end
        if info.roleId ~= GameUtil.GetMyPlayerRID() then
            table.insert(list, info)
        end
    end
    return list
end

function TeamTypes.GetMemberList_Recommand()
    local list = {}
    local PlayWorldData = ModelManager:GetModel("PlayWorldData")
    BriefDataList = PlayWorldData:GetWorldBriefDataList()
    for _, SingleBrief in pairs(BriefDataList) do
        local info = {}
        info.roleId = SingleBrief.OwnerRID
        info.level = SingleBrief.OwnerLevel
        info.isOnline = true
        info.iconIndex = info.roleId % 10
        local attrCache = OtherPlayerModel.GetPlayerAttrInCache(info.roleId)
        if attrCache then
            info.name = attrCache.Name
            info.iconIndex = attrCache.IconIdx
            info.bOnline = attrCache.IsOnline
            info.level = attrCache.Level
        end
        if info.roleId ~= GameUtil.GetMyPlayerRID() then
            table.insert(list, info)
        end
    end
    return list
end

TeamTypes.WorldTabCfg = {
    Title = "Team.WorldTab",
    GetMembersFunc = TeamTypes.GetMemberList_World
}

TeamTypes.FriendTabCfg = {
    Title = "Team.FriendTab",
    GetMembersFunc = TeamTypes.GetMemberList_Friend
}

TeamTypes.RecentTabCfg = {
    Title = "Team.RecentTab",
    GetMembersFunc = TeamTypes.GetMemberList_Recent
}

TeamTypes.RecommandTabCfg = {
    Title = "Team.RecommandTab",
    GetMembersFunc = TeamTypes.GetMemberList_Recommand
}

TeamTypes.TabType = {
    Instance = {
        [1] = TeamTypes.RecommandTabCfg,
        [2] = TeamTypes.FriendTabCfg,
        [3] = TeamTypes.RecentTabCfg
    }
}

TeamTypes.TeamStage = {
    None = 0, -- 无状态
    TeamState = 1, -- 组队面板
    Matching = 2 -- 匹配成功确认阶段
}

TeamTypes.HUDState = {
    UnReady = 1, -- 作为队员未准备,待准备
    Ready = 2, -- 作为队员已准备,或者只有队长自己
    Matching = 3, -- 匹配中
    AllReady = 4 -- 全员已准备,队长进入该状态
}

TeamTypes.HUDStateCfg = {
    [TeamTypes.HUDState.UnReady] = {
        NoticeText = "<D03>%s</>",
        StateText = "Team.Waiting",
        HUDAnim = true,
        BGPath = "VtaSlateTexture'/Game/common_resource/UI/Atlas/Common/Component/HudNotice/HudNotice/Frame_NewMessage_Bg.Frame_NewMessage_Bg'"
    },
    [TeamTypes.HUDState.Ready] = {
        NoticeText = "<D03>%s</>",
        StateText = "Team.Teaming",
        HUDAnim = false,
        BGPath = "VtaSlateTexture'/Game/common_resource/UI/Atlas/Common/Component/HudNotice/HudNotice/Frame_NewMessage_Bg.Frame_NewMessage_Bg'"
    },
    [TeamTypes.HUDState.Matching] = {
        NoticeText = "<D03>%s</>",
        StateText = "Team.Matching",
        HUDAnim = true,
        BGPath = "VtaSlateTexture'/Game/common_resource/UI/Atlas/Common/Component/HudNotice/HudNotice/Frame_NewMessage_Bg.Frame_NewMessage_Bg'"
    },
    [TeamTypes.HUDState.AllReady] = {
        NoticeText = "<D03>%s</>",
        StateText = "Team.Starting",
        HUDAnim = true,
        BGPath = "VtaSlateTexture'/Game/common_resource/UI/Atlas/Common/Component/HudNotice/HudNotice/Frame_NewMessage_Bg.Frame_NewMessage_Bg'"
    }
}

TeamTypes.CSQIdToStr = {
    [ResMacros.RES_CSQ_FAIR_1V1] = "Team.CSQFAIR1V1",
    [ResMacros.RES_CSQ_FAIR_3V3] = "Team.CSQFAIR3V3",
    [ResMacros.RES_CSQ_FAIR_4V4] = "Team.CSQFAIR4V4",
    [ResMacros.RES_CSQ_1V1] = "Team.CSQ1V1",
    [ResMacros.RES_CSQ_3V3] = "Team.CSQ3V3",
    [ResMacros.RES_CSQ_4V4] = "Team.CSQ4V4",
    [ResMacros.RES_CSQ_1V1_MECHA] = "Team.CSQ1V1MECHA",
}

TeamTypes.MultiArenaHUDNoticeStr = "Team.MultiArenaHUD"

function TeamTypes.GetTeamTargetType(TargetId)
    local ResTeamTargetCfg = ConfigManager.GetTable("ResTeamTargetCfg")
    local Cfg = ResTeamTargetCfg:GetRowByKey(TargetId)
    if Cfg then
        return Cfg.TargetCate
    end

end

return TeamTypes
