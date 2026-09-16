# Verification and remaining validation

Reverified on 16 September 2026: **44 tests run — 43 passed, 1 expected failure** documenting the cache-miss assumption below. The suite includes the 64-case team presentation matrix, 11 HUD work/freshness model tests and 16 matchmaking-adapter reconstruction tests. No unexpected failures remained. This is a local test result, not CI, in-engine or device validation.

## Run the focused tests

Python 3.12 and the pinned Lua runtime bridge are sufficient; the game and Unreal Engine are not required for these tests.

```sh
python -m venv .venv
# Activate the virtual environment using your platform's usual command.
python -m pip install -r requirements-test.txt
python -m unittest discover -s tests -v
```

The test doubles have no network or game-service connection. For `test_portfolio.py`, `runtime.lua` supplies native queries, widget setters, event delivery and a queued attribute callback service; these tests execute retained Lua functions. Separately, `test_hud_refresh.py` runs an independently written explanatory model with a synchronous in-memory detail service. That model is not claimed to be the original implementation.

## What is covered

- Parse every included Lua file without executing game services.
- Check displayed-file checksums against the implementation map; these are not project revision identifiers.
- Verify that the implementation map contains only paths, method lists, omitted-body information and displayed-file checksums.
- Verify that the test loader rejects an omitted body. Short source comments are replaced with failures in memory during tests, not written back to the code.
- Check local Markdown file links.
- Exercise 64 role/readiness/team/matching combinations in `UpdateTeamFrameViewState`.
- Exercise notice/full-panel coordination and clearing views on map/no-team conditions. Frame open/remove methods are instrumented: real async frame creation is **not** tested.
- Verify the native matching signal is considered.
- Demonstrate the pre-fix historical support callback cycle with a bounded drain; verify that the post-fix path drains and preserves busy-player feedback.
- Exercise current support offline, busy, pending, available and robot paths, including an invitation refresh on an offline row.
- Record the current online-item cache-miss assumption as one expected failure.

## HUD work and freshness model

The [performance chapter](HUD_PERFORMANCE.md) explains the historical implementation decisions. Its [model](../examples/hud-refresh/HudRefreshModel.lua) has 11 checks in [test_hud_refresh.py](../tests/test_hud_refresh.py):

- Stable-roster ticks: compare unconditional and dirty-gated notifications and their downstream list-binding/detail-API work.
- Coalesce additions before the next dispatch; do not notify again for duplicate additions.
- Refresh on removal; retain the conservative no-op removal case instead of inventing perfect invalidation.
- Update support context without rebuilding members; update health/distance independently.
- Demonstrate stale cache-permitted binding, a forced binding query, a cache miss and periodic forced details without structural rebinding.

Run just this portion with `python -m unittest discover -s tests -p test_hud_refresh.py -v`.

The stable-roster fixture uses a fixed synthetic tick count. Its event and binding counts are deterministic checks, **not a benchmark, measured speedup or network saving**. Detail timing is represented by a separate test clock; real per-widget timer phase, callback scheduling, service request coalescing, network errors, multiple tracking-reason groups and recycled-row lifetime are not simulated. The tests do not prove that every production clear/full-sync path invalidates correctly.

## Matchmaking adapter reconstruction

The [later design example](../examples/matchmaking-adapters/README.md) has 16 checks in [test_matchmaking_adapters.py](../tests/test_matchmaking_adapters.py). They exercise different protocol snapshots producing a common state, retained mode-specific details, separate party/matched participants, arena target conversion and solo/party commands, dungeon service routing, cancellation, and shared panel/HUD presentation.

They also check that request dispatch alone does not imply a state transition, unsupported modes and unknown stages do not silently become valid flows, snapshots do not alias the model, and a synthetic third mode can be registered without changing shared model code. The role guard and defensive checks belong to this new example. Same-mode stale sessions, real subscriptions, service timing and UMG widget creation are outside its coverage.

Run only these checks with `python -m unittest discover -s tests -p test_matchmaking_adapters.py -v`. These are tests of the reconstruction, not a claim that the later production refactor used these exact classes or had this historical test coverage.

## Expected failure is intentional

`test_known_cache_miss_assumption_for_online_item` documents that the exported `RefreshAssistState` assumes a cached detail record on an online path. The test removes that record. The current excerpt cannot safely handle this input. It is not silently modified just to make a green test report.

This does not prove a production crash is reachable: the real caller/cache contract may guarantee a record. It does identify an explicit contract to confirm, or a guard to add in a production fix. An unexpected success should trigger a review of the recorded limitation and expected outcome.

## What is not covered

No Unreal build, real UMG rendering, native C++ execution, network/backend interaction, cross-platform timing, accessibility validation, console navigation or measured game-performance work was performed by this harness. The repository is not advertised as a runnable game or a complete automated integration suite.

## In-editor / device regression plan

1. **Role and command transitions:** leader/member ready and unready, member departure, leader change, invitation acceptance/rejection, matching cancellation, confirmation timeout. Check both labels and the actual command sent.
2. **Presentation continuity:** minimise and restore repeatedly; change map/activity; receive a state update while the panel is closed. Verify that reopening does not replay stale state or abandon the ongoing activity.
3. **Async lifetime:** close before frame load completes, replace the support context before completion, recycle a row while its player details/image are loading. Check validity **and identity/context**, not only a non-null widget.
4. **Search ordering:** rapid typing, empty query, explicit search, tab switching and out-of-order responses. Debounce alone is not an ordering guarantee.
5. **State fidelity:** offline, busy, pending, accepted/expired invitations, favourites/detail-data arriving later; include several rows to detect global-event side effects.
6. **Authoring and presentation:** missing/renamed widget binding, longer localised strings, changing culture with the HUD visible, animation state, DPI/aspect ratios and the actual supported input devices.
7. **Costs:** under an identical list/interaction workload, measure callback count, request count, allocations/data handles, native list entry count, and UI CPU work. Report these separately rather than inferring FPS from an avoided request.
8. **Roster invalidation and freshness:** unchanged members, duplicate additions, removals, bulk clear/full sync, level changes, cache misses and delayed replies. Verify support-only updates do not require rebuilding the roster, and that necessary detail refreshes do not compromise health/distance responsiveness. Distinguish API calls from actual dispatched requests.

These are proposed regression checks, not a claim that every item was historically executed or that the feature already passes all of them.
