## Purpose

Define how tracked wishlist items are rendered in the Objective Tracker, including grouping, row presentation, and removal interactions.

## Requirements

### Requirement: Objective tracker shows a Loot Wishlist section

The addon SHALL display a `Loot Wishlist` section in the objective-tracker area whenever the active character has one or more tracked wishlist items. The section SHALL visually integrate with the native Objective Tracker and SHALL remain visible in that tracker area even when no quests, world quests, or other native objectives are currently tracked. The implementation SHALL NOT require direct registration through Blizzard's native Objective Tracker module manager. Tracker-owned modules SHALL remain the long-term owner of tracker frame creation, tracker rendering, tracker-specific grouping, tracker interaction, and possession-derived tracker presentation, while Core bootstrap code SHALL remain limited to initialization and top-level wiring.

#### Scenario: Tracker section appears when items are tracked

- **WHEN** the active character has one or more tracked wishlist items
- **THEN** the objective tracker shows a `Loot Wishlist` section containing those items

#### Scenario: Tracker section disappears when no items are tracked

- **WHEN** the active character has no tracked wishlist items
- **THEN** the objective tracker does not show the `Loot Wishlist` section

#### Scenario: Wishlist section remains visible with no other objectives

- **WHEN** the active character has tracked wishlist items but no quests, world quests, or other game objectives are being tracked
- **THEN** the `Loot Wishlist` section remains visible in the objective-tracker area

#### Scenario: Wishlist section respects tracker collapse

- **WHEN** the player explicitly collapses the tracker through the native tracker collapse control
- **THEN** the `Loot Wishlist` section is hidden along with the rest of the tracker presentation

#### Scenario: Tracker feature owns tracker-specific presentation behavior

- **WHEN** the addon builds and refreshes the `Loot Wishlist` section
- **THEN** Tracker-owned modules handle tracker rendering and tracker-specific derived behavior
- **AND** Core bootstrap code does not remain the owner of tracker presentation logic

### Requirement: Wishlist section appends naturally to native tracker content

When native Objective Tracker content is visible, the addon SHALL position the `Loot Wishlist` section immediately beneath the last visible native tracker section so the wishlist appears as a natural continuation of the tracker with no unintended blank gap between Blizzard-owned tracker content and the wishlist section. When no native tracker sections are visible and the addon displays its surrogate `All Objectives` header, the wishlist SHALL appear in the tracker area's normal top position. While that standalone surrogate-header presentation is visible, the wishlist SHALL remain correctly aligned across loading-screen and teleport transitions, regardless of whether the Objective Tracker is in its default managed position or has been moved through Edit Mode.

#### Scenario: Native tracker content is visible above the wishlist

- **WHEN** one or more native Objective Tracker sections are visible above the wishlist
- **THEN** the `Loot Wishlist` section appears immediately beneath the last visible native tracker section without an unintended blank gap

#### Scenario: Wishlist is the only visible tracker-area content

- **WHEN** the active character has tracked wishlist items and no native tracker sections are visible
- **AND** the addon displays its surrogate `All Objectives` header
- **THEN** the `Loot Wishlist` section appears at the tracker area's normal top position rather than leaving empty space for missing native sections

#### Scenario: Standalone tracker remains aligned after loading-screen transitions in default position

- **WHEN** the active character has tracked wishlist items, no native Objective Tracker sections are visible, the addon displays its surrogate `All Objectives` header, and the Objective Tracker is using its default managed position
- **AND** a loading-screen or teleport transition completes
- **THEN** the standalone `Loot Wishlist` presentation remains aligned to the tracker area's normal top position without horizontal or vertical drift

#### Scenario: Standalone tracker remains aligned after loading-screen transitions in moved position

- **WHEN** the active character has tracked wishlist items, no native Objective Tracker sections are visible, the addon displays its surrogate `All Objectives` header, and the Objective Tracker has been moved through Edit Mode
- **AND** a loading-screen or teleport transition completes
- **THEN** the standalone `Loot Wishlist` presentation remains aligned to the tracker area's normal top position without horizontal or vertical drift

#### Scenario: Native tracker collapse hides appended wishlist section

- **WHEN** the player collapses all objectives through the native Objective Tracker collapse control while the wishlist is visible
- **THEN** the `Loot Wishlist` section is hidden as part of that collapsed tracker presentation

### Requirement: Tracker items are grouped by loot source

