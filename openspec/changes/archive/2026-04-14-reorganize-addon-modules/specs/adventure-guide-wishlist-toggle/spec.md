## MODIFIED Requirements

### Requirement: Adventure Guide loot rows can toggle wishlist membership
The addon SHALL add a wishlist toggle control to dungeon and raid loot rows shown in the Adventure Guide. The control SHALL reflect whether the corresponding item is currently tracked for the active character and SHALL allow the user to add or remove the item from the character-specific wishlist. When the user adds an item from an Adventure Guide loot row, the addon SHALL persist base-item-scoped wishlist membership together with a locale-neutral selected variant reference derived from that row when the row exposes a selected variant hyperlink. When the user removes an item from the wishlist, the addon SHALL remove the wishlist entry entirely instead of leaving a persisted untracked tombstone. The journal-facing logic that hooks Encounter Journal updates, locates loot rows, derives row item data, and presents the wishlist toggle SHALL be owned by AdventureGuide modules, while DataStore SHALL only persist the normalized values provided by that feature.

#### Scenario: Add an item from the Adventure Guide
- **WHEN** the user checks the wishlist control for an untracked Adventure Guide loot item
- **THEN** the addon adds that item to the active character's wishlist
- **AND** the control displays the tracked state
- **AND** the addon stores a locale-neutral selected variant reference for that loot row when one is available

#### Scenario: Remove an item from the Adventure Guide
- **WHEN** the user unchecks the wishlist control for a tracked Adventure Guide loot item
- **THEN** the addon removes that item from the active character's wishlist
- **AND** the control displays the untracked state
- **AND** the wishlist storage no longer contains an entry for that tracked item

#### Scenario: Adventure Guide owns journal row integration
- **WHEN** the addon refreshes wishlist controls for Encounter Journal loot rows
- **THEN** AdventureGuide-owned modules perform the row discovery, item-data extraction, and checkbox presentation work
- **AND** DataStore does not become the owner of direct Encounter Journal widget traversal
