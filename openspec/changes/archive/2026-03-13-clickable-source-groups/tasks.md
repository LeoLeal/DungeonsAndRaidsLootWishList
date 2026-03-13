## 1. TrackerModel Changes

- [x] 1.1 Add instanceID field to group data structure in TrackerModel.buildGroups()
- [x] 1.2 Populate instanceID from tracked items when building groups
- [x] 1.3 Verify group has valid instanceID before including in group data

## 2. TrackerUI Changes

- [x] 2.1 Add click handler to block.Header using HookScript for secure hooking
- [x] 2.2 Implement OnClick handler that checks for valid instanceID
- [x] 2.3 Implement OnClick handler that checks group is not "Other"
- [x] 2.4 Call EJ_SelectInstance(group.instanceID) when header is clicked
- [x] 2.5 Call EncounterJournal:Show() to open Adventure Guide
- [x] 2.6 Test that collapse button click is not affected by header click handler

## 3. Testing

- [x] 3.1 Test clicking dungeon group header opens Adventure Guide to correct dungeon
- [x] 3.2 Test clicking raid group header opens Adventure Guide to correct raid
- [x] 3.3 Test clicking "Other" group header does nothing
- [x] 3.4 Test clicking group without valid instanceID does nothing
- [x] 3.5 Test collapse/expand button still works correctly
- [x] 3.6 Test hover states on headers are preserved (native Objective Tracker behavior)
