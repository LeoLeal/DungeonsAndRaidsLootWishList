## ADDED Requirements

### Requirement: Source groups are collapsible
The wishlist tracker SHALL allow each source group (dungeon, raid, Other) to be collapsed or expanded independently.

#### Scenario: Collapse a group
- **WHEN** the user clicks the collapse button on a source group header
- **THEN** the group's items are hidden from view
- **AND** the collapse button changes to expand button (showing +)
- **AND** the group header displays the item count in parentheses

#### Scenario: Expand a group
- **WHEN** the user clicks the expand button on a collapsed source group header
- **THEN** the group's items are displayed
- **AND** the expand button changes to collapse button (showing −)
- **AND** the group header displays just the group name without item count

#### Scenario: Collapse state persists across sessions
- **WHEN** the user collapses a group and relogs or reloads the UI
- **THEN** the group remains collapsed in the same state

#### Scenario: New group appears in collapsed state
- **WHEN** a user tracks a new item from a source that is not currently displayed
- **AND** that source group label exists in the collapsed groups set
- **THEN** the new group appears in collapsed state with item count

#### Scenario: New group appears in expanded state
- **WHEN** a user tracks a new item from a source that is not currently displayed
- **AND** that source group label does NOT exist in the collapsed groups set
- **THEN** the new group appears in expanded state (default)

### Requirement: Item count displays for collapsed groups
When a source group is collapsed, the group header SHALL display the number of items in that group.

#### Scenario: Collapsed group shows count
- **GIVEN** a source group with 3 tracked items is collapsed
- **WHEN** the group is rendered
- **THEN** the header displays as "Group Name (3)"

#### Scenario: Collapsed group count updates when items change
- **GIVEN** a source group is collapsed showing "(2)"
- **WHEN** the user tracks an additional item from that source
- **THEN** the header updates to show "(3)"

#### Scenario: Collapsed group with zero items is hidden
- **GIVEN** a source group is collapsed
- **WHEN** all items in that group are untracked (group becomes empty)
- **THEN** the group is hidden entirely (same as existing behavior for empty groups)

### Requirement: Collapse button uses native visual style
The collapse/expand buttons SHALL match the visual style of native WoW Objective Tracker buttons.

#### Scenario: Button uses native atlases
- **WHEN** the collapse button is rendered
- **THEN** it uses atlas "ui-questtrackerbutton-secondary-collapse" for normal state
- **AND** uses atlas "ui-questtrackerbutton-secondary-collapse-pressed" for pushed state

#### Scenario: Expand button uses native atlases
- **WHEN** the expand button is rendered
- **THEN** it uses atlas "ui-questtrackerbutton-secondary-expand" for normal state
- **AND** uses atlas "ui-questtrackerbutton-secondary-expand-pressed" for pushed state

#### Scenario: Button is positioned at right edge of header
- **WHEN** the collapse/expand button is created
- **THEN** it is anchored to the right edge of the block header
- **AND** the group title text is positioned to the left of the button

### Requirement: Default state is expanded
Source groups SHALL default to expanded when the addon is first loaded for a character.

#### Scenario: Fresh load shows expanded groups
- **WHEN** the addon loads for a character with no persisted collapse state
- **THEN** all source groups are displayed in expanded state

#### Scenario: Empty groups remain hidden
- **WHEN** a source group has zero tracked items
- **THEN** the group is not displayed regardless of collapse state (existing behavior preserved)
