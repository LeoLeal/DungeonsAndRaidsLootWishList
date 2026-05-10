## Context

Over 31 archived changes, the codebase has accumulated dead code paths (functions that were superseded but never removed), duplicated utility functions copy-pasted across modules, and locale data quality issues. The addon's architecture already defines clear module boundaries and a shared utility area (`Core/Shared/`, `Tracker/TrackerUtils.lua`), so consolidation targets are well-defined. No saved-variable schema changes are needed.

## Goals / Non-Goals

**Goals:**
- Remove all confirmed dead code (6 items across 5 files)
- Consolidate duplicated utility functions into their natural shared homes
- Fix locale data so translations contain correct diacritical marks and regional variants alias their parent locale

**Non-Goals:**
- Refactoring function signatures, dispatch patterns, or delegation layers (e.g., Bootstrap.lua's event handler, TrackerPreferences pass-throughs)
- Consolidating duplicated constants (e.g., `DEFAULT_WIDTH`, `HEADER_HEIGHT`, magic `999`)
- Changing any user-facing behavior beyond correcting broken translation characters
- Changing the TOC load order for existing files

## Decisions

### Decision: Place `isCursorOverFrame` in a new `Core/Shared/FrameUtils.lua`

`isCursorOverFrame` is duplicated in `TrackerTooltip.lua`, `TrackerFilterMenu.lua`, and `AdventureGuide/WishlistTagPopover.lua`. The function is a generic frame hit-test utility with no Tracker-specific logic.

Create a new `Core/Shared/FrameUtils.lua` file to hold it as `FrameUtils.IsCursorOverFrame`. Add the corresponding TOC entry after the existing `Core/Shared/` files. All three consumers access it through `namespace.FrameUtils.IsCursorOverFrame`.

This respects module boundaries: `Core/Shared/` is the correct home for cross-module frame utilities. Placing it in `Tracker/TrackerUtils.lua` would force `AdventureGuide/WishlistTagPopover.lua` to depend on a sibling module's internals for a general-purpose utility.

**Alternative considered:** Placing it in `Tracker/TrackerUtils.lua` to avoid a TOC change. Rejected because it introduces a wrong-direction dependency — AdventureGuide reaching into Tracker for a generic utility that has nothing to do with the Tracker.

### Decision: Deduplicate `resolveInventoryType` within the DataStore module

The function is duplicated in `WishlistStore.lua` and `WishlistMigration.lua`. Both copies are local functions, and all 4 call sites are within those two DataStore files. The function exists to backfill a persistence field during store operations and migrations — this is a DataStore concern, not an item identity concern.

Keep the canonical copy in `WishlistMigration.lua` (which loads first per TOC order and has 3 of the 4 call sites). Expose it on the namespace as `WishlistMigration.resolveInventoryType`. Have `WishlistStore.lua` call it through `namespace.WishlistMigration.resolveInventoryType` instead of maintaining its own local copy.

**Alternative considered:** Moving it to `Core/Shared/ItemResolver.lua` since it calls `GetItemInfoInstant`. Rejected because the function is only used within DataStore for persistence backfill — moving it outward would cross module boundaries for no practical benefit.

### Decision: Extract item-ID fallback helper within `ItemResolver.lua`

The pattern `itemData.itemID or itemData.itemId or itemData.id` appears 3 times inside `ItemResolver.lua` (`getWishlistKey`, `normalizeItemData`, `getTooltipRef`). Extract a file-local helper `resolveRawItemId(data)` and call it from all three functions. This is a within-file extraction — no cross-module changes needed.

### Decision: Extract ordered-tags-from-lookup helper within `WishlistStore.lua`

The loop that rebuilds `orderedTags` from an `assignedLookup` against the tag catalog appears 3 times in `WishlistStore.lua` (`assignTag`, `unassignTag`, `deleteTag`). Extract a file-local helper `buildOrderedTagsFromLookup(character, assignedLookup)`. This is a within-file extraction.

### Decision: Alias locale variants instead of duplicating

Replace the `enGB` and `esMX` table literals with simple assignments after their parent tables are defined:
```lua
enGB = nil,  -- removed from inline table
-- after table definition:
translations.enGB = translations.enUS
translations.esMX = translations.esES
```

This ensures they share the same table reference. `getLocale()` already falls back to `enUS` for unknown locales, but explicit aliasing preserves `getSupportedLocales()` returning `enGB`/`esMX` in its list.

### Decision: Fix diacritical marks in-place

Correct the specific broken strings in `deDE`, `frFR`, `ptBR`, and `esES` directly. The corrections are:

| Locale | Key | Current | Corrected |
|--------|-----|---------|-----------|
| deDE | TAG_DELETE_CONFIRMATION_TITLE | `"...fortfahren mochtest?"` | `"...fortfahren möchtest?"` |
| deDE | TAG_DELETE_CONFIRMATION | `"...Gegenstande...loschst."` | `"...Gegenstände...löschst."` |
| deDE | TAG_DELETE_AFFECTED_ITEMS | `"Betroffene Gegenstande"` | `"Betroffene Gegenstände"` |
| esES | LOOT_WISHLIST | `"Lista de botin deseado"` | `"Lista de botín deseado"` |
| esES | TAG_DELETE_CONFIRMATION_TITLE | `"Quieres continuar?"` | `"¿Quieres continuar?"` |
| esES | TAG_DELETE_CONFIRMATION | `"...eliminaran...borras..."` | `"...eliminarán...borras..."` |
| frFR | CREATE | `"Creer"` | `"Créer"` |
| frFR | CREATE_NEW_TAG | `"Creer une nouvelle etiquette"` | `"Créer une nouvelle étiquette"` |
| frFR | TAG_FILTER | `"Filtrer les etiquettes"` | `"Filtrer les étiquettes"` |
| frFR | TAG_DELETE_CONFIRMATION | `"...retires...etiquette."` | `"...retirés...étiquette."` |
| frFR | TAG_DELETE_AFFECTED_ITEMS | `"Objets concernes"` | `"Objets concernés"` |
| ptBR | TAG_DELETE_CONFIRMATION | `"...serao...voce..."` | `"...serão...você..."` |

## Risks / Trade-offs

- **[Risk] Removing dead code that has an undiscovered caller** → Mitigated by grep-confirming zero call sites across the entire codebase before removal. All 6 items were verified.
- **[Risk] Consolidated utility function has subtly different behavior at one call site** → Mitigated by using the exact same function body from the duplicated copies, which are byte-for-byte identical. The deduplication is mechanical, not behavioral.
- **[Risk] Locale alias means `enGB` and `enUS` share a table reference — mutation of one affects the other** → Acceptable because the translations table is never mutated at runtime. All access is read-only through `Locales.getString()`.
