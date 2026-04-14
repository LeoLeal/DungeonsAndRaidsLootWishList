# Change Summary

## Change

`reorganize-addon-modules`

## What Was Done

- Reorganized the addon from root-level modules into folder-based modules.
- Moved shared cross-feature logic into `Core/Shared/`:
  - `ItemResolver.lua`
  - `Locales.lua`
  - `TooltipCompare.lua`
- Split persistence into `DataStore/`:
  - `WishlistStore.lua`
  - `WishlistMigration.lua`
  - `TrackerPreferences.lua`
- Moved Adventure Guide behavior into `AdventureGuide/`:
  - `Feature.lua`
  - `MetadataCapture.lua`
  - `LootRowScanner.lua`
  - `LootRowItemData.lua`
  - `WishlistCheckboxes.lua`
  - `JournalHooks.lua`
- Moved tracker behavior into `Tracker/`:
  - `Feature.lua`
  - `TrackerFrame.lua`
  - `TrackerRows.lua`
  - `TrackerHeaders.lua`
  - `TrackerContextMenu.lua`
  - `TrackerAnchoring.lua`
  - `TrackerTooltip.lua`
  - `TrackerGroups.lua`
  - `TrackerRowStyle.lua`
  - `PossessionScanner.lua`
  - `RaidBossOrdering.lua`
  - `TrackerUtils.lua`
- Moved loot reaction behavior into `LootAwareness/`:
  - `Feature.lua`
  - `ChatLootParser.lua`
  - `LootMatcher.lua`
  - `LootEventHandlers.lua`
  - `RecentSelfLoot.lua`
  - `Alerts/LootAlertDialog.lua`
  - `Alerts/AlertPresenter.lua`
  - `Alerts/AlertQueue.lua`
  - `RollBadge/RollFrameLocator.lua`
  - `RollBadge/RollBadgeView.lua`
- Moved the core addon runtime into `Core/Bootstrap.lua`.
- Updated `DungeonsAndRaidsLootWishList.toc` to load only folder-based module paths.
- Removed obsolete root-level Lua modules.
- Removed stale compatibility aliases and duplicated fallback implementations introduced during the refactor.
- Removed the local test file at your request.

## Resulting Structure

```text
Core/
  Bootstrap.lua
  Shared/

DataStore/

AdventureGuide/

Tracker/

LootAwareness/
```

## Important Notes

- Root-level Lua feature/helper files were removed from the addon layout.
- The addon is now organized by folder ownership instead of flat root modules.
- Legacy alias exports like `TrackerUI`, `AdventureGuideUI`, `LootEvents`, and `WishListAlert` were removed.
- Tests were deleted and therefore no test suite remains in the repository right now.

## Suggested Next Step

Execute a final naming-consistency pass across the new modules.

Suggested focus:

- Rename local table names to match file/module names exactly.
  - Example: ensure `AdventureGuide/Feature.lua` uses `AdventureGuide`, not older names.
  - Example: ensure `LootAwareness/Alerts/LootAlertDialog.lua` uses `LootAlertDialog` consistently throughout.
- Remove any remaining wording that reflects the pre-refactor naming.
- Do a final manual review of exported namespace names to ensure they match the new folder structure cleanly.

## Status At Logout

- Structural refactor completed.
- Wiring cleanup completed.
- Duplication cleanup completed.
- Naming consistency pass still recommended.
