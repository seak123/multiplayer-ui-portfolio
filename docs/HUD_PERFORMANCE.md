# UI update policies: balancing player experience and cost

[Overview](../README.md) · [Invitation decision](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility) · [Statistics](COMBAT_STATISTICS.md) · [Model and tests](TESTING.md#hud-work-and-freshness-model)

The Party HUD evolved from regional players to dungeon teammates and later statistics. Invitations and support used related player data for different actions. I developed their update logic around three questions: **what does the player use this for, how much delay is acceptable, and what does keeping it current cost?**

## Different data, different update paths

- **Roster membership:** the DS keeps the large Region data and periodically determines relevant players. Changed membership drives list synchronisation and structural UI updates. In the checked path, a changed list is sent as a current full list; this is not Fast Array or per-row UI diffing.
- **Health and combat information:** preserve responsive updates independently of structural list changes. A changing value should not require rebuilding the roster.
- **Profile details:** a HUD level is mainly informational and can use caching with slower refreshes. In the Team window's invitation tab, the same details can affect an action, so I combined periodic refreshes with targeted invitation-time and response updates.
- **Support:** activity context updates the support entry independently of membership. Player details and request/waiting events update the browser's available actions. Handling received changes promptly does not guarantee instant remote online/offline information.
- **Combat statistics:** the DS keeps accumulating, while the client receives results for its selected display type. A short wait when switching is acceptable; switching does not reset the totals.

The invitation policy also let this kind of stale cached-level warning remain advisory rather than vetoing the RPC. Server validation remained authoritative, and the selected player's details were refreshed. That was an accepted feedback trade-off, not the Party HUD's level-display problem. [Decision and scope](DECISIONS.md#2-immediate-feedback-is-not-authoritative-eligibility).

## One early optimisation behind this policy

An iOS idle-scene report exposed repeated work along:

`RefreshTraceLogic → RefreshTracePlayer → Lua list population → item binding → player-detail query`

The early implementation gated structural notifications with `bTraceDirty` and reused cached details where appropriate. Later maintenance separated support-context updates and revised detail freshness with periodic forced queries and queries on binding. Health/distance retained their separate update path.

The platform report was one discovery point, not the reason every data type needed this policy. Nor were all changes one patch. The broader lesson was to adjust each update responsibility as the feature and player-facing requirements grew.

## What the framework saves

Keeping Region data on the DS avoids that client memory cost. Changed-only list sends and native notification gating act at different boundaries. Gating reduces repeated Lua population and binding; cache/refresh choices control detail-query work; selected statistics limit which results are synchronised.

The retained list still repopulates on a real structural refresh. A detail API call is not necessarily a network packet, and a request interval is not a maximum data-age guarantee. No FPS, CPU-time or bandwidth gains are quantified here.

## Inspectable example

[HudRefreshModel.lua](../examples/hud-refresh/HudRefreshModel.lua) is an independent explanatory model of the early notification, binding, support-overlay and detail-refresh responsibilities. Its tests compare work counts and freshness behaviour; they do not implement the complete invitation policy, statistics system or production replication.

[Verification](TESTING.md) separates these model checks from the retained-function tests and proposed runtime measurements. The later statistics design has its own [short framework overview](COMBAT_STATISTICS.md).
