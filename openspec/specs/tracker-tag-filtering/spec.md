## Purpose

Define tracker-specific tag filtering controls, persisted presentation behavior, and tag-aware tooltip footer rendering.

## Requirements

### Requirement: Wishlist tracker header exposes a tag filter button
The system SHALL display a tag filter button in the wishlist tracker header between the attach or detach control and the grouping control. The button SHALL use `UI-QuestTrackerButton-Filter` as its normal atlas, `UI-QuestTrackerButton-Filter-Pressed` as its pressed atlas, and `UI-QuestTrackerButton-Red-Highlight` as its highlight atlas.

#### Scenario: Tracker header shows filter button with the expected atlases
- **WHEN** the wishlist tracker header renders while more than one tag exists in the addon
- **THEN** the tracker header shows a tag filter button between the attach or detach control and the grouping control
- **AND** the button uses the requested normal, pressed, and highlight atlases

### Requirement: Filter button is disabled when filtering would be meaningless
When only one tag exists in the addon, the system SHALL tint the tracker filter button grey, disable its click interaction, and prevent the filter menu from opening.

#### Scenario: Single tag disables the filter button
- **WHEN** only one tag exists in the addon's tag catalog
- **THEN** the tracker tints the filter button grey
- **AND** the user cannot click it to open the filter menu

### Requirement: Tracker filter menu shows only used tags and applies OR matching
The tracker filter menu SHALL list only tags currently assigned to at least one wishlist item. Each listed tag SHALL have a checkbox. Selecting multiple tags SHALL show items that carry any selected tag. No selected tags SHALL show all wishlist items, and selecting every available filter tag SHALL behave the same as selecting none. The tracker SHALL persist the current filter selection per character so the same selection is restored after reloads or relogs until it is changed or pruned.

#### Scenario: Filter menu excludes unused tags
- **WHEN** the user opens the tracker filter menu
- **THEN** the menu lists only tags currently used by at least one wishlist item

#### Scenario: Multiple selected tags use OR filtering
- **WHEN** the user selects multiple tags in the tracker filter menu
- **THEN** the tracker shows wishlist items that have any of those selected tags

#### Scenario: Empty selection shows all items
- **WHEN** the tracker filter menu has no selected tags
- **THEN** the tracker shows all wishlist items

#### Scenario: All selected tags behave like no selection
- **WHEN** the tracker filter menu has every available filter tag selected
- **THEN** the tracker shows the same item set as it would with no selected tags

#### Scenario: Filter selection is restored after reload
- **WHEN** the player selects one or more tracker filter tags and later reloads the UI or logs back in on the same character
- **THEN** the tracker restores that character's previously selected filter tags

### Requirement: Tracker filter state remains presentation-only and self-healing
The tracker tag filter SHALL affect only which wishlist items are visible in the tracker. It SHALL NOT change wishlist membership, tag assignments, loot alert triggering, or loot roll badge presence. The selected filter state MAY be persisted per character, but that persisted state SHALL remain tracker-local presentation data only. If a selected filter tag is deleted or becomes unused, the system SHALL automatically remove that stale selection from the tracker filter state, and if no selections remain the tracker SHALL revert to showing all wishlist items.

#### Scenario: Filtering does not change underlying tracked membership
- **WHEN** the user filters the tracker to a subset of wishlist tags
- **THEN** items hidden by that filter remain tracked wishlist items with their existing tag assignments unchanged

#### Scenario: Stale filter tag is pruned automatically
- **WHEN** a currently selected tracker filter tag is later deleted or no longer used by any wishlist item
- **THEN** the system removes that stale tag from the active tracker filter selection

#### Scenario: Pruning all stale selections restores show-all behavior
- **WHEN** every currently selected tracker filter tag becomes stale and is pruned
- **THEN** the tracker reverts to an empty filter selection
- **AND** the tracker shows all wishlist items

#### Scenario: Persisted filtering does not change underlying tracked membership
- **WHEN** the tracker restores a persisted filter selection for the active character
- **THEN** items hidden by that restored selection remain tracked wishlist items with their existing tag assignments unchanged
- **AND** loot alerts and loot roll badges remain unaffected by that restored filter selection

### Requirement: Tracker item tooltips show assigned tags in the footer
Tracker item tooltips SHALL append a wishlist footer line using the favorite atlas and the item's assigned tags joined by comma and space. In source-grouped mode, the tooltip SHALL append only that tags line. In equipment-slot-grouped mode, the tooltip SHALL append the tags line above the existing source footer line.

#### Scenario: Source-grouped tooltip shows only the tags footer line
- **WHEN** the user hovers a tracker item while the active tracker grouping mode is loot source
- **THEN** the tooltip appends one wishlist footer line containing the favorite atlas and the item's assigned tags

#### Scenario: Slot-grouped tooltip shows tags above source
- **WHEN** the user hovers a tracker item while the active tracker grouping mode is equipment slot
- **THEN** the tooltip appends the tags footer line above the existing source footer line
