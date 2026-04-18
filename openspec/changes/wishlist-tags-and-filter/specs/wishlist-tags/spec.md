## ADDED Requirements

### Requirement: Wishlist membership is tag-based per character
The system SHALL persist wishlist tags per character as plain text labels. A wishlist item SHALL be considered tracked only while it has at least one assigned tag. The system SHALL seed one initial default tag using the active locale's localized text for `Best in slot` when a character has no persisted tags, and SHALL NOT translate previously stored tag text if the game locale later changes.

#### Scenario: Character with no tags receives the initial default tag
- **WHEN** the tag system initializes for a character with no persisted wishlist tags
- **THEN** the system creates exactly one initial tag using the active locale's localized text for `Best in slot`

#### Scenario: Item with assigned tags remains tracked
- **WHEN** a wishlist item has one or more assigned tags for the active character
- **THEN** the item remains on that character's wishlist

#### Scenario: Item with no assigned tags is removed from the wishlist
- **WHEN** the last assigned tag is removed from a wishlist item
- **THEN** the system removes that item from the character's wishlist instead of persisting a tagless tracked item

#### Scenario: Stored tags remain unchanged after locale change
- **WHEN** a character later plays with a different game locale
- **THEN** previously stored tag labels remain unchanged text

### Requirement: Tag names are unique using case-insensitive comparison
The system SHALL enforce tag uniqueness using trimmed, case-insensitive comparison while preserving the user's chosen display text for stored tags.

#### Scenario: Duplicate tag differs only by case
- **WHEN** the user tries to create a tag whose trimmed text matches an existing tag ignoring case
- **THEN** the system rejects the new tag as a duplicate

#### Scenario: Unique tag preserves chosen casing
- **WHEN** the user creates a new non-duplicate tag label
- **THEN** the system stores and displays that tag using the user's entered casing

### Requirement: The tag catalog always contains at least one tag
The system SHALL keep at least one wishlist tag in the addon's per-character catalog at all times. Deleting a tag SHALL remove that tag from all items that use it, and any item left with zero tags SHALL be removed from the wishlist.

#### Scenario: Last remaining tag cannot be removed from the catalog
- **WHEN** only one tag exists in the active character's tag catalog
- **THEN** the system does not allow that final remaining tag to be deleted

#### Scenario: Deleting a tag removes it from all assigned items
- **WHEN** a tag is deleted from the catalog
- **THEN** the system removes that tag from every wishlist item that used it

#### Scenario: Deleting a tag can untrack affected items
- **WHEN** a deleted tag was the only assigned tag on one or more wishlist items
- **THEN** the system removes those items from the wishlist

### Requirement: Legacy tracked items migrate to the initial default tag
The system SHALL migrate pre-existing tracked wishlist items so that each migrated item receives the initial default tag for that character.

#### Scenario: Legacy tracked item receives default tag during migration
- **WHEN** the addon migrates stored wishlist data created before tag assignments existed
- **THEN** each legacy tracked item is assigned the character's initial default tag

### Requirement: Assigned tag presentation uses catalog order
The system SHALL expose assigned tags in the order of the character's persisted tag catalog when tracker or loot-awareness surfaces display those tags.

#### Scenario: Item displays assigned tags in catalog order
- **WHEN** an item has multiple assigned tags and a feature presents them to the user
- **THEN** the tags appear in the same order as the character's tag catalog
