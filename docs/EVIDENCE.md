# Evidence and implementation scope

[Portfolio overview](../README.md) · [Code tour](CODE_TOUR.md) · [Verification](TESTING.md)

## Historical work and code

This case describes specific past ProjectZ work, using the development account and checked implementation relationships. Selected implementations preserve module paths and calls; omitted bodies are marked and native headers include interface outlines. The full Unreal runtime, services and binary widgets are external. [Dependencies](DEPENDENCIES.md) · [Implementation map](source-manifest.json).

The retained common team model is the earlier incremental facade with mode-aware branches. The subsequent adapter refactor is a later stage, documented separately below. The roster work gates notifications; it does not remove the native tick or replace list population with a per-row diff.

## Later maintenance account

I subsequently split the matching integration into mode-specific adapters selected through a common strategy contract. Plans for multiplayer horse racing, gliding, shooting contests and fishing competitions prompted this change after central branches had served the smaller set of modes. This development account establishes the later design; the retained earlier excerpt does not contain that refactor. The named activities are planning context, not a statement that all of them shipped.

The [matchmaking adapter framework](../examples/matchmaking-adapters/README.md) is newly written explanatory code reconstructing that separation. Its class names, service ports, protocol values, detail keys and defensive checks are illustrative, not exact later production interfaces. Its tests validate the reconstruction only. Existing `Content/` excerpts and their implementation-map checksums are unchanged. No original project history or new proprietary implementation bodies were added for this reconstruction.

The 2025 policy of a non-blocking cached-eligibility warning plus targeted refresh comes from my account of that later iteration. The included version shows supporting mechanisms, not the complete later click handler. The [decision chapter](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility) separates the retained request paths from that account and explains the accepted UX trade-off.

## Verification and performance

Focused tests were added for this portfolio. They execute selected Lua excerpts with controlled services, including a before/after callback-loop check. The suite also records a cache-miss assumption as an expected failure. [Test results and coverage](TESTING.md).

The [independent HUD demonstration model](../examples/hud-refresh/HudRefreshModel.lua) is new explanatory code, not a production export. Its counters measure model notifications, bindings and detail-API calls, not UMG execution time or network packets. Tests of this model do not establish historical device, renderer, allocation, bandwidth or FPS results.

The [HUD performance chapter](HUD_PERFORMANCE.md) distinguishes the implemented refresh changes, later freshness maintenance and proposed runtime measurements.

## Visual material

The [footage guide](../media/SCREENSHOTS.md) records creator credits and English label translations. Screenshots preserve the original watermarks and illustrate separate states rather than a continuous click-through or measured optimisation results. Team formation in the compact banner is distinct from active matchmaking; the party roster is a separate view.

Game visuals and project material remain subject to their respective rights.

## Lifecycle, statistics and cross-layer diagnosis

The later adapter account includes unregistering the previous mode, registering the selected mode and immediately reading its current state. The reconstruction now demonstrates this through synchronous in-memory event ports. Its identity guard and exact method names are illustrative; it does not establish full production race protection.

Later combat statistics are described from my development account: the DS Manager calculates and retains totals, the component synchronises selected results, and the Party HUD displays them. The earlier excerpts, roster model and screenshots do not contain or demonstrate that complete later system.

The multiplayer-entry investigation combines the checked floor-initialization/lookup changes with my recollection of QA state capture, critical-value logs and successful/failing comparisons. That account establishes the three-plus-one composition and incorrect solo-player team context, with correct protocol timing. The relevant fix is not exported or exercised by this portfolio harness; backend details and historical regression results are not added.

These accounts extend the feature background without publishing raw project history, diagnostic logs or private interview-preparation material.
