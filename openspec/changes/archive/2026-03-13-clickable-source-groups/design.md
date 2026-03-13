## Context

The Loot WishList addon displays tracked items in the WoW Objective Tracker, grouped by dungeon/raid source (e.g., "Freehold", "Uldir"). Currently, these group headers are display-only with no interactivity beyond the existing collapse/expand button.

The Adventure Guide (Encounter Journal) can be opened programmatically using WoW's `EJ_*` API functions. The addon already stores `instanceID` metadata when items are tracked from the Adventure Guide, but this ID is not propagated to the group level for use in click handlers.

## Goals / Non-Goals

**Goals:**
- Make dungeon/raid group headers clickable in the Objective Tracker
- Clicking a group header opens the Adventure Guide to the corresponding dungeon/raid
- Use secure hooking (HookScript) to avoid tainting the Objective Tracker
- Only enable clicking when valid instanceID exists and group is not "Other"

**Non-Goals:**
- Making the "Other" group clickable (it has no valid instanceID)
- Adding right-click or other click interactions
- Changing the collapse/expand button behavior
- Adding visual indicators beyond native Objective Tracker hover states

## Decisions

### D1: Use HookScript instead of SetScript for click handling

**Decision:** Use `block.Header:HookScript("OnClick", handler)` instead of `block.Header:SetScript("OnClick", handler)`.

**Rationale:** 
- HookScript is designed for secure frames and won't cause taint
- HookScript works even if no prior handler exists (it becomes a simple SetScript)
- The Objective Tracker is a critical UI component - avoiding taint is essential
- Existing codebase already uses HookScript successfully for tooltip and removal handling (TrackerUI.lua lines 154-195)

**Alternative Considered:** Using SetScript directly - rejected because secure handlers require secure hooking patterns.

### D2: Propagate instanceID through TrackerModel

**Decision:** Add `instanceID` field to group data in TrackerModel.buildGroups(), populated from any item in the group that has a valid instanceID.

**Rationale:**
- instanceID is already stored in WishlistStore when items are tracked
- TrackerModel is the pure transformation layer - this is the appropriate place to enrich group data
- Simpler than looking up instanceID in TrackerUI

**Alternative Considered:** Looking up instanceID in TrackerUI from item metadata - rejected because it couples UI logic to data structure.

### D3: Open Adventure Guide using EJ_SelectInstance + Show

**Decision:** Call `EJ_SelectInstance(group.instanceID)` followed by `EncounterJournal:Show()` when a header is clicked.

**Rationale:**
- EJ_SelectInstance is the proper API for selecting content in the Adventure Guide
- EncounterJournal:Show() ensures the frame is visible (if already open to different content, it switches)
- This matches how the addon already interacts with the Adventure Guide

**Alternative Considered:** Using other frame show methods - rejected as these are the documented APIs for this purpose.

## Risks / Trade-offs

### Risk: block.Header may not accept click events

**Likelihood:** Low  
**Impact:** Medium - feature won't work

**Mitigation:** 
- The collapse button is already positioned relative to block.Header, suggesting it's a Frame not just FontString
- If Header is not clickable, we can create an invisible Button overlay positioned over the header text area
- Test during implementation with in-game verification

### Risk: Legacy tracked items may lack instanceID

**Likelihood:** Low  
**Impact:** Low - those items will simply show non-clickable headers (same as "Other")

**Mitigation:** 
- The check `group.instanceID and group.label ~= "Other"` handles this gracefully
- Users can re-track items from Adventure Guide to populate instanceID
- Migration could backfill instanceID using EJ API (future enhancement if needed)

### Risk: Click on header text vs collapse button confusion

**Likelihood:** Low  
**Impact:** Low - native UI provides clear visual separation

**Mitigation:** 
- The collapse button is positioned at the right edge of the header
- Header click area is the text itself (left/center area)
- These don't overlap - user's click target is clear

## Migration Plan

1. **Deploy:** Single release containing changes to TrackerModel.lua and TrackerUI.lua
2. **Rollback:** Previous version of addon still works - headers just won't be clickable
3. **No data migration needed** - instanceID is already stored for new items
4. **No configuration changes** - feature is automatic based on existing data

## Open Questions

None at this time. The implementation path is clear from exploration.
