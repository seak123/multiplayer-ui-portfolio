-- Team-window and compact-notice stand-ins, NOT the separate party roster HUD.
-- No UMG or asset loading is implied.
local Contract = require("MatchContract")
local Presenter = {}
local labels = {
    idle = "Forming a team", searching = "Finding teammates",
    awaiting_confirmation = "Confirm participation", entering = "Entering activity",
    unavailable = "Waiting for activity data", unknown = "Status unavailable",
}

function Presenter.Panel(view)
    return {
        label = labels[view.matchmaking.phase],
        members = Contract.Copy(view.party.members),
        matchedMembers = Contract.Copy(view.matchmaking.matchedMembers),
        actions = Contract.Copy(view.actions),
        -- The view layer resolves the key to a mode-specific widget/presenter.
        -- Adapters supply data; they do not construct widgets.
        detailsKey = view.matchmaking.details.key,
        details = Contract.Copy(view.matchmaking.details.data),
    }
end

function Presenter.Notice(view)
    return { label = labels[view.matchmaking.phase], memberCount = #view.party.members }
end

return Presenter
