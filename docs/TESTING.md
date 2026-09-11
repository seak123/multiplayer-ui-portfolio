# Verification and remaining validation

Second-edition verification on 11 September 2026: **17 tests run — 16 passed, 1 expected failure** documenting the cache-miss assumption below. The suite includes the 64-case team presentation matrix. No unexpected failures remained. This is a local test result, not CI, in-engine or device validation.

## Run the focused tests

Python 3.12 and the pinned Lua runtime bridge are sufficient; the game and Unreal Engine are not required for these tests.

```sh
python -m venv .venv
# Activate the virtual environment using your platform's usual command.
python -m pip install -r requirements-test.txt
python -m unittest discover -s tests -v
```

The test doubles have no network or game-service connection. `runtime.lua` supplies native queries, widget setters, event delivery and a queued attribute callback service. Tests execute retained Lua functions, not a newly written state reducer claimed to be the original implementation.

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

## Expected failure is intentional

`test_known_cache_miss_assumption_for_online_item` documents that the exported `RefreshAssistState` assumes a cached detail record on an online path. The test removes that record. The current excerpt cannot safely handle this input. It is not silently modified just to make a green test report.

This does not prove a production crash is reachable: the real caller/cache contract may guarantee a record. It does identify an explicit contract to confirm, or a guard to add in a production fix. An unexpected success should trigger a review of the recorded limitation and expected outcome.

## What is not covered

No Unreal build, real UMG rendering, native C++ execution, network/backend interaction, cross-platform timing, accessibility validation, console navigation or measured performance work was performed by this harness. The repository is not advertised as a runnable game or a complete automated integration suite.

## In-editor / device regression plan

1. **Role and command transitions:** leader/member ready and unready, member departure, leader change, invitation acceptance/rejection, matching cancellation, confirmation timeout. Check both labels and the actual command sent.
2. **Presentation continuity:** minimise and restore repeatedly; change map/activity; receive a state update while the panel is closed. Verify that reopening does not replay stale state or abandon the ongoing activity.
3. **Async lifetime:** close before frame load completes, replace the support context before completion, recycle a row while its player details/image are loading. Check validity **and identity/context**, not only a non-null widget.
4. **Search ordering:** rapid typing, empty query, explicit search, tab switching and out-of-order responses. Debounce alone is not an ordering guarantee.
5. **State fidelity:** offline, busy, pending, accepted/expired invitations, favourites/detail-data arriving later; include several rows to detect global-event side effects.
6. **Authoring and presentation:** missing/renamed widget binding, longer localised strings, changing culture with the HUD visible, animation state, DPI/aspect ratios and the actual supported input devices.
7. **Costs:** under an identical list/interaction workload, measure callback count, request count, allocations/data handles, native list entry count, and UI CPU work. Report these separately rather than inferring FPS from an avoided request.

These are proposed regression checks, not a claim that every item was historically executed or that the feature already passes all of them.
