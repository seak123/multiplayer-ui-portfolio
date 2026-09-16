-- Shared party state + one selected matchmaking strategy.
-- This does not replace the retained Content/.../TeamModel.lua excerpt.
local Contract = require("MatchContract")
local Model = {}
Model.__index = Model

function Model.new(registry, publish)
    return setmetatable({
        registry = registry,
        publish = publish or function() end,
        party = { members = {} },
        match = Contract.Unavailable(),
    }, Model)
end

function Model:SelectMode(mode, context)
    -- Resolve first: an unsupported mode must not partially replace active state.
    local adapter = self.registry:Create(mode)
    assert(type(context) == "table" and context.targetId ~= nil, "target required")
    self.adapter, self.mode = adapter, mode
    self.context = Contract.Copy(context)
    self.match = Contract.Unavailable()
    self:Publish()
end

function Model:SetParty(party)
    assert(type(party) == "table" and type(party.members) == "table", "party members required")
    self.party = Contract.Copy(party)
    self:Publish()
end

function Model:OnMatchSnapshot(mode, snapshot)
    if not self.adapter or mode ~= self.mode then return false end
    self.match = self.adapter:BuildState(self.context, snapshot)
    self:Publish()
    return true
end

function Model:GetViewData()
    local canControl = self.party.id == nil or
        (self.party.localPlayerId ~= nil and self.party.localPlayerId == self.party.leaderId)
    return Contract.Copy({
        mode = self.mode,
        party = self.party,
        matchmaking = self.match,
        actions = {
            start = canControl and self.match.canStart,
            cancel = canControl and self.match.canCancel,
        },
    })
end

function Model:Publish()
    self.publish(self:GetViewData())
end

function Model:StartMatch()
    if not self:GetViewData().actions.start then return false, "start unavailable" end
    -- Dispatch is not success. Only an incoming snapshot changes match state.
    return self.adapter:Start(self.context, self.party)
end

function Model:CancelMatch()
    if not self:GetViewData().actions.cancel then return false, "cancel unavailable" end
    return self.adapter:Cancel(self.context, self.party)
end

return Model
