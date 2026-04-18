## MODIFIED Requirements

### Requirement: Adventure Guide loot rows use a favorite icon for wishlist tags

The system SHALL replace Adventure Guide wishlist checkboxes with a favorite icon control with background ring. The control SHALL use `delves-scenario-heart-icon` with grey tint when the item has no assigned tags and white when the item has one or more assigned tags, surrounded by a background ring using `pvpqueue-rewardring-black` or `pvpqueue-rewardring` depending on state. For every visual state rendered by that control, including tracked idle, untracked idle, and pressed interaction states, the background ring SHALL use the same opacity as the foreground favorite icon.

#### Scenario: Untracked loot row shows the off favorite icon with matched opacity
- **WHEN** the Adventure Guide renders a loot row for an item with no assigned wishlist tags
- **THEN** the row shows the `delves-scenario-heart-icon` atlas with black tint on a darker background ring
- **AND** the foreground icon and background ring use the same reduced opacity for that untracked state

#### Scenario: Tagged loot row shows the on favorite icon with matched opacity
- **WHEN** the Adventure Guide renders a loot row for an item with one or more assigned wishlist tags
- **THEN** the row shows the `delves-scenario-heart-icon` atlas with white color on an active background ring
- **AND** the foreground icon and background ring use the same opacity for that tracked state

#### Scenario: Favorite button press preserves matched opacity
- **WHEN** the user presses or releases the Adventure Guide favorite icon for a loot row
- **THEN** the foreground icon and background ring remain synchronized to the same opacity for the active interaction state
