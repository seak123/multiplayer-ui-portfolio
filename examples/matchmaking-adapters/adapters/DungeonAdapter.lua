local Contract = require("MatchContract")
local DungeonAdapter = {}
DungeonAdapter.__index = DungeonAdapter

-- Different fixture fields and stage names map into the same presentation contract.
local phases = {
    FORMING = "idle", FINDING_MEMBERS = "searching",
    READY_CHECK = "awaiting_confirmation", TRANSFERRING = "entering",
}

function DungeonAdapter.new(service)
    return setmetatable({ service = assert(service, "team service required") }, DungeonAdapter)
end

-- Ports represent existing mode-owned data and events, not new data ownership.
function DungeonAdapter:RegisterEvents(context, changed)
    self:UnregisterEvents()
    self.unsubscribe = self.service:Subscribe(context.targetId, changed)
    assert(type(self.unsubscribe) == "function", "unsubscribe function required")
end

function DungeonAdapter:UnregisterEvents()
    local unsubscribe = self.unsubscribe
    self.unsubscribe = nil
    if unsubscribe then unsubscribe() end
end

function DungeonAdapter:ReadSnapshot(context)
    return self.service:GetSnapshot(context.targetId)
end

function DungeonAdapter:BuildState(context, snapshot)
    return Contract.State(phases[snapshot.teamPhase] or "unknown", snapshot.teamPhase,
        "dungeon_objective", { objective = snapshot.objective, targetId = context.targetId },
        snapshot.matchMembers)
end

function DungeonAdapter:Start(context, party)
    return self.service:SetMatching(context.targetId, true)
end

function DungeonAdapter:Cancel(context, party)
    return self.service:SetMatching(context.targetId, false)
end

return DungeonAdapter
