## Purpose

Define how the `Loot Wishlist` tracker lets each character switch between grouping modes and how those grouping-specific preferences persist.

## Requirements

### Requirement: Wishlist tracker header can switch grouping mode

The addon SHALL expose a grouping control on the `Loot Wishlist` header that lets the player switch the tracker between `Loot Source` mode and `Equipment Slot` mode without changing wishlist membership.

#### Scenario: Tracker starts in Loot Source mode by default

- **WHEN** the active character has never changed the wishlist tracker grouping mode before
- **THEN** the `Loot Wishlist` tracker displays in `Loot Source` mode

#### Scenario: Player switches from Loot Source to Equipment Slot

- **WHEN** the player uses the grouping control on the `Loot Wishlist` header to select `Equipment Slot`
- **THEN** the wishlist tracker immediately rebuilds in `Equipment Slot` mode
- **AND** the tracked items remain on the wishlist unchanged

#### Scenario: Player switches from Equipment Slot to Loot Source

- **WHEN** the player uses the grouping control on the `Loot Wishlist` header to select `Loot Source`
- **THEN** the wishlist tracker immediately rebuilds in `Loot Source` mode
- **AND** the tracked items remain on the wishlist unchanged

### Requirement: Grouping preference persists per character

The addon SHALL persist the active wishlist tracker grouping mode per character so the same character returns to the same grouping mode after reloading the UI or logging in again. Persisted grouping mode and grouping-specific collapse state SHALL remain DataStore-owned preferences, while Tracker-owned modules consume and apply those persisted preferences when rendering the tracker.

#### Scenario: Reload preserves grouping mode

- **WHEN** the player selects `Equipment Slot` mode and reloads the UI
- **THEN** the same character's `Loot Wishlist` tracker returns in `Equipment Slot` mode

#### Scenario: Character-specific preference stays isolated

- **WHEN** one character changes the wishlist tracker grouping mode
- **THEN** another character's grouping preference is unaffected until that character changes its own setting

#### Scenario: Tracker consumes persisted preferences without owning storage

- **WHEN** the tracker rebuilds using the active character's grouping mode and collapse state
- **THEN** Tracker-owned modules read and apply the persisted preferences
- **AND** DataStore-owned modules remain the owner of storing those preferences

### Requirement: Group collapse state is isolated per grouping mode

The addon SHALL persist collapsed group state separately for `Loot Source` mode and `Equipment Slot` mode so collapsing a group in one mode does not collapse an unrelated group in the other mode.

#### Scenario: Source-mode collapse does not affect slot mode

- **WHEN** the player collapses a group while the tracker is in `Loot Source` mode and then switches to `Equipment Slot` mode
- **THEN** the slot-mode groups use their own collapse state rather than inheriting the source-mode collapse state

#### Scenario: Slot-mode collapse is restored when returning to slot mode

- **WHEN** the player collapses a group while the tracker is in `Equipment Slot` mode, switches away, and later returns to `Equipment Slot` mode
- **THEN** the same slot-mode group remains collapsed
