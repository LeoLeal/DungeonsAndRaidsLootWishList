## MODIFIED Requirements

### Requirement: Tracker rows show current possession and best looted item level separately

The addon SHALL show a green tick for a tracked item only when the active character currently possesses any version of that item in equipped slots, bags, or bank when bank data is known. Tracker item rows SHALL NOT append remembered item-level or item-track suffix text. In `Loot Source` mode, if the item's source is identified as a raid, the addon SHALL organize items hierarchically by boss: each boss appears as a gray section header followed by items belonging to that boss, sorted by encounter order within the raid. In `Equipment Slot` mode, the addon SHALL display items in a flat list within each slot group with no nested boss or source subheaders. Wishlist tracker row hover SHALL use a tooltip surface isolated from shared Blizzard tooltip state so hovering wishlist rows does not interfere with Blizzard tooltip flows elsewhere. The tracker SHALL render a fixed 5px vertical gap between adjacent top-level groups in the active grouping mode while keeping rows within the same top-level group, including raid boss headers and item rows, tightly stacked without that extra gap. The tracker row's effective display variant for styling and tooltip content SHALL prefer the best owned item link, then the persisted selected variant reference, then stable base-item fallback.

#### Scenario: Tracked item is currently possessed
- **WHEN** the active character currently has any version of a tracked item equipped, in bags, or in known bank contents
- **THEN** the objective tracker row shows a green tick for that item

#### Scenario: Tracked item is no longer possessed
- **WHEN** the active character no longer has any version of a tracked item equipped, in bags, or in known bank contents
- **THEN** the objective tracker row does not show the green tick for that item

#### Scenario: Tracker row omits item-level history text
- **WHEN** the addon renders a tracked item row
- **THEN** the row shows item identity and possession state only
- **AND** the row does not append remembered item-level or item-track suffix text

#### Scenario: Best owned version controls row styling
- **WHEN** the character owns a higher-quality or otherwise better version of a tracked item than the originally tracked journal variant
- **THEN** the tracker row uses the best owned item link for display styling so row quality color matches the best known owned version

#### Scenario: Selected variant controls unowned row styling
- **WHEN** the character does not currently own a tracked item
- **AND** the wishlist entry has a persisted selected variant reference
- **THEN** the tracker row uses that selected variant as the effective display variant for styling

#### Scenario: Hover tracked item row shows isolated Blizzard-native tooltip
- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section and the addon can resolve that item
- **THEN** the row shows the standard Blizzard item tooltip anchored near that row without addon-specific tooltip text

#### Scenario: Wishlist tracker hover does not break later Blizzard tooltips
- **WHEN** the user hovers a tracked item row and then hovers a Blizzard-owned item surface such as an Encounter Journal loot row
- **THEN** the Blizzard-owned surface still shows its normal tooltip behavior

#### Scenario: Source mode raid items are grouped by boss
- **WHEN** the active tracker grouping mode is `Loot Source`
- **AND** the addon resolves tracked items' source as a raid and successfully determines encounter boss names
- **THEN** the objective tracker displays a gray section header for each boss followed by items belonging to that boss, sorted by encounter order

#### Scenario: Source mode dungeon items stay flat within the source group
- **WHEN** the active tracker grouping mode is `Loot Source`
- **AND** the addon resolves a tracked item's source as a dungeon rather than a raid
- **THEN** the objective tracker displays items in a flat list within that source group without boss headers

#### Scenario: Slot mode items stay flat within the slot group
- **WHEN** the active tracker grouping mode is `Equipment Slot`
- **THEN** the objective tracker displays items in a flat list within each slot group without boss or source subheaders

#### Scenario: Source mode shows spacing between adjacent groups
- **WHEN** the active tracker grouping mode is `Loot Source`
- **AND** the tracker renders two or more top-level source groups
- **THEN** each adjacent pair of top-level source groups is separated by a 5px vertical gap

#### Scenario: Slot mode shows spacing between adjacent groups
- **WHEN** the active tracker grouping mode is `Equipment Slot`
- **AND** the tracker renders two or more top-level slot groups
- **THEN** each adjacent pair of top-level slot groups is separated by a 5px vertical gap

#### Scenario: Raid boss subsections remain tightly stacked within a group
- **WHEN** a top-level raid source group renders boss subheaders and item rows in the tracker
- **THEN** the boss subheaders and item rows within that same group remain tightly stacked without the 5px inter-group gap between them

#### Scenario: Collapsed group still separates from the next group
- **WHEN** a top-level group is collapsed and another top-level group is rendered after it
- **THEN** the collapsed group's rendered block is followed by the same 5px vertical gap before the next top-level group header
