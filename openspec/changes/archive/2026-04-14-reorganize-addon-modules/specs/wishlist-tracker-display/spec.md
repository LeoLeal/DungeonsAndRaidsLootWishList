## MODIFIED Requirements

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
