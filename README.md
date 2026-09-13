# Multiplayer UI: from finding teammates to playing together

**Evan (Yaxin) Ge · Lua / C++ / UMG · Past ProjectZ development work**

Team setup, invitations, readiness, matching and support requests form one connected player experience across menus and gameplay. The challenge was keeping several views aligned with live multiplayer state.

I developed and maintained gameplay features and their associated UI, including team/support integration, compact status and follow-up fixes. I also implemented the right-side party HUD shown below. The work used the team's shared Lua/UMG framework and existing multiplayer services.

[中文 README](docs/README.zh-CN.md) · [Case study](docs/CASE_STUDY.md) · [Decisions](docs/DECISIONS.md) · [Code tour](docs/CODE_TOUR.md) · [Architecture](docs/ARCHITECTURE.md) · [Visuals](media/SCREENSHOTS.md) · [Verification](docs/TESTING.md)

## How to read this case

This is a retrospective of specific work on ProjectZ, not a proposal for a new feature. The account follows actual implementation behaviour and verified interface relationships. Selected code excerpts retain module paths and calling relationships; omitted bodies and shortened interface outlines are labelled.

Separately written reference models and tests are supporting material, not original game code or historical validation results. Documentation is in English, with one Chinese README. The [decision rationale](docs/DECISIONS.md) combines my account of the work with the implementation boundaries visible in the code.

## Four engineering decisions

**1. Adapt different matching systems into one UI-facing model.**

