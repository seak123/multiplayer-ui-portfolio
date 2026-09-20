# Matchmaking adapters, strategy selection and event lifetime

**Reconstructed example of a later production design, based on my development account.** Names, service ports, protocol values and protective checks are illustrative. The retained [TeamModel](../../Content/Lua/GameLogics/Team/TeamModel.lua) shows the earlier branch-based stage. [Evidence scope](../../docs/EVIDENCE.md).

## Framework

Party information remains shared. Mode-specific adapters translate matching snapshots and commands; selecting an implementation through the common contract is the Strategy role.

1. [Composition](Composition.lua) registers factories in [AdapterRegistry](AdapterRegistry.lua).
2. [ArenaAdapter](adapters/ArenaAdapter.lua) and [DungeonAdapter](adapters/DungeonAdapter.lua) translate their services into [MatchContract](MatchContract.lua).
3. [TeamPresentationModel](TeamPresentationModel.lua) combines independent party and matching snapshots.
4. [SharedTeamPresenter](SharedTeamPresenter.lua) supplies the **Team window** and **Compact team notice**, not the separate Party HUD roster. Specialised matching detail keys/data are left for the view layer.

More planned modes justified this boundary after central branches had served the smaller feature. The example does not invent racing/fishing protocols or imply that every planned activity shipped.

## Adapter interface

```lua
adapter:BuildState(context, snapshot)
adapter:Start(context, party)
adapter:Cancel(context, party)
adapter:RegisterEvents(context, changed)
adapter:UnregisterEvents()
adapter:ReadSnapshot(context)
```

Incoming data and outgoing commands remain mode-specific. Each injected service port also exposes `Subscribe(targetId, changed)`, returning an unsubscribe function, and `GetSnapshot(targetId)`, reading its current local state. Reading is not a new network request or a transfer of data ownership.

## Switching and first display

`SelectMode` resolves the next adapter, unregisters the old events, registers the new events and immediately reads the current snapshot. An existing snapshot is displayed without waiting for a new broadcast; later events trigger another read. `Dispose` releases the subscription.

The example adds an adapter-identity guard for a queued old listener. This guard is illustrative; the historical behaviour confirmed here is the unsubscribe/subscribe/initial-refresh sequence. It is not an atomic snapshot-and-subscribe protocol or protection against every same-mode out-of-order service response.

## Usage

```lua
local Presenter = require("SharedTeamPresenter")
local model = require("Composition")(servicePorts, function(view)
    panel:Apply(Presenter.Panel(view))
    notice:Apply(Presenter.Notice(view))
end)
model:SetParty(partySnapshot)
model:SelectMode("dungeon", { targetId = 42 })
-- Mode events now refresh the view from the service's current snapshot.
-- Disposing the feature releases its mode subscription.
model:Dispose()
```

Add this directory's `?.lua` to the package path. The application provides the service ports and views. Minimising a window is not feature disposal or cancellation of matching.

## Verification and extension

The [tests](../../tests/test_matchmaking_adapters.py) cover protocol mapping, commands, party/matching separation, mode extension and subscription lifetime. A synthetic third mode demonstrates registration without changing the shared model.

Run `python -m unittest discover -s tests -p test_matchmaking_adapters.py -v` from the repository root after installing its test dependencies.

These are local reconstruction tests. Real framework event scheduling, ready-check commands, service sessions, UI loading and backend behaviour remain outside this example. [Full verification scope](../../docs/TESTING.md).
