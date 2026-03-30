## 1. Remove best-looted item-level persistence and normalization leftovers

- [x] 1.1 Update `WishlistStore.lua` so tracked entries no longer write or expose `bestLootedItemLevel` as persisted wishlist state and remove obsolete helper functions for that field
- [x] 1.2 Extend the existing normalization / repair path to strip `bestLootedItemLevel` from loaded entries without changing the persistence version
- [x] 1.3 Update persistence-focused tests to verify normalized entries no longer retain `bestLootedItemLevel`

## 2. Remove remembered item-level behavior from loot and tracker models

- [x] 2.1 Update self-loot handling so tracked self-loot no longer records or updates remembered item-level history
- [x] 2.2 Remove tracker-row suffix generation from `TrackerModel.lua` and any related row-layout logic in `TrackerUI.lua`
- [x] 2.3 Update tracker-display tests so rows present only item identity and possession state

## 3. Refine tooltip compare behavior for owned vs unowned items

- [x] 3.1 Update tracker tooltip behavior so possessed rows show only the possessed tooltip and suppress equipped comparison panes
- [x] 3.2 Preserve equipped comparison panes for relevant unowned tracked items using the existing real tooltip variant path
- [x] 3.3 Update tooltip/hover tests to cover possessed compare suppression and unowned compare retention

## 4. Validate the simplified tracker UX

- [x] 4.1 Manually validate in-game that tracker rows no longer show the item-level suffix, possessed rows still show the green tick, and unowned rows still show truthful tooltips
- [x] 4.2 Manually validate in-game that possessed rows suppress compare panes while unowned equippable rows still show compare panes when appropriate
