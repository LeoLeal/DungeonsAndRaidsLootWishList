## MODIFIED Requirements

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
