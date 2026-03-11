## ADDED Requirements

### Requirement: Source group headers open Adventure Guide when clicked

The addon SHALL make source group headers in the Objective Tracker clickable when the group represents a known dungeon or raid with a valid instance ID. Clicking such a header SHALL open the Adventure Guide to that dungeon or raid.

#### Scenario: Click dungeon group header opens Adventure Guide

- **WHEN** the user clicks the left mouse button on a source group header in the Loot Wishlist section and the group has a valid instance ID and is not the "Other" group
- **THEN** the Adventure Guide opens and displays the corresponding dungeon

#### Scenario: Click raid group header opens Adventure Guide

- **WHEN** the user clicks the left mouse button on a source group header in the Loot Wishlist section and the group has a valid instance ID and is not the "Other" group
- **THEN** the Adventure Guide opens and displays the corresponding raid

#### Scenario: Click Other group header does nothing

- **WHEN** the user clicks on the "Other" group header in the Loot Wishlist section
- **THEN** nothing happens - the Adventure Guide is not opened

#### Scenario: Click group without valid instance ID does nothing

- **WHEN** the user clicks on a source group header that has no valid instance ID (e.g., legacy tracked items)
- **THEN** nothing happens - the Adventure Guide is not opened

#### Scenario: Collapse button click is unchanged

- **WHEN** the user clicks the collapse/expand button (plus/minus) on a source group header
- **THEN** the group's collapse state toggles as before, and the Adventure Guide is not opened
