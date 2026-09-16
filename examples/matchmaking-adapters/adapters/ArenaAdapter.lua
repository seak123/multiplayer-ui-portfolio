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
