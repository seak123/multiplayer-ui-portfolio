-- Strategy selection: the shared model asks for a mode, not a protocol branch.
local Contract = require("MatchContract")
local Registry = {}
Registry.__index = Registry

function Registry.new()
    return setmetatable({ factories = {} }, Registry)
end

function Registry:Register(mode, factory)
    assert(type(mode) == "string" and mode ~= "", "mode must be named")
    assert(type(factory) == "function", "adapter factory required")
    assert(not self.factories[mode], "mode already registered: " .. mode)
    self.factories[mode] = factory
end

function Registry:Create(mode)
    local factory = assert(self.factories[mode], "unsupported mode: " .. tostring(mode))
    return Contract.ValidateAdapter(factory())
end

return Registry
