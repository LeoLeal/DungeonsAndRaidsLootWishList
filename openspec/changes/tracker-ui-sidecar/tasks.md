# Tasks: TrackerUI Side-Car Refactor

## Phase 1: Scaffold and Decouple
- [ ] 1. In `TrackerUI.lua`, remove all references to `ObjectiveTrackerModuleTemplate`, `ObjectiveTrackerModuleMixin`, and `ObjectiveTrackerFrame:AddModule`.
- [ ] 2. Create the main `LootWishlistSideCar` Frame (the master container) with no initial anchors.
- [ ] 3. Implement the `hooksecurefunc` on `ObjectiveTrackerContainerMixin.Update` using the logic defined in `design.md` to control visibility and positioning of the `LootWishlistSideCar`.

## Phase 2: Frame Pooling and Visuals
- [ ] 4. Initialize `CreateFramePool` for Header blocks using a custom pure-Lua setup that mimics native headers (Font: `ObjectiveTrackerHeaderFont`).
- [ ] 5. Initialize `CreateFramePool` for Item lines using a custom pure-Lua setup that mimics native lines (Font: `ObjectiveFont`, Dash/Checkmarks via `TrackerRowStyle.lua`).
- [ ] 6. Implement the `TrackerUI.Refresh(groups)` function to `ReleaseAll()` on pools, iterate `groups`, `Acquire()` frames, and stack them vertically inside the `LootWishlistSideCar`.

## Phase 3: Interaction and Security
- [ ] 7. Add click handlers to the pure-Lua Header blocks to replicate the Encounter Journal opening/switching behavior.
- [ ] 8. Add click handlers to Header collapse buttons to trigger `WishlistStore.toggleGroupCollapse` and call `Refresh`.
- [ ] 9. Implement the strict, taint-safe tooltip logic on Item lines: `GameTooltip:Hide()` -> `SetOwner(UIParent, "ANCHOR_CURSOR")` -> `SetHyperlink/SetItemByID`.
- [ ] 10. Implement Shift-Click to remove functionality on Item lines.

## Phase 4: Validation
- [ ] 11. Verify the layout expands and collapses correctly when groups are toggled.
- [ ] 12. Verify the Side-Car hides completely when the native tracker's global collapse button is clicked.
- [ ] 13. Run `/console taintLog 2`, enter combat, and verify no "Action Forbidden" errors occur when hovering over tracker items.