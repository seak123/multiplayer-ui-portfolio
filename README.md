# Multiplayer UI: from finding teammates to playing together

A connected multiplayer experience: form a team, invite support, minimise the controls and keep track of teammates during gameplay.

**Evan (Yaxin) Ge · Lua / C++ / UMG · ProjectZ**

[中文 README](docs/README.zh-CN.md) · [Feature screenshots](#gameplay-footage-and-screenshots) · [My work](#my-work) · [Decisions](#three-questions-and-decisions) · [Code and tests](#deeper-reading)

## Gameplay footage and screenshots

Three views show the menu, combat HUD and support-discovery parts of the feature. [All four screenshots, English labels and footage credits](media/SCREENSHOTS.md).

### Team setup and invitations

![Team setup with three occupied member slots, an empty slot and an invitation browser on the right.](media/screenshots/Team_MainUI.png)

**What the player does:** inspect the team and activity, find players through **Recommended / Friends / Recent / World**, and invite them. The crown marks the leader; the displayed action is **Waiting to start**. The feature allows the panel to be minimised while the team remains active.

**Work behind this view:** common team presentation across arena/PvE data, role-dependent controls, invitation details, and shared state between the full panel and compact notice.

[Feature: team panel to HUD and back](docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore) · [Decision: one UI-facing model](docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [Code: panel actions](docs/CODE_TOUR.md#2-full-panel--player-intent)

<a id="2-in-game-party-hud"></a>

### In-game party HUD: readable team information during combat

![Combat with a compact member roster on the right showing levels, names, health bars and distance.](media/screenshots/HUD_TeamPanel.png)

**What the player sees:** the **member list on the right** keeps levels, names, health and distance visible without reopening team controls. [Open full-size image to inspect the roster](media/screenshots/HUD_TeamPanel.png).

**Work behind this view:** I implemented this party HUD and maintained its data updates. Membership changes, live combat information and richer player profiles use different refresh responsibilities, avoiding unnecessary full-list work while retaining explicit detail-refresh opportunities.

[Performance case: follow the refresh-cost chain](docs/HUD_PERFORMANCE.md) · [Code-reading route](docs/CODE_TOUR.md#7-hud-performance-read-the-cost-chain-then-run-the-model)

### Support discovery and availability

![Multiplayer browser with Invite for support actions, a Busy row, favourites, filters and search.](media/screenshots/SupportUI.png)

**What the player does:** find another player to help with an activity using favourites, filters, refresh and search. Available rows offer **Invite for support**; a currently unavailable row reads **Busy**.

**Work behind this view:** carry the activity's support ID into an existing browser, bind player details and availability, and route invitation requests and pending/cooldown state through the native manager.

[Feature: contextual support](docs/CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context) · [Code: world interaction to support UI](docs/CODE_TOUR.md#4-a-world-interaction--support-ui) · [Debugging: callback and availability fixes](docs/DEBUGGING.md)

**Additional view — [compact team-status notice: screenshot and explanation](media/SCREENSHOTS.md#compact-team-status-notice).** The top-centre banner shows the activity and **Forming a team** state, and provides a route back to controls. It is separate from the right-side party roster. [Restore and exit logic](docs/CODE_TOUR.md#3-compact-status--restore-or-explicit-exit).

## My work

I developed and maintained team and support gameplay with its associated UI, including the main-panel integration, compact team-status notice, right-side party HUD and follow-up fixes. The work connected Lua/UMG views to C++ systems and multiplayer services.

- **Team-state integration and evolution:** adapted arena and PvE matching data into common UI-facing state, then separated mode-specific matching into adapters as the multiplayer roadmap expanded. Shared party data and the panel/HUD flow stayed common; mode selection chose the matching strategy.
- **Panel and compact HUD:** connected member and role information, readiness/matching presentation, and minimise/restore behaviour; separated hiding controls from commands such as leaving or cancelling.
- **Invitations and support:** integrated player discovery with activity context, player details and offline/busy/pending feedback, preserving the intended support action through to native dispatch.
- **Party HUD:** implemented the in-game member roster and maintained the different update paths for roster membership, combat values and player details.
- **Logic-layer performance:** followed repeated native notifications through Lua list population, binding and detail requests; gated structural refreshes and separated support-context updates, then revised detail freshness as the feature evolved.
- **Debugging and ongoing maintenance:** removed a support-search request/callback cycle, corrected availability refreshes, and worked through the trade-off between immediate cached feedback and server-authoritative eligibility.

## Three questions and decisions

### 1. How can different matching systems present one coherent team state?

Arena and PvE matching used different protocols, stages and team records. I first centralised state translation and service dispatch in a common UI-facing model. With few modes, explicit branches were manageable.

Later plans for multiplayer horse racing, gliding, shooting contests and fishing competitions changed that trade-off. I split matching into mode-specific adapters, selected as strategies: incoming data became shared presentation state, outgoing actions used the correct service, and specialised matching details remained available to the view. The common party model and panel/HUD experience did not need a separate protocol implementation for each mode.

[Two-stage design decision](docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [Reconstructed later-design example and tests](examples/matchmaking-adapters/README.md) · [Panel and HUD flow](docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore).

### 2. How can support reuse player discovery without losing its purpose?

I carried the activity's support context into the existing multiplayer browser, reusing search, lists and player details. Row actions retain the support ID and distinguish offline, busy and pending players; the native manager maintains invitation waiting and cooldown state.

The same discovery UI can therefore support a different player intent without treating a sent request as an accepted invitation. [Support flow](docs/CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context).

### 3. Which data needs refreshing, and when?

An iOS performance issue led me through native roster notifications, Lua list repopulation, item binding and detail queries. I gated structural notifications with a dirty flag and separated support-context updates from member-list refreshes.

Profile data needed a different policy: cache-permitted binding reduced repeated work, while later level-display maintenance restored explicit freshness through periodic forced queries and queries on binding. I treated roster structure, live combat values and richer player details as different update responsibilities. [HUD optimisation and maintenance](docs/HUD_PERFORMANCE.md).

## Outcomes

- Arena and PvE flows use a common presentation vocabulary while retaining their existing service paths.
- The later adapter boundary concentrates mode-specific mapping and commands in a defined extension point, rather than continually expanding the shared model's matching branches.
- Players can minimise team controls, keep playing with status feedback, and return to the current team state.
- Stable membership avoids repeated structural refresh propagation; support-context changes have a narrower update path, and player details retain explicit refresh opportunities.
- A support-search callback cycle was removed so completing a detail request no longer starts the same request again. [Debugging case](docs/DEBUGGING.md).

## Deeper reading

- **Feature and architecture:** [Case study](docs/CASE_STUDY.md) · [Architecture](docs/ARCHITECTURE.md) · [Decision rationale](docs/DECISIONS.md).
- **Implementation:** [Guided code tour](docs/CODE_TOUR.md) · [TeamModel](Content/Lua/GameLogics/Team/TeamModel.lua).
- **Architecture evolution:** [Later Adapter/Strategy framework — reconstructed example](examples/matchmaking-adapters/README.md), including shared model, concrete adapters, mode registration and executable tests.
- **Reliability and cost:** [Callback and availability fixes](docs/DEBUGGING.md) · [HUD performance](docs/HUD_PERFORMANCE.md).
- **Additional trade-off:** [Cached eligibility, immediate feedback and server authority](docs/DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility).
- **Verification:** [Focused tests — added for this portfolio](docs/TESTING.md) · [Independent HUD demonstration model — not production code](examples/hud-refresh/HudRefreshModel.lua).
- **Evidence scope:** [Historical work, version boundaries, tests and footage](docs/EVIDENCE.md).

**Related cases:** [Building UI](https://github.com/seak123/building-ui-portfolio) · [Mechanical workers and world-space UI](https://github.com/seak123/mechanical-workers-ui-portfolio).
