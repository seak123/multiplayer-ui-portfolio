-- Historical function excerpts, not the complete file. Do not use in production.
-- before the callback-cycle fix; see docs/DEBUGGING.md.
local MultiPlayerWorldItem = {}
local ESlateVisibility = UE4.ESlateVisibility
function MultiPlayerWorldItem:RefreshAssistGroup()
    if self.data.IsShowRecommendPlayer then
        self.UIInviteVisitBtnGroup:SetVisibility(ESlateVisibility.Collapsed)
        self.UIAddFriendSwitch:SetVisibility(ESlateVisibility.Collapsed)
        self.UIReqAssistSwitcher:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.UIInviteVisitBtnGroup:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.UIAddFriendSwitch:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.UIReqAssistSwitcher:SetVisibility(ESlateVisibility.Collapsed)
    end
     if self.data.IsShowRecommendPlayer then
        if self.RobotID > 0 then
            local CurExsitRob = UE4.PzTeamFunctionLibrary.GetCurrentRobotID(_G.GlobalContext)
            if CurExsitRob > 0 then
                self.UIReqAssistSwitcher:SetActiveWidgetIndex(2)
                return
            end
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(0) 
            return
        end
        local bAssistValid = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):IsAssistPlayerValid(self.data.OwnerRID)
        if bAssistValid then
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(0)
            self._target:StopAnimation(self._target["BtnWaiting"])
        else
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(1)
            self._target:PlayAnimation(self._target["BtnWaiting"], 0, 0, UE4.EUMGSequencePlayMode.Forward, 1, false)
        end
        if self.RobotID == 0 then
            local PlayerId = {self.data.OwnerRID}
            OtherPlayerModel.OnPlayerAttrReq(PlayerId, function()
                EventSystem.Fire("OnAssistPlayerWatchCompleted")
            end, true)
        end
    end
end

function MultiPlayerWorldItem:OnAssistPlayerWatchCompleted()
    local record = OtherPlayerModel.GetPlayerAttrInCache(self.data.OwnerRID)
    if record ~= nil then
        local NeedMarked = UE4.PzGameLuaLibrary.IsMarkedMapBusy(_G.GlobalContext, record.CurrentMapId)
        if NeedMarked then
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(3)
        else
            local bAssistValid = UE4.PzMultiPlayerLibrary.GetMultiPlayerManager(_G.GlobalContext):IsAssistPlayerValid(self.data.OwnerRID)
            if bAssistValid then
                self.UIReqAssistSwitcher:SetActiveWidgetIndex(0)
                self._target:StopAnimation(self._target["BtnWaiting"])
            else
                self.UIReqAssistSwitcher:SetActiveWidgetIndex(1)
                self._target:PlayAnimation(self._target["BtnWaiting"], 0, 0, UE4.EUMGSequencePlayMode.Forward, 1, false)
            end
        end
    end
    if self.RobotID == 0 then
        local PlayerId = {self.data.OwnerRID}
        OtherPlayerModel.OnPlayerAttrReq(PlayerId, function()
            EventSystem.Fire("OnAssistPlayerWatchCompleted")
        end)
    end
end

function MultiPlayerWorldItem:OnAssistPlayerWatchCompleted()
    local record = OtherPlayerModel.GetPlayerAttrInCache(self.data.OwnerRID)
    if record ~= nil then
        local NeedMarked = UE4.PzGameLuaLibrary.IsMarkedMapBusy(_G.GlobalContext, record.CurrentMapId)
        if NeedMarked then
            self.UIReqAssistSwitcher:SetActiveWidgetIndex(3)
        else
            self:RefreshAssistGroup()
        end
    end
end

return MultiPlayerWorldItem
