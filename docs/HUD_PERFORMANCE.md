# HUD performance: refresh granularity and data freshness

[Overview](../README.md) · [中文 README](README.zh-CN.md) · [Executable model](../examples/hud-refresh/HudRefreshModel.lua) · [Tests](../tests/test_hud_refresh.py)

**The engineering problem:** a small party roster can trigger substantial repeated work if its update signal is too broad. Reducing that work must not leave the player looking at stale information.

This is the in-game member roster shown on the right of the [combat screenshot](../README.md#2-in-game-party-hud), not the compact matchmaking notice. It extends the existing team case with my HUD optimisation and subsequent maintenance work.

## Context: unnecessary work while the player was standing still

An iOS idle-scene performance report pointed to the native team's tracked-player refresh path. Standing still does not stop health, distance or other players from changing, but an unchanged membership list should not require repeated structural refreshes.

The important boundary was between **who belongs in the roster**, **what those members are doing**, and **when their richer profile information becomes stale**. Those are different reasons to update the UI.

## Following the cost through the layers

The relevant path was:

`UPzTeamManager::RefreshTraceLogic` → `RefreshTracePlayer` event → `DungeonHUDTeamArea:RefreshTracePlayer` → list data population → `DungeonHUDTeamItem:OnDataSet` → player-detail query.

Before the change, the native refresh path emitted the Lua event unconditionally on each tick. Its recipient cleared the list's items, constructed role-ID data, acquired data-bridge objects and added the items again. Binding an item also entered the player-detail request path.

Looking only at the size of the widget or the cost of one event would miss the repeated downstream work. ListView can reuse widget entries, and the project has a data-object pool, but neither makes repeated data population and binding free. Likewise, entering the detail API is not proof of a separate network packet: the existing service queues and combines requests.

This explains the optimisation target without inventing a historical profiler capture or timing breakdown.

## Change 1: gate membership notifications

I introduced a `bTraceDirty` flag and gated `RefreshTracePlayer` on it, clearing the flag before dispatch. A subsequent refinement marked an addition dirty only when the member was actually inserted. Repeatedly ensuring that an already tracked player was present no longer had to notify the entire list.

This was **notification gating**, not removal of the native tick, a per-row diff algorithm, or a blanket reduction of every HUD update rate. When a roster refresh did occur, the existing clear-and-repopulate path remained.

There were also conservative edges: the removal branch could mark dirty whenever its tracking-reason group existed, even if that particular member was absent. Bulk removal and full-sync paths need their own invalidation audit. I would not describe this as a perfect change-detection system.

## Change 2: give support availability its own update path

Nearby activity context can change whether a support action should be shown without changing roster membership. A follow-up correctness fix compared the current support ID with the stored ID and emitted `RegionAssistIDUpdated` when it changed. The Lua handler refreshed the support overlay directly.

That separated an overlay-only update from a full member-list refresh. The member-list refresh still refreshed the overlay too; this was an incremental separation, not a wholesale view-model rewrite. Its original trigger was incorrect support-button availability, while its architectural value was a narrower update responsibility.

## Change 3: revise the cache policy when freshness matters

The work did not stop at adding a dirty flag. My changes evolved through three stages:

1. **Initial optimisation:** item binding changed from a forced detail query to a cache-permitted query. This reduced pressure on the detail-refresh path when data was already available; a cache miss could still require a request.
2. **Later level-display maintenance:** a level-zero issue led to a separate two-second forced-detail refresh and removal of the level assignment from the frequent brief-data update. Health and distance still used the brief-data path.
3. **Further level-mismatch maintenance:** binding was changed back to a forced detail query, with an immediate presentation refresh as well. The later implementation therefore does **not** use cache-only binding.

These were separate maintenance changes, not proof that the initial cache change caused every later level bug. Together, they show why an optimisation policy needs to be revisited against the meaning and freshness of the displayed data.

The result was not “cache everything” or “refresh everything every frame”. Structural updates were gated; changing combat information retained a separate refresh path; richer details regained explicit refresh opportunities. The two-second timer is a request cadence, not a guarantee that the displayed data is never more than two seconds old—service latency and failures still matter.

## What this work demonstrates

I reduced avoidable refresh propagation across C++, Lua and list binding, then adjusted detail-query policy when player-facing correctness required it. The useful distinction is **unnecessary repetition versus necessary freshness**, not simply fewer calls at any cost.

The implementation changes support that account. They do not establish a numerical FPS, CPU-time, allocation or bandwidth improvement. This is logic-layer UI performance work, not a claim of engine-renderer optimisation.

## Inspectable model and regression checks

The [Lua model](../examples/hud-refresh/HudRefreshModel.lua) was written specifically for this portfolio. It represents the notification boundary, list-binding work and detail policies in one small, runnable example; it is **not copied production code or a replacement for the native manager**. The existing extracted code elsewhere in the repository is unchanged.

The [tests](../tests/test_hud_refresh.py) cover:

- repeated ticks with a stable roster: unconditional dispatch versus gated dispatch;
- batching additions into one notification and avoiding duplicate-add notifications;
- removal, including the conservative no-op removal behaviour;
- a support-context update without rebuilding the roster;
- health/distance changes without a structural refresh;
- stale cached details, a forced query on binding, and a periodic forced refresh;
- a cache miss and a detail refresh that leaves roster structure untouched.

The counters measure **model events, bindings and detail-API calls**, not UMG execution time, native allocations or network traffic. The detail service is an in-memory synchronous test double; real callback scheduling, deduplication, failure handling and row recycling are outside this model.

## What I would measure in the running game

Use the same roster size, scene and device for stable-roster and changing-roster workloads. Count native-to-Lua notifications, list repopulations, item bindings, detail-API calls, and actual dispatched service requests separately. Then correlate them with game-thread UI time and allocation activity.

Validate joining/leaving, region changes, level changes, cache misses, reopening the HUD, bulk clear/full sync, delayed replies and recycled entries. Retain responsive health/distance feedback while checking when profile details become correct. These are proposed runtime checks, not historical measurements supplied by this portfolio.

The next design step would be to audit every membership mutation, make data freshness requirements explicit, and consider batched detail refreshes with lifecycle-safe completion. Those are improvement proposals, not additional shipped work claimed here.
