## 1. WishlistStore Changes

- [x] 1.1 Add `collapsedGroups` table to character data structure
- [x] 1.2 Implement `WishlistStore.setGroupCollapsed(db, charKey, label, collapsed)` function
- [x] 1.3 Implement `WishlistStore.isGroupCollapsed(db, charKey, label)` function
- [x] 1.4 Implement `WishlistStore.toggleGroupCollapse(db, charKey, label)` function

## 2. TrackerUI - Collapse Button Infrastructure

- [x] 2.1 Create collapse button creation function `getOrCreateCollapseButton(block, groupLabel)`
- [x] 2.2 Configure button to use native WoW atlases (collapse/expand)
- [x] 2.3 Anchor button to right edge of block header
- [x] 2.4 Call `block:AdjustRightEdgeOffset(-20)` to reserve space

## 3. TrackerUI - Collapse/Expand Logic

- [x] 3.1 Modify `layoutContents` to check collapse state for each group
- [x] 3.2 Add click handler to toggle collapse state in WishlistStore
- [x] 3.3 Update button atlas based on collapse state
- [x] 3.4 Conditionally skip item rendering when group is collapsed

## 4. TrackerUI - Header Text with Count

- [x] 4.1 Modify header text to include item count when collapsed
- [x] 4.2 Format: "Group Name (N)" where N is item count
- [x] 4.3 Remove count when group is expanded

## 5. TrackerUI - Persistence Integration

- [x] 5.1 Load collapsedGroups from WishlistStore on initialization
- [x] 5.2 Pass character key to collapse state lookup
- [x] 5.3 Save state after each toggle operation

## 6. Edge Cases and Testing

- [x] 6.1 Handle new groups appearing (default to expanded if not in collapsedGroups)
- [x] 6.2 Handle group becoming empty (hide completely, don't show as collapsed)
- [x] 6.3 Test persistence across /reload and log out/in
- [x] 6.4 Verify button atlases match native WoW style
- [x] 6.5 Verify layout recalculates correctly after toggle

## 7. Cleanup

- [x] 7.1 Remove any debug print statements
- [x] 7.2 Verify no taint issues with secure frames
- [x] 7.3 Test with various group counts (0, 1, many items)
