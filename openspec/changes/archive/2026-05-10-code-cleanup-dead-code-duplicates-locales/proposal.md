## Why

The codebase has accumulated dead code, duplicated functions, and locale data issues across 31 archived changes. Confirmed-unused functions remain in shipped files, identical utility logic is copy-pasted across 3–4 files instead of shared, and two locale entries duplicate their parent locale verbatim while others contain broken diacritical marks. Cleaning these up reduces maintenance surface, eliminates divergence risk, and fixes user-visible translation errors.

## What Changes

### Dead code removal
- Remove `getExistingCharacter()` from `DataStore/WishlistStore.lua` — defined but never called
- Remove `extractItemLinkFromLootMessage()` from `LootAwareness/ChatLootParser.lua` — defined but never called
- Remove `ShowForRoll()` from `LootAwareness/RollBadge/RollBadgeView.lua` — explicitly rejected in archived design notes, never called
- Remove the `frame.LootWishListTag = badge.text` assignment from `LootAwareness/RollBadge/RollBadgeView.lua` — assigned but never read
- Remove `getVisibleWidth()` from `Tracker/TrackerHeaders.lua` — defined but never called
- Remove the unused local `isDescendantOf()` copy from `Tracker/TrackerFilterMenu.lua` — dead duplicate of `TrackerUtils.IsDescendantOf`

### Duplicated function consolidation
- Consolidate `isCursorOverFrame()` (3 identical copies in `TrackerTooltip.lua`, `TrackerFilterMenu.lua`, `WishlistTagPopover.lua`) into a new `Core/Shared/FrameUtils.lua` shared utility
- Consolidate `resolveInventoryType()` (2 identical copies in `WishlistStore.lua`, `WishlistMigration.lua`) by keeping the canonical copy in `WishlistMigration.lua` and having `WishlistStore.lua` call it through the namespace
- Extract the repeated item-ID fallback chain (`itemID or itemId or id`) in `ItemResolver.lua` into a single local helper, replacing the 3 internal copies
- Extract the repeated "rebuild ordered tags from assigned lookup" loop in `WishlistStore.lua` into a local helper, replacing 3 internal copies


### Locale data fixes
- Alias `enGB` to `enUS` in `Core/Shared/Locales.lua` instead of duplicating all strings
- Alias `esMX` to `esES` in `Core/Shared/Locales.lua` instead of duplicating all strings
- Fix missing diacritical marks in `deDE` (`"mochtest"` → `"möchtest"`, `"Gegenstande"` → `"Gegenstände"`, `"loschst"` → `"löschst"`)
- Fix missing diacritical marks in `frFR` (`"Creer"` → `"Créer"`, `"etiquettes"` → `"étiquettes"`, `"retires"` → `"retirés"`, `"concernes"` → `"concernés"`)
- Fix missing diacritical marks in `ptBR` (`"serao"` → `"serão"`, `"voce"` → `"você"`)

## Capabilities

### New Capabilities

_(none — this is a cleanup change with no new capabilities)_

### Modified Capabilities

- `wishlist-localization`: Fix broken diacritical marks in deDE, frFR, and ptBR translation strings to satisfy the existing requirement that all user-facing labels are properly localized

## Impact

- **Files modified (dead code removal):** `WishlistStore.lua`, `ChatLootParser.lua`, `RollBadgeView.lua`, `TrackerHeaders.lua`, `TrackerFilterMenu.lua`
- **Files modified (deduplication):** `TrackerTooltip.lua`, `TrackerFilterMenu.lua`, `WishlistTagPopover.lua`, `WishlistStore.lua`, `WishlistMigration.lua`, `ItemResolver.lua`
- **Files added:** `Core/Shared/FrameUtils.lua`
- **Files modified (locales):** `Locales.lua`
- **No saved-variable changes** — no migration needed
- **TOC change** — one new entry for `Core/Shared/FrameUtils.lua`
- **No user-facing behavior changes** except corrected translation strings in deDE, frFR, and ptBR
