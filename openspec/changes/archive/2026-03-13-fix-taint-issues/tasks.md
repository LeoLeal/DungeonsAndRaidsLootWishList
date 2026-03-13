## 1. TrackerUI.lua - Collapse Button

- [x] 1.1 Keep `SetScript` for collapse button (custom button, not from secure template)

## 2. AdventureGuideUI.lua - HookScript Conversion

- [x] 2.1 Change `checkbox:SetScript("OnClick", ...)` to `checkbox:HookScript("OnClick", ...)` in AdventureGuideUI.lua

## 3. Add InCombatLockdown Utility Function

- [x] 3.1 Create `QueueAfterCombat(callback)` utility function in LootWishList.lua
- [x] 3.2 Test that the function properly queues operations after combat ends

## 4. Add InCombatLockdown Checks to Event Handlers

- [x] 4.1 Add InCombatLockdown() check to CHAT_MSG_LOOT event handler
- [x] 4.2 Add InCombatLockdown() check to START_LOOT_ROLL event handler
- [x] 4.3 Add InCombatLockdown() check to BAG_UPDATE_DELAYED event handler
- [x] 4.4 Add InCombatLockdown() check to PLAYER_EQUIPMENT_CHANGED event handler

## 5. Defer Non-Critical Refreshes During Combat

- [x] 5.1 Mark RefreshAll() calls as critical or non-critical
- [x] 5.2 Skip non-critical refreshes during combat
- [x] 5.3 Queue critical refreshes after combat using QueueAfterCombat

## 6. Prevent Tooltips During Combat

- [x] 6.1 Add InCombatLockdown() check to tracker item OnEnter hook
- [x] 6.2 Verify tooltip is not shown during combat

## 7. Testing

- [x] 7.1 Enable taint logging with `/console taintLog 1`
- [x] 7.2 Test collapse/expand functionality in Objective Tracker
- [x] 7.3 Test Adventure Guide checkbox toggle
- [x] 7.4 Test that events are handled correctly out of combat
- [x] 7.5 Test that events are deferred during combat
- [x] 7.6 Test that queued operations execute after leaving combat
- [x] 7.7 Test all functionality in combat (enable PvP or raid boss)
- [x] 7.8 Test that tooltips are not shown during combat
