## 1. Adventure Guide favorite control state sync

- [x] 1.1 Update `AdventureGuide/WishlistCheckboxes.lua` so favorite-control state application sets matching opacity on both the foreground icon and background ring.
- [x] 1.2 Ensure favorite-button interaction handlers preserve synchronized opacity for tracked, untracked, pressed, and restored states.

## 2. Tracker attachment-mode clamping

- [x] 2.1 Update `Tracker/TrackerAnchoring.lua` so only detached mode uses screen clamping while attached append and attached standalone modes do not.
- [x] 2.2 Verify attachment toggles still preserve detached dragging, saved detached position, and detached lock behavior after the clamping change.

## 3. Validation

- [x] 3.1 Perform in-game smoke validation for Adventure Guide favorite icon opacity in tracked, untracked, press, release, and leave states.
- [x] 3.2 Perform in-game smoke validation for attached append overflow, attached standalone overflow, and detached screen clamping, including tracker tooltip or popup behavior near screen edges.
