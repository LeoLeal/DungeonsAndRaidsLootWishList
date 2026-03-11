## Why

The Loot Wishlist tracker currently displays all tracked items in a single flat list grouped by source (dungeon/raid). As players track more items, the list grows long and becomes harder to scan. Making source groups collapsible lets users focus on the content they care about while keeping the full wishlist accessible.

## What Changes

- Add collapsible behavior to source groups (dungeons, raids, Other) in the Objective Tracker
- Persist collapsed/expanded state per character
- Show item count in group title when collapsed (e.g., "Brackenhide Hollow (3)")
- Add native-style collapse/expand buttons to the right edge of each group header
- Groups with zero items remain hidden (existing behavior unchanged)

## Capabilities

### New Capabilities

- **collapsible-tracker-groups**: Adds collapse/expand functionality to source groups in the wishlist tracker, with persistence and item count display

### Modified Capabilities

- None. This feature is additive and does not change existing spec behavior.

## Impact

### Files Modified

- **WishlistStore.lua**: Add persistence functions for collapsed group state
- **TrackerUI.lua**: Add collapse button creation, click handlers, and conditional item rendering

### UI/UX Impact

- New collapse buttons appear in tracker section
- Collapsed groups display item count in header
- State persists across sessions per character

### No Breaking Changes

- All existing behavior preserved
- Groups still hide when empty
- Default state is expanded
