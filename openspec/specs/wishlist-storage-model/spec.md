## Purpose

Define the normalized saved-variable model for tracked wishlist entries, including locale-neutral selected variant fallback data and current-version normalization behavior.

## Requirements

### Requirement: Wishlist storage persists canonical locale-neutral tracked-item state

The addon SHALL persist the active character's wishlist as a sparse map keyed by stable base item identity. A wishlist item SHALL be considered tracked when its entry is present and untracked when its entry is absent. Persisted wishlist entries SHALL store only canonical locale-neutral tracked-item state needed for wishlist behavior, including stable source identifiers, stable slot metadata when used for grouping, and a locale-neutral `selectedVariantRef` when a selected Adventure Guide variant is known. Persisted wishlist entries SHALL NOT store remembered best looted item level, localized item names, localized source labels, localized boss names, full localized item links, or a separate `tracked` boolean. Store helpers that existed solely to read or update remembered best-looted item-level history SHALL be removed rather than retained as compatibility shims. DataStore-owned modules SHALL own tracked-item persistence, migration, and persisted tracker preferences, and SHALL NOT become the owner of direct feature-UI widget traversal such as Encounter Journal row scraping.

#### Scenario: Tracked item is persisted as a present entry
- **WHEN** the active character tracks an item
- **THEN** the wishlist storage contains an entry for that base item ID
- **AND** the presence of that entry is the tracked-membership signal

#### Scenario: Untracked item has no tombstone entry
- **WHEN** the active character removes a tracked item from the wishlist
- **THEN** the wishlist storage deletes that item's entry instead of persisting a `tracked = false` tombstone

#### Scenario: Persisted entry omits obsolete history and localized presentation fields
- **WHEN** the addon saves or updates a tracked wishlist entry
- **THEN** the stored entry omits remembered best-looted item-level history and localized presentation fields such as item name text, source label text, boss name text, and full localized display-link text

#### Scenario: DataStore remains separate from feature widget traversal
- **WHEN** the addon needs metadata that must be derived from live feature UI structures
- **THEN** the owning feature derives the normalized values before persistence
- **AND** DataStore only persists the normalized results it receives

### Requirement: Selected Adventure Guide variant is stored as a locale-neutral fallback reference

When the player tracks an item from an Adventure Guide loot row, the addon SHALL persist the selected variant as a locale-neutral item-reference payload suitable for later tooltip derivation. The persisted selected variant SHALL remain presentation metadata only and SHALL NOT change base-item-scoped wishlist membership.

#### Scenario: Tracking an item stores a locale-neutral selected variant
- **WHEN** the player tracks an item from an Adventure Guide loot row with a known selected variant hyperlink
- **THEN** the wishlist entry stores a locale-neutral `selectedVariantRef` derived from that hyperlink's item-reference payload

#### Scenario: Selected variant does not create variant-specific membership
- **WHEN** the wishlist entry stores a `selectedVariantRef` for a tracked item
- **THEN** wishlist membership still remains keyed by the base item identity rather than the selected variant

### Requirement: Legacy wishlist entries migrate to the normalized schema

On loading existing SavedVariables, the addon SHALL normalize wishlist entries to the current storage model before normal wishlist reads and writes occur. The normalization SHALL preserve tracked membership and durable metadata where possible, derive a locale-neutral `selectedVariantRef` from a legacy tracked link when possible, remove legacy localized presentation fields, remove any stored `bestLootedItemLevel`, and be safe to run more than once. The addon SHALL keep the current persistence version while performing this normalization.

#### Scenario: Loaded tracked entry is normalized
- **WHEN** the addon loads a tracked wishlist entry that still contains obsolete localized fields or a stored `bestLootedItemLevel`
- **THEN** the addon preserves tracked membership and current durable metadata such as source identifiers and `selectedVariantRef`
- **AND** removes obsolete localized presentation fields and stored `bestLootedItemLevel`

#### Scenario: Loaded untracked tombstone is removed
- **WHEN** the addon loads a wishlist entry whose stored state indicates that the item is not tracked
- **THEN** the addon removes that entry from the normalized wishlist storage

#### Scenario: Legacy link cannot produce a locale-neutral selected variant
- **WHEN** the addon loads a tracked entry but cannot derive a valid locale-neutral `selectedVariantRef` from the stored tracked link
- **THEN** the addon preserves the tracked entry's remaining durable state
- **AND** leaves the normalized entry without a `selectedVariantRef` instead of failing normalization

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
