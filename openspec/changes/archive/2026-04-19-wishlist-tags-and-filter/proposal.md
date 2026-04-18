## Why

The addon's current wishlist model only supports a single tracked state per item, which makes it hard for players to organize why an item matters and to focus tracker views without changing what counts as tracked loot. Adding user-authored tags now lets wishlist data carry lightweight intent across the Adventure Guide, tracker, and loot-awareness surfaces while preserving stable underlying membership and keeping module ownership clear.

## What Changes

- Add a per-character tagging system for wishlist items, with tags stored as plain text labels authored by the user.
- Redefine wishlist membership so an item is tracked when it has at least one tag rather than a simple boolean tracked flag.
- Seed one initial default tag once per character using the localized label `Best in slot` for the active locale at migration or first use, without later translating stored tags if the locale changes.
- Enforce case-insensitive tag uniqueness and maintain the invariant that at least one tag always exists in the addon.
- Migrate existing tracked items so they are assigned to the initial default tag.
- Replace Adventure Guide wishlist checkboxes with a Blizzard-atlas favorite icon that opens a small parchment-friendly live-apply popover near the cursor.
- Add tag assignment controls to the Adventure Guide popover: per-tag checkboxes, delete buttons, a text input with Add button, a top-right close icon, and outside-click dismissal.
- Keep tag creation separate from assignment so creating a new tag does not automatically apply it to the current item.
- Require confirmation before deleting a tag when its removal would untrack items that only have that tag, and list the affected items in the confirmation dialog.
- Add a tracker filter button between the attach/detach and grouping controls.
- Add tracker tag filtering that only offers tags currently used by at least one item, supports multi-select OR filtering, persists the user's current selection, treats no selection as show-all, and automatically prunes stale selections when tags are deleted or become unused.
- Keep tracker filter state presentation-only so it never changes tracked membership and never suppresses loot alerts or loot roll badges, even though the current selection is persisted per character.
- Extend tracker item tooltips with a tags footer line using the favorite atlas and comma-separated tags; in slot-grouped mode this line appears above the existing source footer, while source-grouped mode only shows the tags line.
- Update loot roll badge text from `Wishlist` to `Wishlist: <tag1>, <tag2>, ...`.
- Update loot alert dialog copy from `<player> looted an item on your Wishlist!` to `<player> looted an item on your Wishlist (<tag1>, <tag2>, ...)!`.
- Preserve architectural boundaries so DataStore owns tag catalog, assignment, deletion, and migration invariants; AdventureGuide owns journal icon and popover UI; Tracker owns filtering and tooltip presentation; LootAwareness owns badge and alert presentation; and Core bootstrap remains orchestration-only.

## Capabilities

### New Capabilities
- `wishlist-tags`: Per-character tag catalog, item tag assignment, migration of legacy tracked items, and tag lifecycle rules including case-insensitive uniqueness, default-tag seeding, and deletion safeguards.
- `wishlist-tag-management-ui`: Adventure Guide tag icon and live-apply popover flow for assigning, creating, deleting, confirming destructive tag removal, and dismissing the popover.
- `tracker-tag-filtering`: Tracker tag filter controls, persisted but presentation-only multi-select OR filtering, stale selection pruning, and tag-aware tooltip footer presentation.
- `loot-tag-awareness`: Tag-aware loot roll badges and loot alerts that surface assigned tags without changing the underlying tracked-item matching rules.

### Modified Capabilities
- None.

## Impact

- Affected code: `DataStore/WishlistStore.lua`, `DataStore/WishlistMigration.lua`, `AdventureGuide/*`, `Tracker/*`, `LootAwareness/*`, and narrow refresh wiring in `Core/Bootstrap.lua`.
- Data model impact: persisted per-character wishlist data changes from boolean-like tracked membership to tag-based membership and requires migration of existing tracked items onto the initial default tag.
- UI impact: Adventure Guide wishlist affordance changes from checkbox behavior to favorite-icon popover management, tracker gains a filter control and tag-aware tooltip footers, and loot-awareness text surfaces include assigned tags.
- Behavioral guardrail: tracker filtering remains presentation-only and must not affect tracked membership, loot alert triggering, or loot roll badge presence.
