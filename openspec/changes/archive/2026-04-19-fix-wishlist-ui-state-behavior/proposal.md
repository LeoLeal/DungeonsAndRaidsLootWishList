## Why

The Adventure Guide wishlist favorite control currently applies reduced opacity only to the foreground heart icon, leaving the background ring visually inconsistent in untracked and pressed states. The attached wishlist tracker is also incorrectly clamped to the screen, which prevents it from continuing below the bottom edge when tall Objective Tracker content pushes it down.

## What Changes

- Align the Adventure Guide wishlist favorite control so its background ring always uses the same opacity as the foreground icon for each visual state.
- Update attached and attached-standalone tracker behavior so the wishlist frame may extend offscreen when Objective Tracker layout requires it.
- Preserve screen clamping only for detached tracker mode so the movable standalone frame still remains constrained to the viewport.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `adventure-guide-wishlist-toggle`: refine favorite icon visual-state requirements so foreground and background opacity remain synchronized across tracked, untracked, and interaction states.
- `wishlist-tracker-display`: refine tracker placement behavior so all non-detached presentations may extend below the visible screen while detached mode remains clamped to screen bounds.

## Impact

- Adventure Guide favorite icon presentation in `AdventureGuide/WishlistCheckboxes.lua`
- Tracker anchoring and layout behavior in `Tracker/TrackerAnchoring.lua` and related tracker rendering modules
- OpenSpec delta specs for Adventure Guide toggle visuals and attached versus detached tracker placement behavior
