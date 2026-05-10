## 1. Dead Code Removal

- [x] 1.1 Remove `getExistingCharacter()` function from `DataStore/WishlistStore.lua`
- [x] 1.2 Remove `extractItemLinkFromLootMessage()` function from `LootAwareness/ChatLootParser.lua`
- [x] 1.3 Remove `ShowForRoll()` function from `LootAwareness/RollBadge/RollBadgeView.lua`
- [x] 1.4 Remove the `frame.LootWishListTag = badge.text` assignment from `LootAwareness/RollBadge/RollBadgeView.lua`
- [x] 1.5 Remove `getVisibleWidth()` function from `Tracker/TrackerHeaders.lua`
- [x] 1.6 Remove the unused local `isDescendantOf()` copy from `Tracker/TrackerFilterMenu.lua`

## 2. Consolidate Shared Utility Functions

- [x] 2.1 Create `Core/Shared/FrameUtils.lua` with `FrameUtils.IsCursorOverFrame`, add the TOC entry, and update `TrackerTooltip.lua`, `TrackerFilterMenu.lua`, and `AdventureGuide/WishlistTagPopover.lua` to call through the namespace
- [x] 2.2 Expose `resolveInventoryType()` from `DataStore/WishlistMigration.lua` as `WishlistMigration.resolveInventoryType` and update `DataStore/WishlistStore.lua` to call through the namespace instead of its local copy
## 3. Deduplicate Within-File Patterns

- [x] 3.1 Extract a local `resolveRawItemId(data)` helper in `Core/Shared/ItemResolver.lua` to replace the 3 inline `itemID or itemId or id` fallback chains
- [x] 3.2 Extract a local `buildOrderedTagsFromLookup(character, assignedLookup)` helper in `DataStore/WishlistStore.lua` to replace the 3 duplicated loops in `assignTag`, `unassignTag`, and `deleteTag`

## 4. Locale Data Fixes

- [x] 4.1 Replace the `enGB` table literal in `Core/Shared/Locales.lua` with an alias to `enUS` (`translations.enGB = translations.enUS`)
- [x] 4.2 Replace the `esMX` table literal in `Core/Shared/Locales.lua` with an alias to `esES` (`translations.esMX = translations.esES`)
- [x] 4.3 Fix diacritical marks in `deDE` strings: `TAG_DELETE_CONFIRMATION_TITLE` ("möchtest"), `TAG_DELETE_CONFIRMATION` ("Gegenstände", "löschst"), `TAG_DELETE_AFFECTED_ITEMS` ("Gegenstände")
- [x] 4.4 Fix diacritical marks in `esES` strings: `LOOT_WISHLIST` ("botín"), `TAG_DELETE_CONFIRMATION_TITLE` ("¿Quieres"), `TAG_DELETE_CONFIRMATION` ("eliminarán")
- [x] 4.5 Fix diacritical marks in `frFR` strings: `CREATE` ("Créer"), `CREATE_NEW_TAG` ("Créer", "étiquette"), `TAG_FILTER` ("étiquettes"), `TAG_DELETE_CONFIRMATION` ("retirés", "étiquette"), `TAG_DELETE_AFFECTED_ITEMS` ("concernés")
- [x] 4.6 Fix diacritical marks in `ptBR` strings: `TAG_DELETE_CONFIRMATION` ("serão", "você")
