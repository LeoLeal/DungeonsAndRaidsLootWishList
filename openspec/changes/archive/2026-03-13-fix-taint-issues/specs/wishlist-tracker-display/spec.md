## MODIFIED Requirements

### Requirement: Objective tracker shows a Loot Wishlist section

The addon SHALL register a native ObjectiveTracker module using `ObjectiveTrackerModuleMixin` with the tracker manager. The module SHALL report content availability so that the tracker manager keeps the ObjectiveTrackerFrame visible whenever the active character has at least one tracked wishlist item, even if no other game objectives are being tracked. The section SHALL be labeled `Loot Wishlist`.

#### Scenario: Tracker section appears when items are tracked

- **WHEN** the active character has one or more tracked wishlist items
- **THEN** the objective tracker shows a `Loot Wishlist` section containing those items

#### Scenario: Tracker section disappears when no items are tracked

- **WHEN** the active character has no tracked wishlist items
- **THEN** the objective tracker does not show the `Loot Wishlist` section

#### Scenario: Wishlist section keeps tracker visible with no other objectives

- **WHEN** the active character has tracked wishlist items but no quests, world quests, or other game objectives are being tracked
- **THEN** the ObjectiveTrackerFrame remains visible and the `Loot Wishlist` section is displayed

#### Scenario: Wishlist section respects tracker collapse

- **WHEN** the player explicitly collapses the ObjectiveTrackerFrame
- **THEN** the `Loot Wishlist` section is hidden along with all other tracker sections

### Requirement: Collapse button uses SetScript

When adding click handlers to the collapse/expand button in the tracker section, the addon SHALL use SetScript since the button is a custom button created by the addon (not inherited from a secure template). HookScript requires an existing handler which custom buttons don't have.

#### Scenario: Collapse button OnClick handler
- **WHEN** the addon creates a collapse/expand button as a child of an Objective Tracker block
- **THEN** the addon uses `button:SetScript("OnClick", handler)`

### Requirement: Event handlers must check InCombatLockdown before modifying UI

When event handlers fire that may modify the Objective Tracker UI, the addon SHALL check `InCombatLockdown()` before executing operations that could be forbidden during combat.

#### Scenario: Tracker refresh during combat
- **WHEN** an event that triggers a tracker refresh fires while the player is in combat
- **THEN** the addon checks `InCombatLockdown()` before executing the refresh
- **AND** if in combat, queues the refresh to execute after combat ends

### Requirement: Tooltips must not show during combat

When hovering over tracker items, the addon SHALL check `InCombatLockdown()` before showing tooltips to prevent interfering with combat UI.

#### Scenario: Hover tooltip during combat
- **WHEN** the player hovers over a tracker item while in combat
- **THEN** the addon checks `InCombatLockdown()` before showing the tooltip
- **AND** if in combat, does not show the tooltip
