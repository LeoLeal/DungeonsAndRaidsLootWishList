## ADDED Requirements

### Requirement: Wishlist tracker can detach from the Objective Tracker
The addon SHALL allow the player to switch the `Loot Wishlist` tracker between its default attached Objective Tracker presentation and a detached movable presentation. The attach or detach toggle SHALL be exposed on the `Loot Wishlist` header. In detached mode, the tracker SHALL render as a single surrogate-style header labeled `Loot Wishlist`, remain movable while unlocked, and continue to show tracked items independently of native Objective Tracker collapse or hiding. When reattached, the tracker SHALL return to its Objective Tracker-attached presentation and resume native tracker layout behavior.

#### Scenario: Player detaches the attached wishlist tracker
- **WHEN** the player clicks the attach or detach control while the `Loot Wishlist` tracker is attached
- **THEN** the tracker leaves the Objective Tracker layout and becomes a movable detached frame
- **AND** the detached frame shows a single surrogate-style header labeled `Loot Wishlist`

#### Scenario: Detached tracker stays visible when native tracker collapses
- **WHEN** the `Loot Wishlist` tracker is detached
- **AND** the player collapses or hides the native Objective Tracker
- **THEN** the detached `Loot Wishlist` tracker remains visible

#### Scenario: Player reattaches the detached wishlist tracker
- **WHEN** the player clicks the attach or detach control while the `Loot Wishlist` tracker is detached
- **THEN** the tracker returns to its Objective Tracker-attached presentation
- **AND** the wishlist again follows native tracker layout behavior

### Requirement: Detached header can collapse and expand detached content
When the `Loot Wishlist` tracker is detached, its single surrogate-style header SHALL be able to collapse and expand the detached tracker content without reattaching the tracker. Clicking the detached header row or its collapse or expand control SHALL toggle the detached content visibility using the same detached-header presentation.

#### Scenario: Detached header collapses its content
- **WHEN** the `Loot Wishlist` tracker is detached and expanded
- **AND** the user clicks the detached header row or its collapse control
- **THEN** the detached tracker content is collapsed under that detached header

#### Scenario: Detached header expands its content
- **WHEN** the `Loot Wishlist` tracker is detached and collapsed
- **AND** the user clicks the detached header row or its expand control
- **THEN** the detached tracker content is shown again under that detached header

### Requirement: Detached header exposes atlas-based lock-state movement control
When the `Loot Wishlist` tracker is detached, its header SHALL show an addon-owned atlas control between the grouping-mode control and the attach or detach control that toggles whether the detached tracker can be moved. The control SHALL use atlas `AdventureMapIcon-Lock` at full brightness while the detached tracker is currently locked and SHALL use the same atlas in a darkened presentation while the detached tracker is currently unlocked.

#### Scenario: Unlocked detached header shows darkened lock atlas
- **WHEN** the `Loot Wishlist` tracker is detached and currently unlocked
- **THEN** the detached header shows a darkened `AdventureMapIcon-Lock` control between the grouping-mode control and the attach or detach button

#### Scenario: Clicking darkened lock atlas prevents detached movement
- **WHEN** the `Loot Wishlist` tracker is detached and currently unlocked
- **AND** the user clicks the detached header's darkened `AdventureMapIcon-Lock` control
- **THEN** the detached tracker becomes locked against movement
- **AND** the control changes to the full-brightness `AdventureMapIcon-Lock` presentation

#### Scenario: Clicking bright lock atlas restores detached movement
- **WHEN** the `Loot Wishlist` tracker is detached and currently locked
- **AND** the user clicks the detached header's full-brightness `AdventureMapIcon-Lock` control
- **THEN** the detached tracker becomes movable again
- **AND** the control changes to the darkened `AdventureMapIcon-Lock` presentation

### Requirement: Attach or detach control uses native red-button visuals
The addon SHALL render an addon-owned attach or detach control on the `Loot Wishlist` header as part of the right-side control cluster. While the tracker is attached, the control SHALL use atlas `RedButton-Expand` for its normal state and `RedButton-Expand-Pressed` for its pushed state. While the tracker is detached, the control SHALL use atlas `RedButton-Condense` for its normal state and `RedButton-Condense-Pressed` for its pushed state.

#### Scenario: Attached tracker shows expand atlas on the control
- **WHEN** the `Loot Wishlist` tracker header is rendered while the tracker is attached
- **THEN** the attach or detach control uses atlas `RedButton-Expand` for its normal state
- **AND** uses atlas `RedButton-Expand-Pressed` for its pushed state

