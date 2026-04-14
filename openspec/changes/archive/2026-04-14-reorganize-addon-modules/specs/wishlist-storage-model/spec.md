## MODIFIED Requirements

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
