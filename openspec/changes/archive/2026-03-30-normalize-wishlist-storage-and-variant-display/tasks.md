## 1. Normalize wishlist persistence and migration

- [x] 1.1 Refactor `WishlistStore.lua` so tracked membership is represented by entry presence and untracking deletes the item entry instead of writing `tracked = false`
- [x] 1.2 Update wishlist entry write paths to persist only the normalized locale-neutral fields (`bestLootedItemLevel`, `instanceID`, `encounterID`, retained `inventoryType`, and `selectedVariantRef` when available)
- [x] 1.3 Add an idempotent SavedVariables migration that upgrades legacy tracked entries, removes untracked tombstones, strips localized fields, and derives `selectedVariantRef` from legacy `itemLink` when possible

## 2. Capture and consume selected variant references

- [x] 2.1 Update `AdventureGuideUI.lua` tracking flows so adding an item captures a locale-neutral `selectedVariantRef` from the selected Adventure Guide row without changing base-item-scoped membership
- [x] 2.2 Update `LootWishList.lua` and any supporting resolver helpers so tooltip/display variant resolution prefers best owned live links, then persisted `selectedVariantRef`, then stable base-item fallback
- [x] 2.3 Ensure persisted source metadata and runtime label enrichment no longer depend on stored localized item, source, or boss strings

## 3. Update tracker tooltip and row presentation

- [x] 3.1 Update tracker tooltip resolution in `TrackerUI.lua` to use the effective display variant pipeline while keeping tooltip ownership isolated from shared Blizzard tooltip state
- [x] 3.2 Update tracker row text/styling so suffix formatting becomes `(<ITEM LEVEL> <ITEM TRACK>)` when both are known, `(<ITEM LEVEL>)` when only item level is known, and nothing when item level is unknown
- [x] 3.3 Implement localized item-track derivation from `C_TooltipInfo.GetHyperlink` / tooltip-data lines with a bounded follow-up refresh trigger when track data is initially unavailable

## 4. Preserve taint-safe runtime boundaries

- [x] 4.1 Keep all new runtime enrichment on addon-owned, read-only API paths so tracker rebuild and track derivation do not reopen shared tooltip or Encounter Journal taint boundaries
- [x] 4.2 Verify no new tracker or tooltip path calls `EncounterJournal_OpenJournal`, `EJ_SelectInstance`, or reuses shared tooltip frames as a data source for track/source text

## 5. Verify behavior and regression coverage

- [x] 5.1 Update or add automated tests for normalized wishlist storage, legacy migration, selected-variant persistence, and effective display variant fallback resolution in the pure/testable seams
- [x] 5.2 Manually validate Adventure Guide tracking, tracker tooltip fallback, tracker suffix formatting, and legacy SavedVariables upgrade behavior in-game across owned and unowned variants
- [x] 5.3 Run taint-focused in-game validation with `taint.log` around tracker hover, Adventure Guide selection, post-migration refresh, and delayed tooltip-data updates to confirm no taint regressions
