## 1. TrackerModel Changes

- [ ] 1.1 Add instanceID field to group data structure in TrackerModel.buildGroups()
- [ ] 1.2 Populate instanceID from tracked items when building groups
- [ ] 1.3 Verify group has valid instanceID before including in group data

## 2. TrackerUI Changes

- [ ] 2.1 Add click handler to block.Header using HookScript for secure hooking
- [ ] 2.2 Implement OnClick handler that checks for valid instanceID
- [ ] 2.3 Implement OnClick handler that checks group is not "Other"
- [ ] 2.4 Call EJ_SelectInstance(group.instanceID) when header is clicked
- [ ] 2.5 Call EncounterJournal:Show() to open Adventure Guide
- [ ] 2.6 Test that collapse button click is not affected by header click handler

## 3. Testing

- [ ] 3.1 Test clicking dungeon group header opens Adventure Guide to correct dungeon
- [ ] 3.2 Test clicking raid group header opens Adventure Guide to correct raid
- [ ] 3.3 Test clicking "Other" group header does nothing
- [ ] 3.4 Test clicking group without valid instanceID does nothing
- [ ] 3.5 Test collapse/expand button still works correctly
- [ ] 3.6 Test hover states on headers are preserved (native Objective Tracker behavior)
