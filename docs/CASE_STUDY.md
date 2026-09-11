# Case study — one feature across menus, HUD and native systems

[Back to overview](../README.md)

## Context and responsibility

ProjectZ is a multiplayer game built on a modified Unreal codebase. Players need to find teammates, choose activities, prepare, match and request help without losing awareness of the world around them. The work crossed existing C++ gameplay services, Lua interface logic and UMG widgets.

My contribution was feature implementation and maintenance across those layers. The work connected contextual support interactions and a minimised team HUD. Later changes addressed support-search behaviour and stale player-availability presentation. These were extensions within an existing multiplayer and UI architecture, not a greenfield UI framework.

## The problem was the flow, not just the screen

Several facts determine what the player should see:

- Whether a team exists, who leads it and which activity it targets.
- Whether I am ready, whether others are ready, and whether matching is active.
- Whether the full panel is open and whether the current map should show team status.
- Whether a recommended support player is online, already invited or busy elsewhere.
- Whether list data and richer player details have arrived at different times.

A single button label cannot be updated correctly in isolation from these facts. Likewise, closing a menu must not accidentally mean “leave the team”. The implementation separates presentation changes from explicit multiplayer commands.

## Flow A — create a team, minimise, restore

`TeamMatchingForInstance(targetId)` uses the existing native team API to create or change the activity target, or restores the panel for an existing team. Native data-sync events update `TeamModel`. The full panel draws members, readiness and available actions from that state.

For a leader, controls cover matching, starting the target and prompting unready members. For a member, the same region becomes ready / cancel-ready or a matching-related action. The target and role therefore matter together; controls are not simply enabled by whether the team contains players.

`UpdateTeamFrameViewState` also derives a compact `HUDState`: unready, ready, matching or all-ready. It coordinates whether a notice should be available when the full panel is absent. **Matching can keep a notice alongside the panel**, so the implementation is not a strict one-view-at-a-time toggle.

The notice displays a localised activity/state label, an asynchronously loaded image and an animation choice from shared configuration. Its click handler restores the team panel. Its explicit exit action offers confirmation and calls the appropriate cancel/leave command. The player's presentation choice and their multiplayer intent remain separate.

### Why this decision mattered

The value is continuity: players can return to gameplay while retaining status and a route back to the controls. Keeping common state derivation in the model also gives engineers a focal point when the HUD and full view disagree. The views still contain mode-specific presentation logic; this is a practical model-view design, not a claim of perfectly pure MVVM.

## Flow B — request support from a gameplay context

A native NPC interaction calls `ExecuteNpcFunc_Implementation`. After validating the actor, it emits `OnRequestOpenAssistPanel` with an `AssistId`. `MultiPlayerModel` retains that context, consults support configuration and opens the existing multiplayer panel in support mode.

The parent panel passes `bFromAssist` into the world/player-list flow. The list panel chooses the appropriate data request. The list converts service records into item view data; each item chooses between normal world interaction controls and support controls.

Clicking an eligible support action eventually calls:

`RequestAssistPlayer(OwnerRID, AssistId)` → native manager → multiplayer component request.

The manager owns the per-player invitation timer and emits `OnInviteAssistRefresh` after inserting or clearing pending entries. Items read that status rather than maintaining independent authoritative invitation timers. An RPC request is not treated as proof that the other player accepted.

### Reuse with a visible cost

Reusing browsing, player information and list presentation avoided building another full social interface. The cost is `bFromAssist` and related context branching across several layers. It is a reasonable incremental integration, but not free abstraction. If more action contexts accumulated, I would propose a small typed action/context policy rather than adding more loosely related booleans. That is a **future design proposal**, not a historical refactor claimed here.

## Working within the team's authoring workflow

The existing framework let UMG authoring and Lua behaviour remain connected by named widgets, element bindings and child behaviours. This matters in cross-discipline work: designers need to iterate on flow and rules; UI artists need to author layout, animation and feedback; engineers need stable bindings and clear state ownership.

I used these existing facilities in feature delivery and discussed UI solutions with the team. A useful review conversation is concrete: what should remain visible after minimising; what does “waiting” mean; which player action needs confirmation; which event changes a control; and what should the interface display while detail data is missing? Those questions connect user flow to an implementable contract within the existing authoring workflow.

## Maintenance after delivery

The support-search freeze was especially instructive. The pre-fix file contained two definitions of the same completion handler. Lua uses the later definition. That effective handler could call the refresh function, which submitted another detail request and fired the same completion event. Removing only code in the earlier definition would not fix the effective runtime path.

The historical change removed the duplicate/re-entrant path and left a completion handler that updated state without requesting the same data again. The [debugging chapter](DEBUGGING.md) traces the exact functions and explains what a controlled before/after test proves.

Other maintenance changes routed invitation refresh back through the complete availability calculation and updated lists after player details arrived. These reinforce the same design rule: update the meaningful player state, not just whichever button happened to change last.

## Outcome and limits

The implementation connected team controls, compact status and contextual support to existing gameplay services while keeping the existing UI authoring workflow. The case documents the implementation and its maintenance through selected code and work records. No measured conversion-rate, frame-time or bug-count improvement is reported.

The strongest evidence here is inspectable behaviour: role-dependent controls, shared status derivation, contextual reuse, native request ownership and a concrete feedback-loop fix. The [four gameplay screenshots](../README.md#gameplay-footage-and-screenshots) now provide visual context for team setup, the party HUD, support selection and the compact team-status notice. They do not demonstrate transition timing or a continuous user flow.
