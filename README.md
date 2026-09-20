# Multiplayer UI: team controls and contextual in-game feedback

Form a team, match into an activity, request support and follow the right information during play.

**Evan (Yaxin) Ge · Lua / C++ / UMG · ProjectZ**

[中文 README](docs/README.zh-CN.md) · [Screenshots](#gameplay-footage-and-screenshots) · [My work](#my-work) · [Decisions](#three-questions-and-decisions) · [Walkthrough](#deeper-reading)

## Gameplay footage and screenshots

The **Team window** handles invitations, activity selection and matchmaking, followed by the activity's ready check and level entry. The **Compact team notice** keeps that flow accessible when controls are minimised. The separate **Party HUD** shows contextual players during gameplay; its world-boss support button opens the reused **Support browser**.

### Team setup and invitations

![Team window with member slots and an invitation browser.](media/screenshots/Team_MainUI.png)

Players inspect the team, choose an activity and invite others through **Recommended / Friends / Recent / World**. The crown identifies the leader; the current action reads **Waiting to start**. Minimising changes presentation, not team membership or the matching request.

[Team flow and compact notice](docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [Adapter design](docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems)

<a id="2-in-game-party-hud"></a>

### Party HUD: information that follows the gameplay context

![The right-side roster during combat, showing names, levels, health and distance.](media/screenshots/HUD_TeamPanel.png)

The right-side **Party HUD** shows players for the current context: participants in a world-boss area or teammates inside a dungeon. I implemented this panel and its data updates. Later work added switchable combat-statistics views; **this screenshot shows the roster, not statistics mode**.

[Update policies](docs/HUD_PERFORMANCE.md) · [Later combat-statistics design](docs/COMBAT_STATISTICS.md) · [Full-size image](media/screenshots/HUD_TeamPanel.png)

### Support browser: reuse discovery for a different player action

![Support browser with Invite for support actions, availability, favourites and search.](media/screenshots/SupportUI.png)

In a world-boss area, the Party HUD's support button opens the existing player browser with the activity's support context. Players can search or filter candidates and see available, busy or pending feedback. Sending an invitation is distinct from its acceptance.

[Support flow and its entry points](docs/CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context) · [Native-to-UI route](docs/CODE_TOUR.md#4-a-world-interaction--support-ui)

**Additional view:** [Compact team notice](media/SCREENSHOTS.md#compact-team-status-notice), the top-centre activity/status banner. It restores the Team window and is not the right-side Party HUD. [All four stills and footage credits](media/SCREENSHOTS.md).

## My work

I developed and maintained these gameplay features and their associated UI across C++ data/services, Lua behaviour and UMG widgets.

- **Team architecture:** integrated different matchmaking protocols, then separated mode-specific adapters as the multiplayer roadmap expanded.
- **Presentation and lifecycle:** connected the Team window and Compact team notice while keeping gameplay-owned state separate; handled adapter event switching and initial refresh.
- **Contextual support:** reused player discovery with an explicit support ID, player details and availability updates.
- **Party HUD and update policies:** maintained roster membership, combat values and profile details with different freshness requirements and costs.
- **Later combat statistics:** developed server-side accumulation and connected selectively synchronised results to the Party HUD.
- **Cross-layer debugging:** followed a reported team-entry problem into the dungeon's initialization data, alongside ongoing UI maintenance.

## Three questions and decisions

### 1. How can different matching systems provide one consistent experience?

Arena and PvE used different protocols. Central translation in TeamModel was practical with a few modes. Later plans for racing, gliding and other multiplayer activities justified mode-specific adapters: they translate incoming matching data and outgoing commands, while party data and common presentation remain shared.

[Design evolution](docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [Reconstructed Adapter/Strategy example](examples/matchmaking-adapters/README.md)

### 2. How does the UI change modes without owning gameplay state?

Gameplay components/managers own team and matching data; the UI owns its presentation. On an adapter switch, I removed old listeners, registered new ones and immediately read the new mode's current state. That avoids waiting for another event just to show data that already exists.

[State and lifecycle framework](docs/ARCHITECTURE.md#later-matchmaking-adapter-boundary) · [Executable lifecycle example](examples/matchmaking-adapters/TeamPresentationModel.lua)

### 3. Which updates are worth paying for?

I chose update paths from the player's needs, acceptable delay and cost: responsive combat values, slower informational details, fresher invitation details, change-driven roster/support state, and statistics synchronised for the selected display type. Early notification gating and cache work were parts of that continuing evolution, not the whole decision.

[UX and update policies](docs/HUD_PERFORMANCE.md) · [Invitation trade-off](docs/DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility) · [Statistics lifecycle](docs/COMBAT_STATISTICS.md)

## Outcomes

Matching differences gained a defined extension point; minimising controls stayed separate from gameplay commands. The Party HUD could evolve without forcing every kind of data onto one refresh schedule. Later statistics separated accumulation from display, while cross-layer diagnosis corrected a multiplayer entry dependency.

## Deeper reading

For a walkthrough: **feature flow → adapters and lifecycle → update policies → statistics or debugging**.

- [Feature case study](docs/CASE_STUDY.md) · [Architecture](docs/ARCHITECTURE.md) · [Guided code tour](docs/CODE_TOUR.md)
- [Multiplayer entry investigation and additional maintenance](docs/DEBUGGING.md)
- [Tests and their scope](docs/TESTING.md) · [Historical work, reconstructed examples and evidence boundaries](docs/EVIDENCE.md)

Retained excerpts and explicitly labelled reconstructions show framework relationships with implementation details omitted. Tests were added for this portfolio; they are not historical game-performance measurements.

**Related cases:** [Building UI](https://github.com/seak123/building-ui-portfolio) · [Mechanical workers and world-space UI](https://github.com/seak123/mechanical-workers-ui-portfolio).
