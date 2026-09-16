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