#### Scenario: Detached tracker shows condense atlas on the control
- **WHEN** the `Loot Wishlist` tracker header is rendered while the tracker is detached
- **THEN** the attach or detach control uses atlas `RedButton-Condense` for its normal state
- **AND** uses atlas `RedButton-Condense-Pressed` for its pushed state

#### Scenario: Attach or detach control sits between lock-state control and collapse controls
- **WHEN** the `Loot Wishlist` header is rendered
- **THEN** the attach or detach control appears between the lock-state control and the collapse or expand button

#### Scenario: Detached controls keep a stable order
- **WHEN** the `Loot Wishlist` tracker is detached
- **THEN** the right-side detached header controls appear in the order `Grouping`, `Lock State`, `Attach/Detach`, `Collapse/Expand`

## MODIFIED Requirements

### Requirement: Objective tracker shows a Loot Wishlist section
The addon SHALL display a `Loot Wishlist` tracker whenever the active character has one or more tracked wishlist items. By default the tracker SHALL appear attached in the objective-tracker area, visually integrated with the native Objective Tracker, and SHALL remain visible there even when no quests, world quests, or other native objectives are currently tracked. The player SHALL be able to switch that same tracker into a detached movable presentation that is no longer anchored inside the objective-tracker area. The implementation SHALL NOT require direct registration through Blizzard's native Objective Tracker module manager. Tracker-owned modules SHALL remain the long-term owner of tracker frame creation, tracker rendering, tracker-specific grouping, tracker interaction, and possession-derived tracker presentation, while Core bootstrap code SHALL remain limited to initialization and top-level wiring.

#### Scenario: Attached tracker section appears when items are tracked
- **WHEN** the active character has one or more tracked wishlist items
- **AND** that character's saved tracker attachment mode is attached
- **THEN** the objective tracker shows a `Loot Wishlist` section containing those items

#### Scenario: Detached tracker appears when items are tracked
- **WHEN** the active character has one or more tracked wishlist items
- **AND** that character's saved tracker attachment mode is detached
- **THEN** the addon shows the `Loot Wishlist` tracker as a detached movable frame instead of as an Objective Tracker-attached section

#### Scenario: Tracker section disappears when no items are tracked
- **WHEN** the active character has no tracked wishlist items
- **THEN** the addon does not show the `Loot Wishlist` tracker in either attached or detached presentation

#### Scenario: Attached wishlist section remains visible with no other objectives
- **WHEN** the active character has tracked wishlist items, that character's saved tracker attachment mode is attached, and no quests, world quests, or other game objectives are being tracked
- **THEN** the `Loot Wishlist` tracker remains visible in the objective-tracker area

#### Scenario: Attached wishlist section respects native tracker collapse
- **WHEN** the player explicitly collapses the native Objective Tracker through its collapse control while the `Loot Wishlist` tracker is attached
- **THEN** the attached `Loot Wishlist` tracker is hidden along with the rest of the tracker presentation

#### Scenario: Tracker feature owns tracker-specific presentation behavior
- **WHEN** the addon builds and refreshes the `Loot Wishlist` tracker
- **THEN** Tracker-owned modules handle tracker rendering and tracker-specific derived behavior
- **AND** Core bootstrap code does not remain the owner of tracker presentation logic

### Requirement: Wishlist section appends naturally to native tracker content
When the `Loot Wishlist` tracker is attached and native Objective Tracker content is visible, the addon SHALL position the `Loot Wishlist` section immediately beneath the last visible native tracker section so the wishlist appears as a natural continuation of the tracker with no unintended blank gap between Blizzard-owned tracker content and the wishlist section. When the attached tracker has tracked items but no native tracker sections are visible, the addon SHALL display its surrogate `All Objectives` header and position the wishlist at the tracker area's normal top position. While that attached standalone surrogate-header presentation is visible, the wishlist SHALL remain correctly aligned across loading-screen and teleport transitions, regardless of whether the Objective Tracker is in its default managed position or has been moved through Edit Mode. These Objective Tracker anchoring requirements SHALL apply only while the wishlist is attached; detached mode SHALL instead use its persisted movable placement.

#### Scenario: Native tracker content is visible above the attached wishlist
- **WHEN** one or more native Objective Tracker sections are visible above the `Loot Wishlist` tracker while it is attached
- **THEN** the `Loot Wishlist` section appears immediately beneath the last visible native tracker section without an unintended blank gap

