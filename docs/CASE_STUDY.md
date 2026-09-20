# Case study — connected flows, separate responsibilities

[Overview](../README.md) · [Architecture](ARCHITECTURE.md) · [Decisions](DECISIONS.md)

## Context and responsibility

I developed and maintained team/support gameplay and its UI across C++ data and services, Lua behaviour and UMG widgets. The feature grew from arena matching to PvE and later multiplayer plans, while the Party HUD expanded from regional players to teammates and statistics.

The key boundaries are **gameplay state versus window state**, **party data versus matching data**, and **display needs versus accumulation and synchronisation**.

## Flow A: create a team, minimise, restore

Players form a team, invite others and choose an activity. An explicit request joins the appropriate matching queue; a successful match leads to the mode's ready-confirmation flow and then level entry.

The Team window and Compact team notice describe the same team/matching flow. Minimising or restoring controls is a presentation choice, not a leave/cancel command. The retained earlier code can show the matching notice alongside the window, so this is not a strict one-view-only toggle.

Gameplay modules own team and mode-specific matching data. The later adapter design connects those sources to common presentation: unregister old events, register the selected mode's events, then read its current state. Later broadcasts keep the view updated.

[Earlier panel/notice code](CODE_TOUR.md#1-shared-state--two-presentations) · [Later adapter example](../examples/matchmaking-adapters/README.md)

## Flow B: request support from a gameplay context

The separate Party HUD prioritises players for the current world-boss area or dungeon. In the boss context, its support button opens the Support browser with the region's support ID.

The checked HUD handler, `DungeonHUDTeamArea:OnReqAssist`, emits `OnRequestOpenAssistPanel`. The included NPC interaction is another entry into that same event. Both retain the activity context rather than opening a generic list without a purpose.

`MultiPlayerModel` opens the existing multiplayer browser in support mode. The browser reuses discovery, search and player details; a row dispatches the selected player and support ID to the native manager. Pending/cooldown feedback remains distinct from acceptance.

[Included native entry and shared browser](CODE_TOUR.md#4-a-world-interaction--support-ui)

## Flow C: follow gameplay without reopening the Team window

The Party HUD is not the minimised Team window. Its roster follows gameplay context, while combat values, player details and support availability have separate update needs. Later, the same HUD gained damage-dealt/taken views backed by server-held statistics.

[UX and refresh policy](HUD_PERFORMANCE.md) · [Statistics ownership and lifecycle](COMBAT_STATISTICS.md)

## Framework and maintenance

I used the existing UMG/Lua authoring framework for widget binding, events and lists, without replacing the team's layout and animation workflow. Different protocols, data lifetimes and player actions were handled at the feature boundary.

A reported team-entry problem also required following the flow beyond UI: dungeon initialization queried a solo player's server-side team context that lacked the target, despite correct protocol synchronization. [Cross-layer investigation](DEBUGGING.md).

The delivered interfaces, later framework decisions and selected implementation relationships are the focus here. The [code tour](CODE_TOUR.md) leads to retained excerpts and labelled reconstructions; [evidence scope](EVIDENCE.md) collects the version and verification boundaries.