The addon SHALL group tracked items in the objective tracker according to the active persisted tracker grouping mode. In `Loot Source` mode, the addon SHALL group tracked items by persisted loot-source metadata already stored on the wishlist entry, such as the dungeon or raid where the item drops. In `Equipment Slot` mode, the addon SHALL group tracked items by persisted stable equipment-slot metadata stored on the wishlist entry. Tracker grouping SHALL NOT depend on live Encounter Journal state during generic tracker rebuilds or post-loot refreshes. If the metadata required for the active grouping mode cannot be identified for a tracked item, the addon SHALL place that item under an `Other` group for that mode.

#### Scenario: Source mode groups item under stored source

- **WHEN** the active tracker grouping mode is `Loot Source`
- **AND** a tracked item has a stored dungeon or raid source on its wishlist entry
- **THEN** the objective tracker displays that item under a group named for that stored source

#### Scenario: Source mode falls back to Other when source is missing

- **WHEN** the active tracker grouping mode is `Loot Source`
- **AND** a tracked item does not have persisted loot-source metadata on its wishlist entry
- **THEN** the objective tracker displays that item under the `Other` group

#### Scenario: Slot mode groups item under stored equipment slot

- **WHEN** the active tracker grouping mode is `Equipment Slot`
- **AND** a tracked item has persisted equipment-slot metadata on its wishlist entry
- **THEN** the objective tracker displays that item under a group named for that equipment slot

#### Scenario: Slot mode falls back to Other when slot metadata is missing

- **WHEN** the active tracker grouping mode is `Equipment Slot`
- **AND** a tracked item does not have persisted equipment-slot metadata on its wishlist entry
- **THEN** the objective tracker displays that item under the `Other` group for slot grouping

#### Scenario: Tracker rebuild does not consult live Encounter Journal state for grouping

- **WHEN** the addon rebuilds tracker groups after loot, bag, bank, equipment, or combat-state updates
- **THEN** tracker grouping is computed without depending on live Encounter Journal selection or title state

### Requirement: Group headers do not open Adventure Guide loot view when clicked

The addon SHALL NOT open the Adventure Guide or Encounter Journal when the user clicks a group header in the `Loot Wishlist` section. Group headers in both `Loot Source` mode and `Equipment Slot` mode remain informational labels for grouping only. Clicking the group's collapse or expand button SHALL continue to affect only collapse state.

#### Scenario: Click source group header does not open Encounter Journal

- **WHEN** the user clicks the left mouse button on a source group header in `Loot Source` mode
- **THEN** the Adventure Guide or Encounter Journal is not opened

#### Scenario: Click slot group header does not open Encounter Journal

- **WHEN** the user clicks the left mouse button on an equipment-slot group header in `Equipment Slot` mode
- **THEN** the Adventure Guide or Encounter Journal is not opened

#### Scenario: Collapse button click still only changes collapse state

- **WHEN** the user clicks the collapse or expand button on a group header in either grouping mode
- **THEN** only the group's collapse state changes
- **AND** the Adventure Guide or Encounter Journal is not opened

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

### Requirement: Tracker rows support direct removal

The addon SHALL allow the user to remove a tracked item from the wishlist from the objective tracker by either Shift-clicking that item row or right-clicking that item row to open a context menu with only one action, `Remove`. The right-click remove menu SHALL be rendered on an isolated addon-owned menu surface and SHALL NOT depend on shared Blizzard context-menu or dropdown menu systems.

#### Scenario: Shift-click removes a tracked item

- **WHEN** the user Shift-clicks a tracked item in the `Loot Wishlist` section
- **THEN** the addon removes the item from the active character's wishlist and updates the tracker accordingly

#### Scenario: Right-click opens remove menu for a tracked item

- **WHEN** the user right-clicks a tracked item in the `Loot Wishlist` section
- **THEN** the addon opens a context menu for that row
- **AND** the menu contains only one action named `Remove`

#### Scenario: Remove menu uses isolated addon-owned surface

- **WHEN** the user right-clicks a tracked item in the `Loot Wishlist` section
- **THEN** the remove menu is shown from an addon-owned isolated popup surface
- **AND** the interaction does not require shared Blizzard context-menu or dropdown menu systems

#### Scenario: Remove menu action removes a tracked item

- **WHEN** the user activates `Remove` from a tracked item's right-click context menu in the `Loot Wishlist` section
- **THEN** the addon removes the item from the active character's wishlist and updates the tracker accordingly

#### Scenario: Group and boss headers do not show remove menu

- **WHEN** the user right-clicks a group header or boss subheader in the `Loot Wishlist` section
- **THEN** the addon does not open the tracked-item remove menu

### Requirement: Newly added tracker items mirror native tracker animation

