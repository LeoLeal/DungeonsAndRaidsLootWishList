## MODIFIED Requirements

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
