-- Reconstructed portfolio example, not an export of the later production code.
-- Names and protocol values are illustrative. See README.md in this directory.
local Contract = {}

-- Snapshots in this example contain only acyclic data tables, not engine objects.
function Contract.Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Contract.Copy(item) end
    return result
end

function Contract.State(phase, sourceStage, detailsKey, details, matchedMembers)
    return {
        phase = phase,
        sourceStage = sourceStage,
        details = { key = detailsKey, data = Contract.Copy(details or {}) },
        matchedMembers = Contract.Copy(matchedMembers or {}),
        canStart = phase == "idle",
        canCancel = phase == "searching",
    }
end

function Contract.Unavailable()
    return Contract.State("unavailable", nil, nil)
end

function Contract.ValidateAdapter(adapter)
    assert(type(adapter) == "table", "adapter must be a table")
    for _, method in ipairs({ "BuildState", "Start", "Cancel" }) do
        assert(type(adapter[method]) == "function", "adapter missing " .. method)
    end
    return adapter
end

return Contract
