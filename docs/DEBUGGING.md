# Debugging across the team-to-gameplay boundary

[Overview](../README.md) · [Feature flow](CASE_STUDY.md) · [Tests and scope](TESTING.md)

## Multiplayer entry: correct synchronisation, wrong team context

QA reported an intermittent empty dungeon after players skipped match confirmation and queued again. The first suspicion was the team request flow. I had implemented the dungeon as well, so I followed the report into its gameplay initialization after level resources finished loading.

Multiplayer initialization needed the team's target to resolve the floor. The failing composition was a pre-formed group of three matched with one solo player. Initialization queried the solo player's TeamComponent, but the solo party was a client-side abstraction: the DS had no equivalent real-team target in that context.

The bug-report state exposed the wrong target. I compared successful and failing histories of the critical value, including assignments, reasons and its source. **The team protocol had synchronized correctly and the timing was right; the wrong data context was being queried.**

I corrected the floor-initialization and lookup path and coordinated with the server team about the temporary matched-team data needed for entry. The fix addressed a data dependency, not a delay before spawning.

This is a cross-layer investigation originating in a team-flow report, not a UI-rendering defect or a proven network race. The framework lesson is to check both when data arrives and which object the downstream system reads.

The relevant TeamComponent/GameState floor changes are described here without exporting their implementation. This repository's tests do not reproduce the dungeon or validate the backend fix.

## Additional UI maintenance

These smaller cases remain useful code-reading examples, rather than the main walkthrough story.

### Support search: request and completion formed a cycle

A duplicate Lua completion-handler definition made the effective path less obvious. Updating a row requested details; the active completion handler could refresh the row and request them again. The fix removed the repeated request and duplicate handler, leaving completion to read cached details and update presentation.

The focused [before](../tests/fixtures/assist_refresh_before.lua) and [after](../tests/fixtures/assist_refresh_after.lua) fixtures demonstrate this cycle. A bounded callback-drain test shows the post-fix path terminates; it is not an original device profile.

### Availability needs the complete set of conditions

After inviting an online player, offline rows could incorrectly show invitation buttons. Replacing a pending-only update with `RefreshAssistState` restored the offline/busy/waiting checks. This was a logic-correctness fix, not a rendering optimisation.

### Detail arrival is separate from opening a tab

The favourites flow gained its completion event and active-tab refresh. Opening the tab once did not guarantee that its asynchronously arriving details were already available.

## Remaining validation boundaries

- The retained online-row path assumes a detail record exists; a cache-miss test intentionally records an expected failure.
- Recycled rows and late callbacks need identity/lifetime checks; frame uniqueness alone is not cancellation.
- Search debounce limits submissions, not response ordering.
- Additional readiness, reconnect and multiplayer-entry scenarios need the actual runtime.

These are validation targets, not extra historical fixes. [Verification](TESTING.md) documents what the local tests actually execute.
