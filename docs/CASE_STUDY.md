# Case study — one feature across menus, HUD and native systems

[Back to overview](../README.md)

## Context and responsibility

ProjectZ is a multiplayer game built on a modified Unreal codebase. Players need to find teammates, choose activities, prepare, match and request help without losing awareness of the world around them. The work crossed existing C++ gameplay services, Lua interface logic and UMG widgets.

I developed and maintained the gameplay features and their associated interfaces across those layers. This included team/support integration, compact team status and the right-side party HUD shown in the gallery. Follow-up work addressed support-search behaviour and stale player availability, using the team's existing multiplayer services and shared UI framework.

The four decisions connect that responsibility to concrete behaviour: keep shared state across views; reuse discovery with an explicit support context; separate data requests from presentation refresh; and control roster-refresh work without losing data freshness.

## The problem was the flow, not just the screen

Several facts determine what the player should see:

- Whether a team exists, who leads it and which activity it targets.
- Whether I am ready, whether others are ready, and whether matching is active.
- Whether the full panel is open and whether the current map should show team status.
- Whether a recommended support player is online, already invited or busy elsewhere.
- Whether list data and richer player details have arrived at different times.

A single button label cannot be updated correctly in isolation from these facts. Likewise, closing a menu must not accidentally mean “leave the team”. The implementation separates presentation changes from explicit multiplayer commands.

## Flow A: create a team, minimise, restore

`TeamMatchingForInstance(targetId)` uses the existing native team API to create or change the activity target, or restores the panel for an existing team. Native data-sync events update `TeamModel`. The full panel draws members, readiness and available actions from that state.

For a leader, controls cover matching, starting the target and prompting unready members. For a member, the same region becomes ready / cancel-ready or a matching-related action. The target and role therefore matter together; controls are not simply enabled by whether the team contains players.

`UpdateTeamFrameViewState` also derives a compact `HUDState`: unready, ready, matching or all-ready. It coordinates whether a notice should be available when the full panel is absent. **Matching can keep a notice alongside the panel**, so the implementation is not a strict one-view-at-a-time toggle.

The notice displays a localised activity/state label, an asynchronously loaded image and an animation choice from shared configuration. Its click handler restores the team panel. Its explicit exit action offers confirmation and calls the appropriate cancel/leave command. The player's presentation choice and their multiplayer intent remain separate.

### Why this decision mattered

The delivered behaviour preserves continuity: players can return to gameplay while retaining status and a route back to controls. Common state derivation gives engineers a focal point when the compact notice and full view disagree. The trade-off is that each view still handles mode-specific presentation, so shared model state alone does not remove the need to test both views.

## Flow B: request support from a gameplay context

A native NPC interaction calls `ExecuteNpcFunc_Implementation`. After validating the actor, it emits `OnRequestOpenAssistPanel` with an `AssistId`. `MultiPlayerModel` retains that context, consults support configuration and opens the existing multiplayer panel in support mode.

The parent panel passes `bFromAssist` into the world/player-list flow. The list panel chooses the appropriate data request. The list converts service records into item view data; each item chooses between normal world interaction controls and support controls.

Clicking an eligible support action eventually calls:

`RequestAssistPlayer(OwnerRID, AssistId)` → native manager → multiplayer component request.

The manager owns the per-player invitation timer and emits `OnInviteAssistRefresh` after inserting or clearing pending entries. Items read that status rather than maintaining independent authoritative invitation timers. Pending invitation feedback remains distinct from acceptance.

### Reuse with a visible cost

Reusing browsing, player information and list presentation avoided building another full social interface. The cost is `bFromAssist` and related context branching across several layers. It is a reasonable incremental integration, but not free abstraction. If more action contexts accumulated, I would propose a small typed action/context policy rather than adding more loosely related booleans. That is a **future design proposal**, not a historical refactor claimed here.

## Working within the team's authoring workflow

The existing framework let UMG authoring and Lua behaviour remain connected by named widgets, element bindings and child behaviours. This matters in cross-discipline work: designers need to iterate on flow and rules; UI artists need to author layout, animation and feedback; engineers need stable bindings and clear state ownership.

I used these facilities in feature delivery and discussed UI solutions with the team. The implementation makes the cross-discipline contract concrete: what remains visible after minimising, which actions are role-dependent, how waiting and unavailable states differ, and which events update the view. Designers can iterate on the flow, UI artists on the presentation, and engineers on the state and command boundaries without replacing the authoring workflow.

## Maintenance after delivery

The support-search freeze was especially instructive. The pre-fix file contained two definitions of the same completion handler. Lua uses the later definition. That effective handler could call the refresh function, which submitted another detail request and fired the same completion event. Removing only code in the earlier definition would not fix the effective runtime path.

The historical change removed the duplicate/re-entrant path and left a completion handler that updated state without requesting the same data again. The [debugging chapter](DEBUGGING.md) traces the exact functions and explains what a controlled before/after test proves.

Other maintenance changes routed invitation refresh back through the complete availability calculation and updated lists after player details arrived. These reinforce the same design rule: update the meaningful player state, not just whichever button happened to change last.

## HUD optimisation and the cost of stale data

The in-game roster introduced a different problem from the support-search callback cycle. A native tracked-player refresh emitted a Lua notification on every tick; the receiving HUD cleared and repopulated its list, and item binding entered the detail-query path. An iOS idle-scene performance issue made this repeated work relevant even when roster membership was stable.

I introduced dirty-gated membership notifications and refined duplicate-add handling. Support-context changes later gained a narrower overlay update path. Neither change removed all ticking or turned the list into a per-row diff system.

Detail freshness required a separate decision. Binding initially moved to cache-permitted queries; later level-display maintenance added a periodic forced refresh and eventually restored forced queries on binding. These changes show an evolving policy, not a claim that every later bug had the same root cause. Health and distance remained separate from structural updates.

The [dedicated performance chapter](HUD_PERFORMANCE.md) connects the cost chain, implementation changes and remaining boundaries. Its independently written model provides work-count and freshness checks without presenting synthetic results as measured game performance.

## Outcome

The work delivered team controls, compact status and contextual support on top of existing gameplay services. Players could minimise and restore the team interface, use discovery tools for support, and receive state-dependent invitation feedback. Maintenance removed the demonstrated request/completion cycle and restored complete availability refresh for affected rows. Roster work also gained notification gating, while subsequent detail-query changes addressed level freshness rather than treating reduced request frequency as the only goal.

These are observable behavioural outcomes. The [screenshots](../README.md#gameplay-footage-and-screenshots) show the interfaces; the [debugging chapter](DEBUGGING.md) and [tests](TESTING.md) make the implementation and regression boundaries inspectable. Measurement and runtime limits are recorded in the verification chapter.
