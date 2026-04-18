## 1. Data model and migration

- [x] 1.1 Extend `DataStore/WishlistStore.lua` with per-character tag catalog storage, per-item tag assignments, and trimmed case-insensitive tag comparison helpers.
- [x] 1.2 Add DataStore tag operations for ordered tag lookup, assign or unassign, create, delete, deletion impact preview, used-tag lookup, and automatic removal of items that lose their last tag.
- [x] 1.3 Update `DataStore/WishlistMigration.lua` and related repair paths to seed the localized default tag and migrate legacy tracked items onto it without duplicating tags or assignments.

## 2. Shared wiring and localization

- [x] 2.1 Add shared locale entries for the default tag label, popover controls, and destructive tag-deletion confirmation copy.
- [x] 2.2 Add thin namespace or shared helpers so features can retrieve ordered assigned tags, format comma-separated tag text, and keep direct full-item removal behavior without making `Core/Bootstrap.lua` the owner of tag semantics.

## 3. Adventure Guide tag management UI

- [x] 3.1 Replace the Adventure Guide wishlist checkbox presentation with the favorite atlas icon that reflects whether the current item has any assigned tags.
- [x] 3.2 Build the compact live-apply tag popover with parchment-friendly nineslice styling, top-right close icon, content-based sizing, cursor-relative placement, and outside-click dismissal.
- [x] 3.3 Wire the popover tag list, assignment checkboxes, add-tag input and `Add` button, enabled and disabled delete icons, and the rule that creating a tag does not auto-assign it to the current item.
- [x] 3.4 Add the destructive tag-deletion confirmation dialog that lists affected items and only appears when deleting the tag would remove items from the wishlist.

## 4. Tracker filter and tooltip updates

- [x] 4.1 Add the tracker header filter button with the requested atlases, place it between the attach or detach control and grouping control, and disable plus grey it out when only one tag exists.
- [x] 4.2 Implement the addon-owned tracker filter menu so it shows only used tags, applies OR filtering, treats empty or all-selected state as show-all, and prunes stale selections when tags are deleted or become unused.
- [x] 4.3 Update tracker render-data shaping to carry ordered assigned tags on render items and apply tag filtering before grouping.
- [x] 4.4 Upgrade tracker tooltip footer handling to support ordered footer lines so source mode shows the tags line and slot mode shows the tags line above the source line.

## 5. Loot-awareness tag presentation

- [x] 5.1 Update loot roll badge presentation to render `Wishlist: <tags>` using the tracked item's assigned tags in catalog order without consulting tracker filter state.
- [x] 5.2 Update loot alert record building and dialog copy so alerts render `Wishlist(<tags>)` using the tracked item's assigned tags in catalog order without consulting tracker filter state.

## 6. Refresh integration and verification

- [x] 6.1 Verify refresh paths so tag edits update Adventure Guide state, tracker visibility, filter choices, and tooltip content without cross-feature ownership leaks.
- [x] 6.2 Perform in-game smoke validation for migration, live-apply popover behavior, last-tag removal, disabled single-tag filter button, tooltip footer ordering, loot roll badge text, and loot alert text.