#### Scenario: Attached wishlist is the only visible tracker-area content
- **WHEN** the active character has tracked wishlist items, the `Loot Wishlist` tracker is attached, no native tracker sections are visible, and the addon displays its surrogate `All Objectives` header
- **THEN** the `Loot Wishlist` section appears at the tracker area's normal top position rather than leaving empty space for missing native sections

#### Scenario: Attached standalone tracker remains aligned after loading-screen transitions in default position
- **WHEN** the active character has tracked wishlist items, the `Loot Wishlist` tracker is attached, no native Objective Tracker sections are visible, the addon displays its surrogate `All Objectives` header, and the Objective Tracker is using its default managed position
- **AND** a loading-screen or teleport transition completes
- **THEN** the attached standalone `Loot Wishlist` presentation remains aligned to the tracker area's normal top position without horizontal or vertical drift

#### Scenario: Attached standalone tracker remains aligned after loading-screen transitions in moved position
- **WHEN** the active character has tracked wishlist items, the `Loot Wishlist` tracker is attached, no native Objective Tracker sections are visible, the addon displays its surrogate `All Objectives` header, and the Objective Tracker has been moved through Edit Mode
- **AND** a loading-screen or teleport transition completes
- **THEN** the attached standalone `Loot Wishlist` presentation remains aligned to the tracker area's normal top position without horizontal or vertical drift

#### Scenario: Native tracker collapse hides attached wishlist section
- **WHEN** the player collapses all objectives through the native Objective Tracker collapse control while the wishlist is attached
- **THEN** the attached `Loot Wishlist` section is hidden as part of that collapsed tracker presentation

### Requirement: Group headers do not open Adventure Guide loot view when clicked
The addon SHALL NOT open the Adventure Guide or Encounter Journal when the user clicks a group header in the `Loot Wishlist` section. Group headers in both `Loot Source` mode and `Equipment Slot` mode remain collapse-only interaction surfaces for grouping. Clicking either the group header row or the group's collapse or expand button SHALL only change that group's collapse state.

#### Scenario: Click source group header row only toggles collapse
- **WHEN** the user clicks the left mouse button on a source group header row in `Loot Source` mode
- **THEN** only that group's collapse state changes
- **AND** the Adventure Guide or Encounter Journal is not opened

#### Scenario: Click slot group header row only toggles collapse
- **WHEN** the user clicks the left mouse button on an equipment-slot group header row in `Equipment Slot` mode
- **THEN** only that group's collapse state changes
- **AND** the Adventure Guide or Encounter Journal is not opened

#### Scenario: Collapse button click still only changes collapse state
- **WHEN** the user clicks the collapse or expand button on a group header in either grouping mode
- **THEN** only that group's collapse state changes
- **AND** the Adventure Guide or Encounter Journal is not opened

### Requirement: Tracker collapse controls play native checkbox-style sound feedback
The addon SHALL play the Blizzard menu checkbox-style sound when a user action changes the collapsed state of the surrogate tracker header, any `Loot Wishlist` header presentation, or a tracker group header in the objective tracker.

#### Scenario: Surrogate header collapse plays sound
- **WHEN** the user clicks the surrogate tracker header to expand or collapse it
- **AND** that click changes the surrogate header's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

#### Scenario: Loot Wishlist header collapse plays sound
- **WHEN** the user clicks the `Loot Wishlist` header in either attached or detached presentation to expand or collapse it
- **AND** that click changes the header's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

#### Scenario: Group header collapse plays sound
- **WHEN** the user clicks a tracker group header row or its collapse or expand control
- **AND** that click changes the group's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

### Requirement: Groups are collapsible
The wishlist tracker SHALL allow each visible group in the active grouping mode to be collapsed or expanded independently.

#### Scenario: Collapse a group in the active mode
- **WHEN** the user clicks either the group header row or the collapse button on a group header in the active grouping mode
- **THEN** the group's items are hidden from view
- **AND** the collapse button changes to expand button (showing +)
- **AND** the group header displays the item count in parentheses

#### Scenario: Expand a collapsed group in the active mode
- **WHEN** the user clicks either the group header row or the expand button on a collapsed group header in the active grouping mode
- **THEN** the group's items are displayed
- **AND** the expand button changes to collapse button (showing −)
- **AND** the group header displays just the group name without item count

#### Scenario: Collapse state persists across sessions for the active mode
- **WHEN** the user collapses a group and relogs or reloads the UI
- **THEN** the same group remains collapsed the next time that character views the tracker in that grouping mode
