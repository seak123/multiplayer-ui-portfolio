-- The service port stands in for native arena calls; it never sends real RPCs here.
local Contract = require("MatchContract")
local ArenaAdapter = {}
ArenaAdapter.__index = ArenaAdapter

-- These symbolic wire values are fixtures, not recovered protocol enumerations.
local phases = {
    NONE = "idle", QUEUED = "searching",
    RESERVED = "awaiting_confirmation", ENTERING = "entering",
}

function ArenaAdapter.new(service)
    return setmetatable({ service = assert(service, "arena service required") }, ArenaAdapter)
end

-- Ports represent existing mode-owned data and events, not new data ownership.
function ArenaAdapter:RegisterEvents(context, changed)
    self:UnregisterEvents()
    self.unsubscribe = self.service:Subscribe(context.targetId, changed)
    assert(type(self.unsubscribe) == "function", "unsubscribe function required")
end

function ArenaAdapter:UnregisterEvents()
    local unsubscribe = self.unsubscribe
    self.unsubscribe = nil
    if unsubscribe then unsubscribe() end
end

function ArenaAdapter:ReadSnapshot(context)
    return self.service:GetSnapshot(context.targetId)
end

function ArenaAdapter:BuildState(context, snapshot)
    return Contract.State(phases[snapshot.queueStage] or "unknown", snapshot.queueStage,
        "arena_queue", { queueLabel = snapshot.queueLabel, targetId = context.targetId },
        snapshot.matchedPlayers)
end

function ArenaAdapter:Start(context, party)
    local arenaId = assert(self.service:ResolveArenaId(context.targetId), "unmapped arena target")
    if #party.members <= 1 then
        return self.service:StartSolo(arenaId)
    end
    return self.service:StartParty(arenaId)
end

function ArenaAdapter:Cancel(context, party)
    return self.service:Cancel()
end

return ArenaAdapter