The feature grew from arena matchmaking into PvE teams with different protocols and stage definitions. I worked on a common model boundary so views could use consistent team state while requests still reached the appropriate service. `TeamModel` retains explicit mode branches; it is an incremental integration, not a replacement backend. The full panel and compact HUD then derive their presentation from this shared state. [Reasoning and code](docs/DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems) · [Team flow](docs/CASE_STUDY.md#flow-a-create-a-team-minimise-restore).

**2. Reuse player discovery, but preserve the meaning of the action.**

A world interaction carries an `AssistId` into the existing multiplayer browser. Lists and search are reused; support actions retain their context and distinguish offline, busy and pending players. Invitation state belongs to the native manager, not individual rows. The trade-off is context branching across layers. [Support flow](docs/CASE_STUDY.md#flow-b-request-support-from-a-gameplay-context).

**3. Diagnose UI failures through the complete data path.**

A support-search freeze involved a detail request whose completion triggered another request. A duplicate Lua method definition hid the effective callback. The historical fix removed that cycle; the included before/after test demonstrates terminating refresh behaviour. [Fix and regression evidence](docs/DEBUGGING.md).

**4. Reduce redundant roster work without sacrificing data freshness.**

An iOS performance issue exposed repeated native-to-Lua roster refreshes, list repopulation and detail queries. I gated membership notifications and separated support-context updates. Detail-query policy then evolved: cache-permitted binding reduced repeat work, but later level-display problems required periodic forced refreshes and forced queries on binding. The lesson is to distinguish structural changes from live values and profile freshness—not simply refresh everything less often. [Optimisation, trade-offs and executable checks](docs/HUD_PERFORMANCE.md).

Together, these decisions connect player-facing continuity, practical reuse, asynchronous correctness and logic-layer UI performance.

A related [data-freshness decision](docs/DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility) explains the tension between immediate client feedback and cached player eligibility. It distinguishes my account of the later interaction policy from the request paths retained in this export.

## The player experience

```mermaid
flowchart TB
    A["Choose activity<br/>or request help"] --> B[Find and invite players]
    B --> C["Team readiness<br/>and matching"]
    C --> D["Minimise to HUD<br/>and keep playing"]
    D -->|Restore controls| C
    C --> F["Confirm / enter<br/>activity"]
```

Team formation and support are related entry points. They use existing services rather than one universal backend state machine.

## Gameplay footage and screenshots

Four separate examples from public Bilibili gameplay footage, with English captions. Original images and creator watermarks are preserved. [Source notes and label translations](media/SCREENSHOTS.md).

### 1. Team setup and invitations

![Team setup with three occupied member slots, one empty slot and an invitation list on the right.](media/screenshots/Team_MainUI.png)

The panel brings together the activity, current members and invitations. The crown identifies the leader; **Recommended / Friends / Recent / World** select invitation sources. The bottom button reads **Waiting to start**. **Minimise** returns to gameplay without leaving the team.

### 2. In-game party HUD

![Combat screenshot with the party roster on the right, showing member levels, names, health bars and distances.](media/screenshots/HUD_TeamPanel.png)

**Focus on the member list on the right, which I implemented.** Levels, names, health and distance remain visible during combat without opening the team panel. Open the image at full size to inspect the roster.

The [HUD performance case](docs/HUD_PERFORMANCE.md) explains how membership refreshes and detail freshness were handled behind this interface. The still shows the UI, not measured optimisation results.

### 3. Finding players for support

![Multiplayer player browser showing Invite for support buttons, a Busy player, favourites, filters and search.](media/screenshots/SupportUI.png)

Available rows offer **Invite for support**; an unavailable player is labelled **Busy**. Favourites, filters, refresh and search support discovery. My work connected this support context and availability feedback to the native invitation path.

### 4. Compact team-status notice

![Gameplay screenshot with a blue activity and team-status notice at the top centre.](media/screenshots/TeamHUD.png)

**Focus on the blue banner at the top centre.** It displays the activity and **Forming a team** status (组队中). This notice is distinct from the party roster; its implementation provides a route back to team controls. The displayed state is team formation, not evidence that matchmaking is active.

## Read the code in ten minutes

1. [TeamModel](Content/Lua/GameLogics/Team/TeamModel.lua): shared presentation state and open/hide/restore.
2. [Main frame](Content/Lua/GameLogics/Team/TeamMatching/TeamMatchingMainFrame.lua) and [compact notice](Content/Lua/GameLogics/Team/TeamMatching/TeamMatchingNotice.lua): role-dependent controls, commands and feedback.
3. [Multiplayer model](Content/Lua/GameLogics/MultiPlayer/MultiPlayerModel.lua) → [list panel](Content/Lua/GameLogics/MultiPlayer/MultiPlayerWorldListPanel.lua) → [player item](Content/Lua/GameLogics/MultiPlayer/MultiPlayerWorldItem.lua): support context, requests and availability.
4. [Native support manager](Source/ProjectZ/GameLogic/MultiPlayer/PzMultiPlayerManager.cpp): invitation dispatch and pending/cooldown ownership.
5. [Debugging](docs/DEBUGGING.md): historical callback fix, later maintenance and remaining validation targets.
6. [HUD performance](docs/HUD_PERFORMANCE.md): native notification granularity, list-binding costs and the evolution of detail freshness. An independently written [Lua model](examples/hud-refresh/HudRefreshModel.lua) makes the trade-offs testable.

## Scope and verification

Selected implementations preserve module paths and calling relationships. Omitted bodies are labelled; C++ headers are interface outlines. The full Unreal runtime, services and binary widgets are external. [Dependencies and widget contracts](docs/DEPENDENCIES.md) · [Implementation map](docs/source-manifest.json).

Focused tests execute Lua excerpts with controlled services, including the before/after callback case. Additional tests exercise the independently written HUD refresh model; model counters are not device-performance measurements. The suite records an existing cache-miss assumption and does not claim device, renderer or shipping-performance validation. [Results and limitations](docs/TESTING.md). Screenshots illustrate separate states, not a continuous click-through. Game visuals and project material remain subject to their respective rights.

**Related cases:** [Building & interactable UI](https://github.com/seak123/building-ui-portfolio) · [Mechanical workers, world-space UI & authoring](https://github.com/seak123/mechanical-workers-ui-portfolio).
