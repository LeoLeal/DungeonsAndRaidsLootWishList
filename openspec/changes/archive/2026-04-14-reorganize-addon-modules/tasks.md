## 1. Establish the target module layout

- [x] 1.1 Create the `Core`, `Core/Shared`, `DataStore`, `AdventureGuide`, `Tracker`, and `LootAwareness` directory structure, including `LootAwareness/Alerts` and `LootAwareness/RollBadge`
- [x] 1.2 Update the `.toc` file to load shared primitives first, persistence modules before consuming features, feature internals before feature entrypoints, and `Core/Bootstrap.lua` last
- [x] 1.3 Introduce `Feature.lua` entrypoints for `AdventureGuide`, `Tracker`, and `LootAwareness` so cross-feature access has explicit public boundaries

## 2. Extract core and shared addon primitives

- [x] 2.1 Move bootstrap-only logic from `LootWishList.lua` into `Core/Bootstrap.lua`
- [x] 2.2 Move shared cross-feature primitives into `Core/Shared/ItemResolver.lua`, `Core/Shared/TooltipCompare.lua`, and `Core/Shared/Locales.lua`
- [x] 2.3 Update namespace wiring and module references so features consume `Core/Shared` primitives without reaching through legacy root-level file paths

## 3. Split persistence into DataStore-owned modules

- [x] 3.1 Keep tracked-item reads and writes in `DataStore/WishlistStore.lua` while removing feature-specific responsibilities from it
- [x] 3.2 Extract wishlist normalization and migration behavior into `DataStore/WishlistMigration.lua`
- [x] 3.3 Extract persisted tracker grouping and collapse preferences into `DataStore/TrackerPreferences.lua`
- [x] 3.4 Ensure Adventure Guide metadata capture and other live widget traversal no longer live in DataStore-owned modules

## 4. Reorganize AdventureGuide into a vertical feature

- [x] 4.1 Split Encounter Journal hook registration into `AdventureGuide/JournalHooks.lua`
- [x] 4.2 Split loot-row discovery and row item-data extraction into `AdventureGuide/LootRowScanner.lua` and `AdventureGuide/LootRowItemData.lua`
- [x] 4.3 Move wishlist checkbox presentation and toggle handling into `AdventureGuide/WishlistCheckboxes.lua`
- [x] 4.4 Move journal-facing metadata capture into `AdventureGuide/MetadataCapture.lua` and expose the feature through `AdventureGuide/Feature.lua`

## 5. Reorganize Tracker into a vertical feature

- [x] 5.1 Split tracker frame creation, anchoring, headers, rows, and context menu behavior into focused `Tracker` modules
- [x] 5.2 Move tracker grouping and raid boss ordering into `Tracker/TrackerGroups.lua` and `Tracker/RaidBossOrdering.lua`
- [x] 5.3 Move possession scanning and effective tracker row state derivation into `Tracker/PossessionScanner.lua`
- [x] 5.4 Move tracker tooltip orchestration into `Tracker/TrackerTooltip.lua` while keeping shared tooltip primitives in `Core/Shared`
- [x] 5.5 Move tracker row-style constants into `Tracker/TrackerRowStyle.lua` and expose tracker behavior through `Tracker/Feature.lua`

## 6. Reorganize LootAwareness into a vertical feature

- [x] 6.1 Move loot-event parsing and tracked-item matching into `LootAwareness/ChatLootParser.lua`, `LootAwareness/LootMatcher.lua`, and `LootAwareness/LootEventHandlers.lua`
- [x] 6.2 Move recent-self-loot tracking into `LootAwareness/RecentSelfLoot.lua` and connect any tracker-owned possession signals through explicit feature boundaries
- [x] 6.3 Move alert queueing and dialog presentation into `LootAwareness/Alerts/AlertQueue.lua`, `LootAwareness/Alerts/AlertPresenter.lua`, and `LootAwareness/Alerts/LootAlertDialog.lua`
- [x] 6.4 Move loot-roll badge frame lookup and badge rendering into `LootAwareness/RollBadge/RollFrameLocator.lua` and `LootAwareness/RollBadge/RollBadgeView.lua`
- [x] 6.5 Expose the feature through `LootAwareness/Feature.lua` and remove bootstrap ownership of feature-specific loot reactions

## 7. Finalize wiring and cleanup

- [x] 7.1 Update remaining cross-feature calls so they go through `Feature.lua` entrypoints rather than internal module files
- [x] 7.2 Remove obsolete root-level modules or reduce them to thin compatibility shims only where temporarily required during migration
- [x] 7.3 Remove the obsolete local test files and related package assets as part of the refactor cleanup
