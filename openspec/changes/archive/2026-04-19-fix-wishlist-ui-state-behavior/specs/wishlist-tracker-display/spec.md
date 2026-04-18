## MODIFIED Requirements

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
