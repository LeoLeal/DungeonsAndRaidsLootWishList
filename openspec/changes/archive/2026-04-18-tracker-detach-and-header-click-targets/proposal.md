## Why

The tracker already supports collapsible group sections and addon-owned header controls, but group headers still require precise clicks on a small button and the wishlist cannot be separated from the Objective Tracker when players want to position it elsewhere. This change improves tracker ergonomics by making group collapse easier to use and by introducing a persisted detached presentation with its own collapsible header and movement lock that still matches Blizzard-native tracker styling.

## What Changes

- Make each tracker group header row toggle the same collapse or expand behavior as its existing right-edge collapse button.
- Add an inline attach or detach control to the `Loot Wishlist` header that switches the wishlist between its current Objective Tracker-attached presentation and a detached movable presentation.
- In detached mode, show a single surrogate-style `Loot Wishlist` header that can collapse or expand the detached content, keep the wishlist visible independently of native Objective Tracker collapse, and restore the last detached position when detached again.
- Add a detached-header atlas-based lock-state control between the grouping toggle and attach/detach button so players can toggle whether the detached tracker can be moved while seeing the current movement state.
- Persist the attached or detached state, detached frame position, and detached lock state per character as tracker preferences while keeping the default state attached and the default detached lock state unlocked.

## Capabilities

### New Capabilities
- `tracker-placement-preferences`: Persist per-character wishlist tracker attachment mode, detached frame position, and detached lock state so detached placement behavior survives reloads and relogs.

### Modified Capabilities
- `wishlist-tracker-display`: Expand tracker header interaction so whole group header rows toggle collapse, and add an attached-versus-detached wishlist presentation with Blizzard-native header visuals, detached-header collapse behavior, and detached lock controls.

## Impact

- Affected specs: `openspec/specs/wishlist-tracker-display/spec.md`, new `openspec/specs/tracker-placement-preferences/spec.md`
- Affected systems: `Tracker/TrackerRows.lua`, `Tracker/TrackerFrame.lua`, `Tracker/TrackerHeaders.lua`, `Tracker/TrackerAnchoring.lua`, `Tracker/Feature.lua`, `DataStore/TrackerPreferences.lua`, `DataStore/WishlistStore.lua`
- Affected UI behavior: group-header click targets, wishlist header controls, detached header collapse and lock controls, detached frame dragging and placement restore, attached-versus-detached visibility rules
