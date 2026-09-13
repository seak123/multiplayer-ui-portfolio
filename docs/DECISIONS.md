# Decision rationale: common UI state, different data lifetimes

[Overview](../README.md) · [Case study](CASE_STUDY.md) · [Code tour](CODE_TOUR.md) · [HUD performance](HUD_PERFORMANCE.md)

These decisions come from my work on the feature. Implementation notes identify what the retained code demonstrates and where the account goes beyond the included version.

## 1. One UI-facing model over different matching systems

### Context and problem

The original team experience centred on arena-style matchmaking, including team-versus-team activities. It consumed the arena system's protocol-specific data, such as the current queue and matching stage. PvE dungeons subsequently introduced another protocol, different stage definitions and a different path for matched-team information.

I expected more activity types, not just one additional special case. If each screen interpreted each protocol independently, the panel, compact HUD and confirmation flow could disagree about the same team. Changes to a service would also spread through presentation code.

### My decision

I introduced a common model boundary to translate the different inputs into UI-facing team state and stages. The purpose was to normalise the meaning of the data, not to force the servers to share one protocol or pretend that every activity had the same lifecycle.

Matching and cancellation still needed mode-aware dispatch. A shared view of the current state did not imply a universal backend command. This let the interface remain consistent while the existing arena and dungeon services continued to operate through their own paths.

### What the implementation shows

The role is visible in [TeamModel](../Content/Lua/GameLogics/Team/TeamModel.lua):

- `OnTeamFullDataSync` and `OnMatchedTeamFullDataSync` read the ordinary and matched-team records separately.
- `IsMatching` combines the common team stage with the arena matching manager's current queue.
- `TeamMatchingForInstance` and `TeamMatchingForPVP` adapt their entry conditions before opening the common team interface.
- `TeamMatchReq` and `CancelMatchReq` dispatch to the PvP or team service as appropriate.
- `UpdateTeamFrameViewState` derives the shared HUD state. [TeamTypes](../Content/Lua/GameLogics/Team/TeamTypes.lua) holds common presentation mappings and invitation-source conventions.

This is a pragmatic facade with explicit branches. The views still query some native information directly, and the model still knows about activity types. I would not describe it as complete protocol isolation or a pluggable adapter architecture.

### Contribution and trade-off

The feature could support arena and dungeon team flows through a common presentation vocabulary, providing one place to investigate conflicting stage information. The cost was maintaining translation and dispatch logic in the model as activity types grew. This was an incremental integration within existing systems, not a large-scale rewrite.

The explanation does not assume why the original server architecture was chosen. Its possible ancestry in an older MMORPG design is not needed to justify this decision.

## 2. Immediate feedback is not authoritative eligibility

### Context and problem

Player discovery and player details arrived through separate stages: obtain a set of player IDs, then batch-request richer records for those IDs. The UI could respond quickly using cached details, but those details could become stale while the screen remained open.

For example, a player who had just reached the required level might still appear ineligible in another client's cache. In this workflow, that detail cache was not kept current by a dedicated push for every such change. Repeatedly polling the entire list just to catch a rare eligibility change carried a disproportionate cost.

### The policy I worked on

In a later development iteration in 2025, the interaction policy I worked on was to treat this kind of cache-based eligibility warning as immediate feedback, not a veto on the RPC. The user action should still reach authoritative validation, while a targeted detail request refreshes the specific player being acted on.

That preserves responsiveness and avoids a stale client permanently preventing an otherwise valid invitation. It does **not** mean bypassing server checks, invite cooldowns or other authoritative restrictions.

The compromise was a potentially incorrect immediate warning before the fresh details arrived. I discussed that trade-off with design, and the team accepted it. I would describe it as an accepted UX cost, not as perfectly consistent feedback. Rewording such a warning as provisional would be a possible future improvement, not a historical change claimed here.

### Evidence boundary

The included version verifies the surrounding mechanisms:

- `TeamMatchingMainFrame:ReqPlayersDetails` collects player IDs and submits a batch detail request, including a forced-refresh path.
- `TeamInvitePlayerItem:OnDataSet` reads cached details; `OnTeamMatchingWatchCompleted` updates the displayed record after completion.
- `TeamInvitePlayerItem:OnInvited` sends `Svr_InviteActorReq` when its cooldown permits. The shown handler has no cached-level rejection branch.
- In the separate support flow, `MultiPlayerWorldItem:RefreshAssistGroup` requests fresh details for one player and recalculates that row's availability.

The **warning + non-blocking invitation + targeted refresh on that click** policy comes from my recollection of the later 2025 iteration. The retained excerpts show earlier supporting mechanisms, not that complete later handler. In particular, the support row's targeted request is not proof of a team-invitation click path. The portfolio tests do not claim to validate the later policy.

### Distinguish this from HUD optimisation

This decision concerns interaction-time freshness for a selected player. The [HUD performance case](HUD_PERFORMANCE.md) concerns roster notifications, list binding and periodic detail refresh. They share a data-lifetime problem, but they are different paths and should not be collapsed into one alleged fix.
