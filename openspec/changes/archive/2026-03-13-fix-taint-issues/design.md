## Context

The LootWishList addon currently has taint issues related to:

1. **TrackerUI.lua - Collapse Button**: Uses `SetScript` instead of `HookScript` on a button that's a child of a secure Objective Tracker block
2. **AdventureGuideUI.lua - Checkbox**: Uses `SetScript` instead of `HookScript` on checkbox
3. **Event handlers fire during combat**: Operations like `RefreshAll()` are called from events that can fire during combat
4. **Non-critical refreshes during combat**: UI refreshes should be deferred when in combat

These patterns can cause taint to spread to secure Blizzard UI components and cause issues during combat.

## Goals / Non-Goals

**Goals:**
- Fix SetScript → HookScript conversions
- Add InCombatLockdown() protection for event-driven UI operations
- Queue operations to execute after combat
- Maintain all existing functionality and visual presentation
- Ensure compatibility with Blizzard's secure UI frameworks

**Non-Goals:**
- Add new features - purely bug fix focused
- Rewrite core addon logic
- Change data models or saved variable structures

## Decisions

### Decision 1: Collapse Button - Use HookScript instead of SetScript

**Current:** `button:SetScript("OnClick", function() ... end)`

**Proposed:** `button:HookScript("OnClick", function() ... end)`

**Rationale:** Using `HookScript` preserves any existing handlers from the secure template while adding our handler. This prevents the secure frame from becoming tainted.

### Decision 2: AdventureGuideUI Checkbox - Use HookScript

**Current:** `checkbox:SetScript("OnClick", function() ... end)`

**Proposed:** `checkbox:HookScript("OnClick", function() ... end)`

**Rationale:** Using HookScript instead of SetScript avoids replacing template handlers and reduces taint risk.

### Decision 3: InCombatLockdown() Protection for Event Handlers

**Current:** Event handlers like `CHAT_MSG_LOOT`, `START_LOOT_ROLL` call `RefreshAll()` directly

**Proposed:** Check `InCombatLockdown()` before executing UI-modifying operations

**Rationale:** Protected functions cannot be called during combat. Checking `InCombatLockdown()` prevents errors.

### Decision 4: Queue Operations After Combat

**Current:** Operations execute immediately regardless of combat state

**Proposed:** Use `C_Timer.After()` to queue operations after combat ends

```lua
local function QueueAfterCombat(callback)
  if InCombatLockdown() then
    C_Timer.After(1, function()
      if InCombatLockdown() then
        QueueAfterCombat(callback) -- keep waiting
      else
        callback()
      end
    end)
  else
    callback()
  end
end
```

**Rationale:** Ensures critical operations complete after the player leaves combat.

### Decision 5: Defer Non-Critical Refreshes

**Current:** All refreshes execute immediately

**Proposed:** Skip or defer non-critical refreshes during combat

**Rationale:** Non-critical UI updates (like checking possession state) can wait until after combat.

### Decision 6: Prevent Tooltips During Combat

**Current:** Tooltips show when hovering over tracker items regardless of combat state

**Proposed:** Check `InCombatLockdown()` in the OnEnter hook before showing tooltip

```lua
line:HookScript("OnEnter", function(self)
  if InCombatLockdown() then return end
  -- ... show tooltip
end)
```

**Rationale:** Showing tooltips during combat can interfere with combat UI and may cause taint issues.

## Risks / Trade-offs

**[Risk]** Some events may fire frequently during combat
→ **Mitigation:** Use throttling or skip non-critical updates

**[Risk]** Operations queued after combat may stack up
→ **Mitigation:** Use debouncing or single consolidated update

## Migration Plan

1. **Phase 1 - HookScript conversions:**
   - Change collapse button SetScript to HookScript
   - Change AdventureGuideUI checkbox SetScript to HookScript

2. **Phase 2 - InCombatLockdown protection:**
   - Add InCombatLockdown() checks to event handlers
   - Implement QueueAfterCombat utility function

3. **Phase 3 - Defer non-critical refreshes:**
   - Mark refreshes as critical or non-critical
   - Skip non-critical refreshes during combat

4. **Testing:**
   - Enable taint logging: `/console taintLog 1`
   - Test all functionality in and out of combat
   - Verify combat deferral works correctly

## Open Questions

- Should we use a single consolidated refresh after combat, or allow multiple?
- Should we add combat state tracking for more granular control?
