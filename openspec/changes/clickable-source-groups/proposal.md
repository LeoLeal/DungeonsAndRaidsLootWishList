## Why

Currently, when users track items from dungeons or raids, they appear in the Objective Tracker grouped by source (e.g., "Freehold", "Uldir"). However, there's no way to quickly jump to the Adventure Guide from these group headers. Users must manually navigate to the Adventure Guide to view loot details, boss strategies, or other information about that content. This feature would improve workflow by making the group headers clickable to open the Adventure Guide directly.

## What Changes

- **TrackerModel.lua**: Add `instanceID` field to group data so each source group knows which dungeon/raid it represents
- **TrackerUI.lua**: Add OnClick handler to block.Header using HookScript (secure hooking) that opens the Adventure Guide to the selected dungeon/raid when the group header is clicked
- Add conditional check to only make headers clickable when:
  - A valid `instanceID` exists for the group
  - The group label is NOT "Other" (fallback group should remain non-clickable)

## Capabilities

### New Capabilities
- **clickable-tracker-groups**: Makes dungeon/raid group headers in the Objective Tracker clickable to open the Adventure Guide to the corresponding dungeon/raid

### Modified Capabilities
- **wishlist-tracker-display**: The existing tracker display spec will have its requirements extended to include click behavior on source group headers (no delta spec needed - this is an additive feature that doesn't change existing requirements, only adds new behavior)

## Impact

- **TrackerModel.lua**: Modified to propagate instanceID through group building
- **TrackerUI.lua**: Modified to add click handlers to group headers
- **WishlistStore.lua**: No changes needed - instanceID is already stored in item metadata
- **LootWishList.lua**: No changes needed - instanceID is already passed through BuildTrackerGroups

### API Usage
- `EJ_SelectInstance(instanceID)` - Select the dungeon/raid in the Adventure Guide
- `EncounterJournal:Show()` - Open the Adventure Guide frame
- `frame:HookScript("OnClick", handler)` - Securely attach click handler to block.Header
