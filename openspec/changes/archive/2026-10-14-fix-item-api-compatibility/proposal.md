# Proposal

## Why

After a recent WoW update, wishlist tracker rows display item IDs without rarity colors even though tooltips and possession indicators work. In-game diagnostics confirm that the legacy global `GetItemInfo` is unavailable while `C_Item.GetItemInfo` successfully returns the tracked item's name, link, and quality; the addon currently treats the missing global as missing item data.

## What Changes

- Resolve tracker item names and rarity colors through supported namespaced item APIs, without depending on legacy global aliases.
- Preserve effective-variant selection, tooltips, possession indicators, grouping, and existing missing-data fallbacks.
- Review related legacy item API calls in alert presentation, tag popovers, metadata resolution, possession scanning, and development-only test commands; update equivalent calls where the same compatibility issue applies.
- Add focused regression checks for a client environment with namespaced APIs available and legacy globals absent.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `wishlist-tracker-display`: Explicitly require resolved localized item names and effective-variant rarity colors when supported item APIs supply data, including when legacy global aliases are absent.

## Impact

- Primary code: `Core/Bootstrap.lua` and `Tracker/TrackerRows.lua`; regression coverage also exercises `Tracker/TrackerRenderData.lua`.
- Related compatibility review: `AdventureGuide/WishlistTagPopover.lua`, `LootAwareness/Alerts/LootAlertDialog.lua`, `Core/Shared/ItemResolver.lua`, `DataStore/WishlistMigration.lua`, and `Tracker/PossessionScanner.lua`.
- APIs: `C_Item.GetItemInfo` and verified namespaced equivalents for existing item icon, inventory-type, item-level, and quality-color lookups.
- No new external dependencies, saved-variable migration, wishlist reset, layout changes, or Blizzard-global replacements.
