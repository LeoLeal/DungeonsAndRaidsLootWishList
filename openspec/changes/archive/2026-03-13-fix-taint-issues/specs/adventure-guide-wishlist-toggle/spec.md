## MODIFIED Requirements

### Requirement: Adventure Guide loot rows can toggle wishlist membership

The addon SHALL add a wishlist toggle control to dungeon and raid loot rows shown in the Adventure Guide. The control SHALL reflect whether the corresponding item is currently tracked for the active character and SHALL allow the user to add or remove the item from the character-specific wishlist.

#### Scenario: Add an item from the Adventure Guide

- **WHEN** the user checks the wishlist control for an untracked Adventure Guide loot item
- **THEN** the addon adds that item to the active character's wishlist and the control displays the tracked state

#### Scenario: Remove an item from the Adventure Guide

- **WHEN** the user unchecks the wishlist control for a tracked Adventure Guide loot item
- **THEN** the addon removes that item from the active character's wishlist and the control displays the untracked state

### Requirement: Checkbox uses HookScript instead of SetScript

When adding click handlers to the wishlist toggle checkbox in the Adventure Guide, the addon SHALL use HookScript rather than SetScript to avoid replacing template handlers and introducing taint.

#### Scenario: Checkbox OnClick handler
- **WHEN** the addon creates a wishlist toggle checkbox in the Adventure Guide
- **THEN** the addon uses `checkbox:HookScript("OnClick", handler)` instead of `checkbox:SetScript("OnClick", handler)`

### Requirement: Event handlers must check InCombatLockdown before modifying UI

When event handlers related to the Adventure Guide fire during combat, the addon SHALL check `InCombatLockdown()` before executing operations that could be forbidden during combat.

#### Scenario: Adventure Guide refresh during combat
- **WHEN** an event that triggers an Adventure Guide refresh fires while the player is in combat
- **THEN** the addon checks `InCombatLockdown()` before executing the refresh
- **AND** if in combat, defers the UI update until after combat ends
