## ADDED Requirements

### Requirement: Adventure Guide loot rows can toggle wishlist membership
The addon SHALL add a wishlist toggle control to dungeon and raid loot rows shown in the Adventure Guide. The control SHALL reflect whether the corresponding item is currently tracked for the active character and SHALL allow the user to add or remove the item from the character-specific wishlist.

#### Scenario: Add an item from the Adventure Guide
- **WHEN** the user checks the wishlist control for an untracked Adventure Guide loot item
- **THEN** the addon adds that item to the active character's wishlist and the control displays the tracked state

#### Scenario: Remove an item from the Adventure Guide
- **WHEN** the user unchecks the wishlist control for a tracked Adventure Guide loot item
- **THEN** the addon removes that item from the active character's wishlist and the control displays the untracked state

### Requirement: Wishlist tracking uses stable item identity across item-level variants
The addon SHALL treat Adventure Guide baseline items and higher item-level versions of the same underlying item as one wishlist target. Wishlist membership SHALL be keyed by stable item identity rather than the item level shown in the Adventure Guide.

#### Scenario: A higher item-level version appears later
- **WHEN** an item tracked from the Adventure Guide is later encountered as a higher item-level version of the same underlying item
- **THEN** the addon matches it to the existing wishlist entry instead of creating a separate tracked item

#### Scenario: Checkbox state reflects an existing tracked item
- **WHEN** the Adventure Guide displays a loot row for an item that is already tracked through another item-level variant
- **THEN** the wishlist control shows that the item is already tracked

### Requirement: Adventure Guide controls remain independent from ownership state
The addon SHALL use the Adventure Guide wishlist control only to represent tracked versus untracked state. Ownership state, possession indicators, and remembered loot history SHALL NOT change how the control behaves.

#### Scenario: Owned item remains tracked in the Adventure Guide
- **WHEN** the character currently possesses a tracked item
- **THEN** the Adventure Guide wishlist control remains checked until the user explicitly removes the item from the wishlist

#### Scenario: Best looted item level does not alter toggle behavior
- **WHEN** the addon has recorded a best looted item level for a tracked item
- **THEN** the Adventure Guide wishlist control still behaves as a simple add or remove toggle
