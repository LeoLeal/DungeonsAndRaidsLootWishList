## Why

Wishlist tracker tooltips currently use the game's default anchor, which can feel detached from the hovered row. Anchoring the tooltip to the row itself makes the hover feedback more spatially obvious without changing tooltip content.

## What Changes

- Update wishlist tracker row tooltips to anchor with the tooltip top-right aligned to the row's top-left, with a 4px horizontal gap.
- Keep tooltip creation, ownership, and content unchanged (still Blizzard-native and owned by UIParent).
- Limit the anchoring change to Objective Tracker wishlist rows only.

## Capabilities

### New Capabilities


### Modified Capabilities

- `tracker-item-tooltips`: Tracker row tooltip anchoring changes from default behavior to a row-anchored placement for wishlist rows.

## Impact

- `TrackerUI.lua`: adjust hover tooltip anchoring logic.
- In-game verification of hover behavior for wishlist rows.
