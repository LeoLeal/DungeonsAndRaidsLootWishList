## Why

The tracker row suffix currently mixes remembered best-looted item level and item-track text into the row label, which makes the row harder to interpret and pushes too much variant/history detail into the compact tracker surface. The cleaner UX is to let the row communicate only item identity and possession state, while tooltip behavior carries the richer item detail when the player hovers a row.

Once that suffix is removed, persisting `bestLootedItemLevel` no longer serves a clear user-facing purpose in the tracker experience. Keeping it would preserve complexity in saved state and loot-update behavior without a corresponding UX payoff.

## What Changes

- Remove the best-looted item-level and item-track suffix from tracker item rows.
- Keep the green possession tick as the primary tracker-row signal for owned or completed wishlist items.
- Change tracker tooltip compare behavior so possessed items show only the possessed tooltip and do not open equipped comparison panes.
- Keep unowned items using the existing effective tooltip variant behavior, including selected-variant fallback and equipped comparison panes when relevant.
- Remove `bestLootedItemLevel` from wishlist persistence and stop updating remembered best-looted item-level state on self-loot events.
- Keep selected-variant fallback, source metadata, and broad item tracking intact so tooltip fidelity and grouping behavior remain correct without remembered item-level history.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `wishlist-storage-model`: Wishlist persistence stops storing remembered best-looted item level while keeping locale-neutral selected-variant and source metadata intact.
- `wishlist-loot-awareness`: Self-loot handling stops recording or updating remembered best-looted item-level state for tracked items.
- `wishlist-tracker-display`: Tracker rows stop displaying the remembered item-level and track suffix and instead present item identity plus possession state only.
- `tracker-item-tooltips`: Tracker compare panes are suppressed for possessed items while remaining available for relevant unowned tracked items.

## Impact

- Affected code will likely center on `WishlistStore.lua`, `LootWishList.lua`, `TrackerModel.lua`, `TrackerUI.lua`, `TooltipCompare.lua`, and tracker/storage/loot tests.
- SavedVariables migration or repair behavior will need to normalize existing entries that still contain `bestLootedItemLevel`.
- Manual in-game validation will be important to confirm the simplified row presentation, possessed-item compare suppression, and lossless tooltip behavior for both owned and unowned tracked items.
