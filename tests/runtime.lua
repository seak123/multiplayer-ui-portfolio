-- Portfolio-only deterministic test doubles. No production transport or UMG.
state = {inTeam=true, allReady=false, selfReady=false, count=2,
    visible=true, single=false, busy=false, pending=false, robot=0, csq=0}
events = {}
requests = 0
queue = {}
records = {[101]={CurrentMapId=1}}
UE4 = {
    ESlateVisibility={Collapsed="collapsed", SelfHitTestInvisible="visible"},
    EUMGSequencePlayMode={Forward=1},
    PzGameLuaLibrary={
        IsCurrentMapShowTeamState=function() return state.visible end,
        IsMarkedMapBusy=function() return state.busy end,
        GetNewFeaturesManager=function() return {} end,
    },
    PzTeamFunctionLibrary={GetCurrentRobotID=function() return state.robot end},
    PzPVPLibrary={IsSingleMatching=function() return state.single end},
    PzMultiPlayerLibrary={},
}
UE = {UGameLuaLibrary=UE4.PzGameLuaLibrary}
manager = {
    IsInTeam=function() return state.inTeam end,
    IsAllMemberReady=function() return state.allReady end,
    IsSelfReady=function() return state.selfReady end,
    GetTeamMemberNum=function() return state.count end,
}
matchManager = {GetCurrentCSQTid=function() return state.csq end}
supportManager = {IsAssistPlayerValid=function() return not state.pending end}
UE4.PzTeamFunctionLibrary.GetTeamManager=function() return manager end
UE4.PzPVPLibrary.GetClientMatchManager=function() return matchManager end
UE4.PzMultiPlayerLibrary.GetMultiPlayerManager=function() return supportManager end
GameUtil={GetMyPlayerRID=function() return 101 end}
ConfigManager={GetTable=function() return {} end}
GScope={Scope={Create=function() return {} end}}
ResMacros=setmetatable({}, {__index=function(_,key) return key end})
models={}
ModelManager={
    CreateModel=function(_,name)
        local model={}
        models[name]=model
        return model, {_init=function() end}
    end,
    GetModel=function(_,name) return models[name] or {} end,
}
function CreateUIBehaviourFromListItem() return {}, {_init=function() end} end
function GetTableDefine() return {GetVisitTimeString=function() return "earlier" end} end
function import(name) return UE4[name] end
LocalizationFText={FromStr=function(s) return {str=s} end}
EventSystem={Fire=function(name,...) events[#events+1]=name end}
OtherPlayerModel={
    GetPlayerAttrInCache=function(id) return records[id] end,
    OnPlayerAttrReq=function(ids,callback)
        requests=requests+1
        queue[#queue+1]=callback
    end,
}
function widget()
    return {
        SetVisibility=function(self,x) self.visibility=x end,
        SetActiveWidgetIndex=function(self,x) self.index=x end,
        SetText=function(self,x) self.text=x end,
        StopAnimation=function(self,...) self.playing=false end,
        PlayAnimation=function(self,...) self.playing=true end,
    }
end
function attachItem(item)
    item.data={OwnerRID=101, IsShowRecommendPlayer=true, IsOnline=true,
        VisitTimestamp=0, LastOnlineTime=0}
    item.RobotID=0
    item.UIInviteVisitBtnGroup=widget()
    item.UIAddFriendSwitch=widget()
    item.UIReqAssistSwitcher=widget()
    item.UIOffLine=widget()
    item._target=widget()
    return item
end
function drain(limit)
    local count=0
    while #queue>0 and count<limit do
        local callback=table.remove(queue,1)
        callback()
        count=count+1
    end
    return count, #queue
end
frames={}
__BehaviourManager={GetBehaviour=function(_,id) return frames[id] end}
function instrumentFrames(model)
    model.matchingFrameID=10
    model.noticeFrameID=20
    model.OpenTeamMatchingNoticeFrame=function() frames[20]={} end
    model.RemoveTeamMatchingNoticeFrame=function() frames[20]=nil end
    model.RemoveTeamMatchingFrame=function() frames[10]=nil end
end
