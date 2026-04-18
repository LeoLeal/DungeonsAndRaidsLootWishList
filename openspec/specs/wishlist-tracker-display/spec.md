## Purpose

Define how tracked wishlist items are rendered in the Objective Tracker, including grouping, row presentation, and removal interactions.
## Requirements
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

When the `Loot Wishlist` tracker is attached and native Objective Tracker content is visible, the addon SHALL position the `Loot Wishlist` section immediately beneath the last visible native tracker section so the wishlist appears as a natural continuation of the tracker with no unintended blank gap between Blizzard-owned tracker content and the wishlist section. When the attached tracker has tracked items but no native tracker sections are visible, the addon SHALL display its surrogate `All Objectives` header and position the wishlist at the tracker area's normal top position. While that attached standalone surrogate-header presentation is visible, the wishlist SHALL remain correctly aligned across loading-screen and teleport transitions, regardless of whether the Objective Tracker is in its default managed position or has been moved through Edit Mode. In all non-detached tracker presentations, the wishlist SHALL follow Objective Tracker layout even when the resulting frame extends below the visible screen, and the addon SHALL NOT stop pushing the wishlist downward solely to keep it on screen. These Objective Tracker anchoring requirements SHALL apply only while the wishlist is attached; detached mode SHALL instead use its persisted movable placement and SHALL remain clamped to the visible screen bounds.

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

#### Scenario: Attached append mode may extend below the screen

- **WHEN** the `Loot Wishlist` tracker is attached beneath visible native Objective Tracker content
- **AND** the combined tracker stack is taller than the visible screen height
- **THEN** the wishlist continues following its attached anchor below the last visible native tracker section
- **AND** the addon does not stop that downward placement solely to keep the wishlist on screen

#### Scenario: Attached standalone mode may extend below the screen

- **WHEN** the `Loot Wishlist` tracker is attached in surrogate-header standalone presentation
- **AND** the tracker's rendered height exceeds the remaining visible screen space
- **THEN** the attached wishlist remains aligned to the tracker area's anchor position
- **AND** the addon does not clamp the wishlist back onto the screen

#### Scenario: Detached tracker remains screen clamped

- **WHEN** the `Loot Wishlist` tracker is detached
- **AND** the user moves it near a screen edge or its rendered height exceeds the available viewport
- **THEN** the detached tracker remains constrained to the visible screen bounds

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

### Requirement: Tracker visuals prefer native Blizzard UI assets

The addon SHALL prefer Blizzard-provided UI assets and visual patterns for tracker presentation, including indicators and row styling, unless a native asset cannot express the required behavior.

#### Scenario: Tracker row is rendered

- **WHEN** the addon renders a wishlist row in the objective tracker
- **THEN** it uses native Blizzard visual patterns where practical instead of bespoke addon-specific visuals

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

The tracker filter menu SHALL list only tags currently assigned to at least one wishlist item. Each listed tag SHALL have a checkbox. Selecting multiple tags SHALL show items that carry any selected tag. No selected tags SHALL show all wishlist items, and selecting every available filter tag SHALL behave the same as selecting none.

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

### Requirement: Tracker filter state remains presentation-only and self-healing

The tracker tag filter SHALL affect only which wishlist items are visible in the tracker. It SHALL NOT change wishlist membership, tag assignments, loot alert triggering, or loot roll badge presence. If a selected filter tag is deleted or becomes unused, the system SHALL automatically remove that stale selection from the tracker filter state, and if no selections remain the tracker SHALL revert to showing all wishlist items.

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

### Requirement: Tracker item tooltips show assigned tags in the footer

Tracker item tooltips SHALL append a wishlist footer line using the favorite atlas and the item's assigned tags joined by comma and space. In source-grouped mode, the tooltip SHALL append only that tags line. In equipment-slot-grouped mode, the tooltip SHALL append the tags line above the existing source footer line.

#### Scenario: Source-grouped tooltip shows only the tags footer line
- **WHEN** the user hovers a tracker item while the active tracker grouping mode is loot source
- **THEN** the tooltip appends one wishlist footer line containing the favorite atlas and the item's assigned tags

#### Scenario: Slot-grouped tooltip shows tags above source
- **WHEN** the user hovers a tracker item while the active tracker grouping mode is equipment slot
- **THEN** the tooltip appends the tags footer line above the existing source footer line

