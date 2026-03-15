## MODIFIED Requirements

### Requirement: Objective tracker shows a Loot Wishlist section

The addon SHALL display a `Loot Wishlist` section in the objective-tracker area whenever the active character has one or more tracked wishlist items. The section SHALL visually integrate with the native Objective Tracker and SHALL remain visible in that tracker area even when no quests, world quests, or other native objectives are currently tracked. The implementation SHALL NOT require direct registration through Blizzard's native Objective Tracker module manager.

#### Scenario: Tracker section appears when items are tracked

- **WHEN** the active character has one or more tracked wishlist items
- **THEN** the objective-tracker area shows a `Loot Wishlist` section containing those items

#### Scenario: Tracker section disappears when no items are tracked

- **WHEN** the active character has no tracked wishlist items
- **THEN** the `Loot Wishlist` section does not appear in the objective-tracker area

#### Scenario: Wishlist section remains visible with no other objectives

- **WHEN** the active character has tracked wishlist items but no quests, world quests, or other game objectives are being tracked
- **THEN** the `Loot Wishlist` section remains visible in the objective-tracker area

#### Scenario: Wishlist section respects tracker collapse

- **WHEN** the player explicitly collapses the tracker through the native tracker collapse control
- **THEN** the `Loot Wishlist` section is hidden along with the rest of the tracker presentation

### Requirement: Wishlist section appends naturally to native tracker content

When native Objective Tracker content is visible, the addon SHALL position the `Loot Wishlist` section immediately beneath the last visible native tracker section so the wishlist appears as a natural continuation of the tracker with no unintended blank gap between Blizzard-owned tracker content and the wishlist section. When no native tracker sections are visible, the wishlist SHALL appear in the tracker area's normal top position.

#### Scenario: Native tracker content is visible above the wishlist

- **WHEN** one or more native Objective Tracker sections are visible above the wishlist
- **THEN** the `Loot Wishlist` section appears immediately beneath the last visible native tracker section without an unintended blank gap

#### Scenario: Wishlist is the only visible tracker-area content

- **WHEN** the active character has tracked wishlist items and no native tracker sections are visible
- **THEN** the `Loot Wishlist` section appears at the tracker area's normal top position rather than leaving empty space for missing native sections

#### Scenario: Native tracker collapse hides appended wishlist section

- **WHEN** the player collapses all objectives through the native Objective Tracker collapse control while the wishlist is visible
- **THEN** the `Loot Wishlist` section is hidden as part of that collapsed tracker presentation

### Requirement: Source group headers open Adventure Guide loot view when clicked

The addon SHALL make source group headers in the `Loot Wishlist` section clickable when the group represents a known dungeon or raid with a valid instance ID. Clicking such a header SHALL open the Adventure Guide to the corresponding dungeon or raid and SHALL present that instance in its loot context. Clicking the group's collapse or expand button SHALL continue to affect only collapse state and SHALL NOT open the Adventure Guide.

#### Scenario: Click dungeon group header opens Adventure Guide loot view

- **WHEN** the user clicks the left mouse button on a dungeon source group header in the `Loot Wishlist` section and the group has a valid instance ID
- **THEN** the Adventure Guide opens to the corresponding dungeon in its loot context

#### Scenario: Click raid group header opens Adventure Guide loot view

- **WHEN** the user clicks the left mouse button on a raid source group header in the `Loot Wishlist` section and the group has a valid instance ID
- **THEN** the Adventure Guide opens to the corresponding raid in its loot context

#### Scenario: Click Other group header does nothing

- **WHEN** the user clicks the `Other` source group header in the `Loot Wishlist` section
- **THEN** the Adventure Guide is not opened

#### Scenario: Click group without valid instance ID does nothing

- **WHEN** the user clicks a source group header that does not have a valid instance ID
- **THEN** the Adventure Guide is not opened

#### Scenario: Collapse button click does not trigger Adventure Guide navigation

- **WHEN** the user clicks the collapse or expand button on a source group header
- **THEN** only the group's collapse state changes
- **AND** the Adventure Guide is not opened

### Requirement: Tracker rows show current possession and best looted item level separately

The addon SHALL show a green tick for a tracked item only when the active character currently possesses any version of that item in equipped slots, bags, or bank when bank data is known. The addon SHALL append the highest remembered looted item level in parentheses when that value is known, even if the item is not currently possessed. If the item's source is identified as a raid, the addon SHALL organize items hierarchically by boss: each boss appears as a gray section header followed by items belonging to that boss, sorted by encounter order within the raid. Items display the item name and item level (if known) without the boss name inline. Hovering a tracked item row SHALL show the standard Blizzard item tooltip for that row anchored near the hovered row, with Blizzard-native item content and no addon-specific tooltip lines. Wishlist tracker row hover SHALL use a tooltip surface isolated from shared Blizzard tooltip state so hovering wishlist rows does not interfere with Blizzard tooltip flows elsewhere. When a best owned item link is available, the tracker row SHALL use that link for display styling instead of an older tracked journal link.

#### Scenario: Tracked item is currently possessed

- **WHEN** the active character currently has any version of a tracked item equipped, in bags, or in known bank contents
- **THEN** the objective tracker row shows a green tick for that item

#### Scenario: Tracked item is no longer possessed

- **WHEN** the active character no longer has any version of a tracked item equipped, in bags, or in known bank contents
- **THEN** the objective tracker row does not show the green tick for that item

#### Scenario: Best looted item level remains after the item is gone

- **WHEN** the addon knows the highest looted item level for a tracked item but the character does not currently possess the item
- **THEN** the objective tracker still shows the item level in parentheses without the green tick

#### Scenario: Best owned version controls row styling

- **WHEN** the character owns a higher-quality or otherwise better version of a tracked item than the originally tracked journal link
- **THEN** the tracker row uses the best owned item link for display styling so row quality color matches the best known owned version

#### Scenario: Hover tracked item row shows isolated Blizzard-native tooltip

- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section and the addon can resolve that item
- **THEN** the row shows the standard Blizzard item tooltip anchored near that row without addon-specific tooltip text

#### Scenario: Wishlist tracker hover does not break later Blizzard tooltips

- **WHEN** the user hovers a tracked item row and then hovers a Blizzard-owned item surface such as an Encounter Journal loot row
- **THEN** the Blizzard-owned surface still shows its normal tooltip behavior

#### Scenario: Tracked items from a raid are grouped by boss

- **WHEN** the addon resolves tracked items' source as a raid and successfully determines encounter boss names
- **THEN** the objective tracker displays a gray section header for each boss followed by items belonging to that boss, sorted by encounter order (e.g., Boss A header -> items from Boss A, Boss B header -> items from Boss B)

#### Scenario: Tracked item from a dungeon does not show boss header

- **WHEN** the addon resolves a tracked item's source as a dungeon (not a raid)
- **THEN** the objective tracker displays items in a flat list without boss headers, showing only the item name and item level
