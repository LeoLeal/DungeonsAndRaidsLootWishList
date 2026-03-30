## Why

Wishlist persistence currently mixes canonical tracking state with locale-specific presentation data such as localized item names, full display links, source labels, and boss names. This makes SavedVariables brittle across client locale changes and hides the addon's real model, where wishlist membership is base-item scoped and most presentation can be derived from live APIs.

## What Changes

- Normalize wishlist storage so tracked membership is represented by entry presence instead of a persisted `tracked` boolean.
- Remove locale-specific saved presentation fields from wishlist entries and keep only durable tracking data, stable source identifiers, remembered loot history, and a locale-neutral `selectedVariantRef` for display fallback.
- Continue matching wishlist membership by base item ID while remembering the specific Adventure Guide variant the player selected for tooltip fallback when no live owned link is available.
- Update tracker row presentation so the suffix changes from `(<ITEM LEVEL>)` to `(<ITEM LEVEL> <ITEM TRACK>)` when both values are known, remains `(<ITEM LEVEL>)` when only item level is known, and appends nothing when item level is unknown.
- Add a SavedVariables migration that upgrades legacy entries, drops tombstone-style untracked records, and converts legacy tracked links into the new locale-neutral variant reference where possible.

## Capabilities

### New Capabilities
- `wishlist-storage-model`: Defines canonical wishlist persistence, locale-neutral selected-variant fallback, and migration behavior for normalized SavedVariables.

### Modified Capabilities
- `adventure-guide-wishlist-toggle`: Wishlist toggles continue to track items by base item identity while also capturing the selected Adventure Guide variant as a locale-neutral fallback reference.
- `tracker-item-tooltips`: Tracker tooltip resolution changes to prefer the best currently owned item link, then the persisted selected variant reference, then stable item-ID fallback.
- `wishlist-tracker-display`: Tracker rows continue to show best owned styling when available and now append item level and item track text from the effective display variant when both are known.

## Impact

- Affected code centers on `WishlistStore.lua`, `LootWishList.lua`, `ItemResolver.lua`, `AdventureGuideUI.lua`, and `TrackerUI.lua`.
- Saved variables require an explicit migration path so existing wishlists are preserved while legacy localized fields and untracked tombstones are removed.
- Tracker and tooltip display paths must stop depending on persisted localized labels and instead derive effective display data from live owned links, the locale-neutral selected variant reference, and stable source identifiers.
