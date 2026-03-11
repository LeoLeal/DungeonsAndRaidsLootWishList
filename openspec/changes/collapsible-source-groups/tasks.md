## 1. WishlistStore Changes

- [ ] 1.1 Add `collapsedGroups` table to character data structure
- [ ] 1.2 Implement `WishlistStore.setGroupCollapsed(db, charKey, label, collapsed)` function
- [ ] 1.3 Implement `WishlistStore.isGroupCollapsed(db, charKey, label)` function
- [ ] 1.4 Implement `WishlistStore.toggleGroupCollapse(db, charKey, label)` function

## 2. TrackerUI - Collapse Button Infrastructure

- [ ] 2.1 Create collapse button creation function `getOrCreateCollapseButton(block, groupLabel)`
- [ ] 2.2 Configure button to use native WoW atlases (collapse/expand)
- [ ] 2.3 Anchor button to right edge of block header
- [ ] 2.4 Call `block:AdjustRightEdgeOffset(-20)` to reserve space

## 3. TrackerUI - Collapse/Expand Logic

- [ ] 3.1 Modify `layoutContents` to check collapse state for each group
- [ ] 3.2 Add click handler to toggle collapse state in WishlistStore
- [ ] 3.3 Update button atlas based on collapse state
- [ ] 3.4 Conditionally skip item rendering when group is collapsed

## 4. TrackerUI - Header Text with Count

- [ ] 4.1 Modify header text to include item count when collapsed
- [ ] 4.2 Format: "Group Name (N)" where N is item count
- [ ] 4.3 Remove count when group is expanded

## 5. TrackerUI - Persistence Integration

- [ ] 5.1 Load collapsedGroups from WishlistStore on initialization
- [ ] 5.2 Pass character key to collapse state lookup
- [ ] 5.3 Save state after each toggle operation

## 6. Edge Cases and Testing

- [ ] 6.1 Handle new groups appearing (default to expanded if not in collapsedGroups)
- [ ] 6.2 Handle group becoming empty (hide completely, don't show as collapsed)
- [ ] 6.3 Test persistence across /reload and log out/in
- [ ] 6.4 Verify button atlases match native WoW style
- [ ] 6.5 Verify layout recalculates correctly after toggle

## 7. Cleanup

- [ ] 7.1 Remove any debug print statements
- [ ] 7.2 Verify no taint issues with secure frames
- [ ] 7.3 Test with various group counts (0, 1, many items)
