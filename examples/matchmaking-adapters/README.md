# Matchmaking adapters and strategy selection

**Reconstructed example of a later production design, based on my development account.** The class names, symbolic protocol values and service ports here are illustrative. The retained [TeamModel excerpt](../../Content/Lua/GameLogics/Team/TeamModel.lua) shows the earlier, branch-based stage. These files make the later separation executable without presenting newly written code as a recovered production export. [Full evidence scope](../../docs/EVIDENCE.md).

## Why the design changed

Arena and PvE initially fitted a small number of central branches. Later plans included multiplayer horse racing, gliding, shooting contests and fishing competitions. That changed the expected rate and variety of extensions. I separated mode-specific matching into adapters, selected as strategies, while preserving shared party data and the team experience. These planned activities explain the decision; this example does not invent their protocols or claim that every planned mode shipped.

## Follow the framework

1. [Composition](Composition.lua) registers arena and dungeon factories with injected service ports. Registration is the explicit extension point.
2. [AdapterRegistry](AdapterRegistry.lua) chooses a matching implementation by mode and validates its contract. The selected implementation is the model's matchmaking strategy.
3. [ArenaAdapter](adapters/ArenaAdapter.lua) and [DungeonAdapter](adapters/DungeonAdapter.lua) translate incoming snapshots into [MatchContract](MatchContract.lua) data. They also translate `Start` and `Cancel` into service-specific operations. Arena start includes target-ID conversion and solo/party dispatch.
4. [TeamPresentationModel](TeamPresentationModel.lua) combines unchanged party information with the selected adapter's matching state, then publishes one view snapshot. `SetParty` and `OnMatchSnapshot` remain separate inputs; matched participants do not overwrite the pre-existing party.
5. [SharedTeamPresenter](SharedTeamPresenter.lua) renders common state into plain panel/HUD data. An adapter supplies a `details.key` and `details.data` for specialised matching content. The view layer owns widget creation; the adapter owns the meaning of mode-specific data.

## Interface contract

Each adapter implements three operations:

```lua
adapter:BuildState(context, serviceSnapshot) -- common phase + mode-specific details
adapter:Start(context, partySnapshot)       -- dispatch the selected service request
adapter:Cancel(context, partySnapshot)      -- dispatch that service's cancellation
```

The common state carries `phase`, the original `sourceStage`, `matchedMembers`, a view-extension descriptor, and start/cancel availability. Unknown stages map to `unknown`, never to a successful state. The available actions are local presentation policy; backend eligibility and authority are still external.

`Adapter` describes protocol translation. `Strategy` describes using a selected implementation through the same contract. One object fulfils both roles here; a second hierarchy of strategy classes is unnecessary.

## Usage

Add this directory's `?.lua` to Lua's package path, then use the composition function:

```lua
local compose = require("Composition")
local present = require("SharedTeamPresenter")
local model, registry = compose(servicePorts, function(view)
    panel:Apply(present.Panel(view))
    hud:Apply(present.Hud(view))
end)

model:SelectMode("dungeon", { targetId = 42 })
model:SetParty(partySnapshot)
model:OnMatchSnapshot("dungeon", dungeonSnapshot)
model:StartMatch()
```

`servicePorts`, `panel` and `hud` are application-owned dependencies. The tests provide in-memory replacements. The example preserves the division between party state, matching adaptation and presentation; it does not reproduce the entire game's frame lifecycle.

## Adding a mode

The mode's integration engineer defines its input mapping, command routing and specialised detail data in a new adapter, then registers a factory during feature setup. Existing shared views do not gain another protocol branch. A genuinely new player action or new layout can still require a deliberate contract or view extension; this is not a claim of zero-change extensibility.

The test suite registers a **synthetic third mode** to demonstrate this boundary without inventing a racing or fishing protocol.

## Run and interpret the tests

From the repository root, after installing [requirements-test.txt](../../requirements-test.txt):

```sh
python -m unittest discover -s tests -p test_matchmaking_adapters.py -v
```

The checks cover equivalent presentation from different snapshots, distinct details, service routing, party/matched-member separation, unknown and unsupported modes, extension registration, and a shared panel/HUD update. Defensive choices such as snapshot copying, duplicate-registration rejection and waiting for a snapshot after mode selection belong to this reconstruction; no claim is made that the historical implementation had these exact guards.

Different-mode updates are ignored, but that is **not** full asynchronous protection. Same-mode old sessions, out-of-order replies, retries, deadlines, subscriptions, ready-check commands and real widget creation are outside this focused example. A production integration needs its actual identity, lifecycle and protocol contracts.
