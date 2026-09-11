# External dependencies and widget contracts

This is a source-reading portfolio. It deliberately does not contain a `.uproject`, engine build, production services or binary UI content. Dropping these files into a stock Unreal project will not produce the game.

## Reading omitted interfaces

An out-of-scope Lua function keeps its signature and a short `-- Implementation omitted.` comment. This preserves readable call relationships without including unrelated functionality. These placeholders are not working implementations: running them directly would do nothing. The focused test loader replaces the marker with a failure in memory, so a test cannot pass by silently relying on omitted behaviour. The source files themselves remain uncluttered.

The C++ `.h` files are interface outlines, **not** the original complete class declarations. Their selected method signatures match the `.cpp` excerpts. Native base classes, reflection metadata, generated includes and dependent type definitions are external. The source is not claimed to compile here.

## Shared Lua runtime contract

- `ModelManager:CreateModel(name)` / `GetModel(name)`: feature-model registration and lookup. Model lifecycle and event setup remain in the project runtime.
- `CreateUIBehaviour`, `CreateUIBehaviourFromListItem`, `CreateUIBehaviourFromListView`: bind feature classes to the shared native-widget/behaviour lifecycle.
- `__BehaviourManager:GetBehaviour(uniqueId)`: resolve a native widget to its Lua behaviour.
- `UIUtil.AddUniqueFrameAsync(path, callback)`: asynchronously obtain a unique frame for the asset path. Availability, close/hide and cancellation semantics require the real frame manager.
- `UIUtil.SetImagePathAsync(widget, path, ...)`: framework-managed asset assignment with stale-path/lifetime handling.
- `EventSystem.Fire(name, ...)`: project event dispatcher. Subscription ownership comes from models and behaviour settings, not from this standalone repository.
- `DataObjectPool:Get(luaTable)`: bridge Lua records into the native list API. List entry/release callbacks belong to the shared runtime.
- `GScope` and `Timer`: scoped timer/event facilities. Do not infer that hiding a widget necessarily destroys its subscriptions.

## Gameplay and service contract

- `PzTeamFunctionLibrary.GetTeamManager(context)` returns the existing native team manager. `GetTeamData()` and `GetMatchedData()` expose snapshots with IDs, target and a native `Member` array (`Num()` / zero-based `Get()`).
- `Svr_*` team functions forward player intent through the team's RPC component. UI button availability is feedback, not a replacement for server validation.
- `PzMultiPlayerLibrary.GetMultiPlayerManager(context)` provides recommendation and invitation services. `RequestAssistPlayer(roleId, assistId)` dispatches the request and manages pending/cooldown state; `IsAssistPlayerValid(roleId)` only checks that manager's pending map in the shown implementation. It does **not** by itself prove full gameplay eligibility.
- `OtherPlayerModel.OnPlayerAttrReq(ids, callback, ...)` requests richer detail data; `GetPlayerAttrInCache(id)` reads a cached record. Cache-completion timing, coalescing and cancellation are not reimplemented here.
- `PlayWorldData` / `PlayWorldNet` provide world/player lists, favourites, history and search requests. The support path selects this existing infrastructure rather than a new service.
- Configuration tables supply target categories, activity titles, support requirements and presentation keys. `LocalizationFText` / `FText` resolve localised strings; no full localisation database is exported.
- Other mode, chat, relationship, achievements and social systems remain external. Their names in an excerpt describe integrations, not included implementations.

## UMG binding contract

Binary widget assets are omitted. The Lua `setting` / `PanelSetting` tables provide the precise widget and handler names expected by the code. The following reading guide groups their responsibilities; it does not invent the original visual arrangement.

### Team main frame

Asset reference: `UI/Panel/Ranks/WBP_Rank_Invite_Frame`.

`UITabItem_1..4` choose invitation sources. `InviteList` holds candidate players through native list data objects. `TeamMemberItem_1..4` display the party. `MatchingPlayerBtn`, `StartTargetBtn`, `LeaveTeamBtn` and `CloseBtn` express distinct intents. Target/difficulty/reward widgets exist but some of their feature-specific bodies are omitted.

### Team notice / HUD

Asset reference: `UI/Panel/Ranks/WBP_Rank_HUD_Matching`.

`NoticeText` describes the activity; `StateTxt` and `StateImg` reflect the derived HUD state. `NoticeBtn` restores controls. `CloseBtn` has an explicit confirmation-based handler, although initial visibility is controlled in code. `TimeTxt` displays matching time; animation functions live on the native blueprint widget.

### Matching confirmation

Asset reference: `UI/Panel/Ranks/WBP_Rank_MatchingSuccessful`.

`TeamMemberItem_1..4`, `ConfirmInfo`, `Time` and `ConfirmBtn` express confirmation progress. The frame reads a deadline derived from `MatchingConfirmTimeStamp`; leave/dismiss events close the confirmation flow.

### Multiplayer parent, list and item

The parent frame is `UI/Panel/MultiPlayer/WBP_MPlayer_Frame`. It composes `UIWorldListPanel`, a content switcher, tabs and a loading group. The list panel owns search/tab controls and its child list. Items are backed by `WBP_MPlayer_WorldItem` and bind player identity and action groups.

The support item's `UIReqAssistSwitcher` uses the original numeric indices: `0` available action, `1` waiting/pending, `2` existing support robot, `3` busy-map restriction, `4` offline fallback. These meanings are inferred from the assigning code; actual appearance/copy requires the omitted widget asset or gameplay footage. An index is not a server state enum.

## Test doubles are separate

The fake services in `tests/` exist only to execute chosen Lua methods. They do not provide game connectivity, visual UMG behaviour or substitutes for missing production modules. Expected failures and untested lifetime assumptions are recorded in [TESTING.md](TESTING.md).
