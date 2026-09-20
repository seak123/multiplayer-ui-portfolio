# Later extension: combat statistics in the Party HUD

[Overview](../README.md) · [Update policies](HUD_PERFORMANCE.md) · [Architecture](ARCHITECTURE.md)

I later developed a combat-statistics system and added its display modes to the existing Party HUD. Players could inspect damage dealt or taken without making the UI responsible for accumulating the results.

## Data ownership and events

1. **Register scope:** when statistics are needed, such as entering an area, the player registers their RID, the target/scope and the other player RIDs to include with a Manager on the dedicated server.
2. **Accumulate:** damage events update totals held by that DS Manager, starting from registration or reset.
3. **Synchronise:** the player's component carries the results needed for the selected display type to the client; it does not independently calculate the final totals.
4. **Present:** the Party HUD consumes those results. For the same roster, switching statistics types retains the items while awaiting the new values.

## Three operations that must stay distinct

**Switching display type** changes the results being synchronised, not the accumulation period. The Manager continues calculating; the small display delay was acceptable.

**Resetting** changes the accumulation starting point, manually or through a gameplay trigger such as entering a dungeon or region.

**Reconnecting** can recover the record still held on the DS. This is not a claim of persistence across server restarts or migration.

This separation let an existing HUD gain a new data view while keeping gameplay accumulation independent of the window and connection lifetime.

## Presentation scope

This is a concise account of later development work. The retained earlier excerpts and HUD model do not contain this full implementation. The gallery shows the roster, not the later statistics screen; no statistics screenshot or reconstructed production API is implied. See [evidence scope](EVIDENCE.md).