When a tracked item is newly added to the `Loot Wishlist` section, the addon SHALL mirror the add-entry animation style used by the native objective tracker on the affected active group header. When a tracked item in a group newly transitions into the completed or possessed state, the addon SHALL mirror the native tracker-style header glow animation on that same active group header.

#### Scenario: Newly tracked item animates the active group header

- **WHEN** the user adds an item to the wishlist and it appears in the objective tracker for the first time
- **THEN** the active group header for that item plays a native objective-tracker style add animation

#### Scenario: Newly completed tracked item animates the active group header

- **WHEN** a tracked item in the active grouping mode newly gains the completed or possessed tracker state
- **THEN** the active group header for that item plays a native objective-tracker style completion glow animation

### Requirement: Tracker collapse controls play native checkbox-style sound feedback

The addon SHALL play the Blizzard menu checkbox-style sound when a user action changes the collapsed state of the surrogate tracker header, the `Loot Wishlist` header, or a tracker group header in the objective tracker.

#### Scenario: Surrogate header collapse plays sound

- **WHEN** the user clicks the surrogate tracker header to expand or collapse it
- **AND** that click changes the surrogate header's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

#### Scenario: Loot Wishlist header collapse plays sound

- **WHEN** the user clicks the `Loot Wishlist` header to expand or collapse it
- **AND** that click changes the header's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

#### Scenario: Group header collapse plays sound

- **WHEN** the user clicks a tracker group header collapse or expand control
- **AND** that click changes the group's collapsed state
- **THEN** the addon plays the Blizzard menu checkbox-style sound once

### Requirement: Tracker visuals prefer native Blizzard UI assets

The addon SHALL prefer Blizzard-provided UI assets and visual patterns for tracker presentation, including indicators and row styling, unless a native asset cannot express the required behavior.

#### Scenario: Tracker row is rendered

- **WHEN** the addon renders a wishlist row in the objective tracker
- **THEN** it uses native Blizzard visual patterns where practical instead of bespoke addon-specific visuals

### Requirement: Groups are collapsible

The wishlist tracker SHALL allow each visible group in the active grouping mode to be collapsed or expanded independently.

#### Scenario: Collapse a group in the active mode

- **WHEN** the user clicks the collapse button on a group header in the active grouping mode
- **THEN** the group's items are hidden from view
- **AND** the collapse button changes to expand button (showing +)
- **AND** the group header displays the item count in parentheses

#### Scenario: Expand a collapsed group in the active mode

- **WHEN** the user clicks the expand button on a collapsed group header in the active grouping mode
- **THEN** the group's items are displayed
- **AND** the expand button changes to collapse button (showing −)
- **AND** the group header displays just the group name without item count

#### Scenario: Collapse state persists across sessions for the active mode

- **WHEN** the user collapses a group and relogs or reloads the UI
- **THEN** the same group remains collapsed the next time that character views the tracker in that grouping mode

### Requirement: Adventure Guide wishlist checkboxes continue to track items

The addon SHALL continue to let the player add and remove wishlist items by clicking loot-row checkboxes in the Adventure Guide after grouping-mode, slot-metadata, and raid-detection changes are introduced.

#### Scenario: Clicking an unchecked loot-row checkbox adds the item

- **WHEN** the player clicks an unchecked wishlist checkbox on an Adventure Guide loot row
- **THEN** the item is added to the wishlist
- **AND** the tracker refreshes using the current grouping mode

#### Scenario: Clicking a checked loot-row checkbox removes the item

- **WHEN** the player clicks a checked wishlist checkbox on an Adventure Guide loot row
- **THEN** the item is removed from the wishlist
- **AND** the tracker refreshes using the current grouping mode

### Requirement: Item count displays for collapsed groups

When a group is collapsed in the active grouping mode, the group header SHALL display the number of tracked items in that group.

#### Scenario: Collapsed group shows count

- **GIVEN** a source group with 3 tracked items is collapsed
- **WHEN** the group is rendered
- **THEN** the header displays as "Group Name (3)"

### Requirement: Collapse button uses native visual style

The collapse/expand buttons SHALL match the visual style of native WoW Objective Tracker buttons.

#### Scenario: Button uses native atlases

- **WHEN** the collapse button is rendered
- **THEN** it uses atlas "ui-questtrackerbutton-secondary-collapse" for normal state
- **AND** uses atlas "ui-questtrackerbutton-secondary-collapse-pressed" for pushed state

#### Scenario: Button is positioned at right edge of header

- **WHEN** the collapse/expand button is created
- **THEN** it is anchored to the right edge of the block header
- **AND** the group title text is positioned to the left of the button
