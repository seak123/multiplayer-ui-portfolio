# Guided code tour

[Overview](../README.md) · [Architecture](ARCHITECTURE.md) · [Widget contracts](DEPENDENCIES.md)

The paths preserve the split between native source and Lua content. Follow a complete flow first, then inspect individual methods. `-- Implementation omitted.` marks an out-of-scope body, not working game behaviour. The test harness rejects calls into these placeholders.

For the two-stage evolution from central arena/PvE branches to mode-specific adapters, read [the adaptation decision](DECISIONS.md#1-one-ui-facing-model-over-different-matching-systems). Sections 1–6 below follow the earlier retained code. The later framework has a separate reconstructed reading route at the end; it is not silently inserted into the earlier excerpt.

## 1. Shared state → two presentations

Start at [TeamModel.lua](../Content/Lua/GameLogics/Team/TeamModel.lua).

- `OnTeamFullDataSync` reads native IDs/target, updates presentation and requests richer player details.
- `IsMatching` combines local team stage with the native matching manager's active queue.
- `UpdateTeamFrameViewState` derives `HUDState`, then coordinates the panel/notice against map visibility and current team state.
- `OpenTeamMatchingFrame` resolves an asynchronously created frame to its Lua behaviour and initialises it.
- `HideTeamMatchingFrame` and `RecoverTeamPanel` change presentation; they do not substitute for a leave/cancel service request.

[TeamTypes.lua](../Content/Lua/GameLogics/Team/TeamTypes.lua) contains the state/config mapping and invitation-source adapters. This keeps common state presentation data together while allowing each view to handle its own layout.

## 2. Full panel → player intent

In [TeamMatchingMainFrame.lua](../Content/Lua/GameLogics/Team/TeamMatching/TeamMatchingMainFrame.lua):

- `InitFrameContent` configures invitation sources and initial content.
- `UpdateInviteList` converts the active source's entries into native list data via `DataObjectPool:Get`.
- `UpdateFrameContent` reads native team members and role; `UpdateFrameBtns` chooses available actions and text.
- `OnMatchingPlayer`, `OnStartTarget` and `OnLeavingTeam` distinguish matching, ready state, leader actions and explicit exit intent.
- `OnCloseFrame` minimises the ordinary team flow, with a special non-matching single-player PvP branch.

The [invitation row](../Content/Lua/GameLogics/Team/TeamMatching/TeamInvitePlayerItem.lua) maps player identity and native invite cooldown to per-row controls. The [member row](../Content/Lua/GameLogics/Team/TeamMatching/TeamMemberItem.lua) displays member/leader/readiness/confirmation state. These are distinct row roles, not one generic item with every responsibility.

## 3. Compact status → restore or explicit exit

In [TeamMatchingNotice.lua](../Content/Lua/GameLogics/Team/TeamMatching/TeamMatchingNotice.lua), inspect `UpdateState`, `OnClickNoticeBtn` and `OnClose`. `OnMatchNoticeTimerUpdate` formats elapsed native matching time; it does not maintain a separate elapsed counter.

[MatchingPrepareFrame.lua](../Content/Lua/GameLogics/Team/TeamMatching/MatchingPrepareFrame.lua) covers the confirmation stage, member agreement count and deadline. `OnTeamBCDismiss` / `OnTeamBCLeave` close that flow. Do not infer an entire server-side matching algorithm from this view code.

## 4. A world interaction → support UI

[PzBossAssistCallFuncObject.cpp](../Source/ProjectZ/GameLogic/BossAltar/NpcFunc/PzBossAssistCallFuncObject.cpp) emits `OnRequestOpenAssistPanel` with the configured `AssistId`.

In [MultiPlayerModel.lua](../Content/Lua/GameLogics/MultiPlayer/MultiPlayerModel.lua), `OnRequestOpenAssistPanel` calls `RequestAssist`, which reads support configuration and opens the multiplayer parent in support mode.

[MultiPlayerPanel.lua](../Content/Lua/GameLogics/MultiPlayer/MultiPlayerPanel.lua) keeps this context in `bFromAssist`. `OnMyShowPanel` and `ShowTab` connect it to the player-list child.

## 5. Query → list data → action state

[MultiPlayerWorldListPanel.lua](../Content/Lua/GameLogics/MultiPlayer/MultiPlayerWorldListPanel.lua): `UpdateDataByReqServer` / `ReqServerData` choose normal browsing versus support recommendations. Search, loading and response handlers live here. Inspect `OnInputTextChanged` for the later scoped debounce, as part of the shared browsing implementation.

[MultiPlayerWorldList.lua](../Content/Lua/GameLogics/MultiPlayer/MultiPlayerWorldList.lua): `CreatePlayerWorldItemData` constructs view data; `FillWorldList` maps records and uses the existing list API. It also groups signature/tag queries. Performance gains are not quantified in this case.

[MultiPlayerWorldItem.lua](../Content/Lua/GameLogics/MultiPlayer/MultiPlayerWorldItem.lua): `RefreshAssistGroup` selects the support presentation and requests details; `RefreshAssistState` chooses the individual action state; `OnRequestAssist` dispatches intent. `OnInviteAssistRefresh` recalculates state following a native notification. See [DEBUGGING.md](DEBUGGING.md) before assuming every asynchronous edge case is protected.

## 6. Lua → native service boundary

[PzTeamFunctionLibrary.cpp](../Source/ProjectZ/GameLogic/Team/PzTeamFunctionLibrary.cpp) preserves the thin team command/query bridge. [PzTeamManager.cpp](../Source/ProjectZ/GameLogic/Team/PzTeamManager.cpp) shows selected data/readiness queries and the urge-ready cooldown.

[PzMultiPlayerManager.cpp](../Source/ProjectZ/GameLogic/MultiPlayer/PzMultiPlayerManager.cpp) shows support request dispatch, per-player pending timers, expiration and refresh notification. Inspect `IsAssistPlayerValid`: in this code it means “not present in the pending map”, not “all server gameplay rules have passed”.

The adjacent headers keep selected signatures readable. They are explicitly labelled outlines; original engine types and generated service dependencies are external.

## 7. HUD performance: read the cost chain, then run the model

[HUD_PERFORMANCE.md](HUD_PERFORMANCE.md) follows the tracked-player notification into roster data population, item binding and detail queries. The production method names there are navigation context; the full HUD implementation is not included in this export.

The independently written [HudRefreshModel.lua](../examples/hud-refresh/HudRefreshModel.lua) gives a small executable counterpart:

- `add_member` / `remove_member` / `tick`: dirty notification gating, including the deliberately conservative removal branch.
- `refresh_roster` / `request_detail`: count list rebinding and detail-API work separately; no inference about widget creation or packet counts.
- `set_assist_id` / `refresh_overlay`: support-only updates.
- `refresh_vitals`: changing row values without rebuilding membership.
- `advance_detail_clock`: a deterministic test scheduler for periodic forced details, not the engine's widget-timer implementation.

[test_hud_refresh.py](../tests/test_hud_refresh.py) compares unconditional and gated notifications, then tests stale-cache and forced-refresh behaviour. These are model tests, separate from the retained-function tests used for the support callback fix.

## 8. Implementation map and validation

[source-manifest.json](source-manifest.json) maps the existing code excerpts to included methods and omitted bodies. Its checksums validate those displayed files only; no project revision identifiers are published. The independently written `examples/` models are not source excerpts and are not part of that map. [TESTING.md](TESTING.md) explains which methods execute in the focused harness and what still needs the actual game/editor.

## 9. Later adapter framework

Start at the [reconstruction entry point](../examples/matchmaking-adapters/README.md), then follow:

1. [Composition](../examples/matchmaking-adapters/Composition.lua) registers concrete factories and native-service stand-ins.
2. [AdapterRegistry](../examples/matchmaking-adapters/AdapterRegistry.lua) resolves a mode to a validated matching strategy.
3. [TeamPresentationModel](../examples/matchmaking-adapters/TeamPresentationModel.lua) maintains party state independently, delegates matching translation/commands and publishes a shared view snapshot.
4. [ArenaAdapter](../examples/matchmaking-adapters/adapters/ArenaAdapter.lua) and [DungeonAdapter](../examples/matchmaking-adapters/adapters/DungeonAdapter.lua) implement the same contract with different incoming fields and outgoing service operations.
5. [SharedTeamPresenter](../examples/matchmaking-adapters/SharedTeamPresenter.lua) consumes common state for panel/HUD and exposes mode-specific detail data for the view layer.
6. [Adapter tests](../tests/test_matchmaking_adapters.py) exercise both routes and register a synthetic third mode without changing the shared model.

These are concrete interfaces for discussing the later refactor, not recovered later production source. The named competitions remain roadmap context, not fabricated protocol implementations.
