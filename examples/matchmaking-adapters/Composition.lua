-- Feature setup selects service ports once; views never select a protocol.
local Registry = require("AdapterRegistry")
local Arena = require("adapters.ArenaAdapter")
local Dungeon = require("adapters.DungeonAdapter")
local Model = require("TeamPresentationModel")

return function(services, publish)
    local registry = Registry.new()
    registry:Register("arena", function() return Arena.new(services.arena) end)
    registry:Register("dungeon", function() return Dungeon.new(services.team) end)
    return Model.new(registry, publish), registry
end
