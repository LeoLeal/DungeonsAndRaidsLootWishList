## Why

The LootWishList addon has taint issues related to:
1. Using `SetScript` instead of `HookScript` on frames that may have secure handlers
2. Operations that can fire during combat without proper protection
3. Non-critical refreshes that should be deferred during combat

These issues can cause taint-related errors and UI breakage during combat.

## What Changes

1. **TrackerUI.lua - Collapse Button**: Keep SetScript (custom button, not from secure template)
2. **AdventureGuideUI.lua - Checkbox**: Change `SetScript` to `HookScript` for checkbox OnClick handler
3. **Add InCombatLockdown() checks**: Add combat protection for event handlers that modify UI
4. **Queue operations after combat**: Queue operations to execute after leaving combat using C_Timer
5. **Defer non-critical refreshes**: Skip or defer non-critical refresh operations during combat
6. **Prevent tooltips during combat**: Skip showing tooltips when player is in combat

## Capabilities

### Modified Capabilities
- `wishlist-tracker-display`: Add InCombatLockdown protection for UI operations
- `adventure-guide-wishlist-toggle`: Change SetScript to HookScript, add combat protection

## Impact

- **Files Modified**: TrackerUI.lua, AdventureGuideUI.lua, LootWishList.lua
- **No breaking changes**: All changes are internal implementation fixes
- **Risk Reduction**: Eliminates taint and combat-related issues
