## Purpose

Define the normalized saved-variable model for tracked wishlist entries, including locale-neutral selected variant fallback data and legacy migration behavior.

## Requirements

### Requirement: Wishlist storage persists canonical locale-neutral tracked-item state

The addon SHALL persist the active character's wishlist as a sparse map keyed by stable base item identity. A wishlist item SHALL be considered tracked when its entry is present and untracked when its entry is absent. Persisted wishlist entries SHALL store only canonical locale-neutral tracked-item state needed for wishlist behavior, including remembered best looted item level, stable source identifiers, stable slot metadata when used for grouping, and a locale-neutral `selectedVariantRef` when a selected Adventure Guide variant is known. Persisted wishlist entries SHALL NOT store localized item names, localized source labels, localized boss names, full localized item links, or a separate `tracked` boolean.

#### Scenario: Tracked item is persisted as a present entry
- **WHEN** the active character tracks an item
- **THEN** the wishlist storage contains an entry for that base item ID
- **AND** the presence of that entry is the tracked-membership signal

#### Scenario: Untracked item has no tombstone entry
- **WHEN** the active character removes a tracked item from the wishlist
- **THEN** the wishlist storage deletes that item's entry instead of persisting a `tracked = false` tombstone

#### Scenario: Persisted entry omits localized presentation fields
- **WHEN** the addon saves or updates a tracked wishlist entry
- **THEN** the stored entry omits localized presentation fields such as item name text, source label text, boss name text, and full localized display-link text

### Requirement: Selected Adventure Guide variant is stored as a locale-neutral fallback reference

When the player tracks an item from an Adventure Guide loot row, the addon SHALL persist the selected variant as a locale-neutral item-reference payload suitable for later tooltip and track derivation. The persisted selected variant SHALL remain presentation metadata only and SHALL NOT change base-item-scoped wishlist membership.

#### Scenario: Tracking an item stores a locale-neutral selected variant
- **WHEN** the player tracks an item from an Adventure Guide loot row with a known selected variant hyperlink
- **THEN** the wishlist entry stores a locale-neutral `selectedVariantRef` derived from that hyperlink's item-reference payload

#### Scenario: Selected variant does not create variant-specific membership
- **WHEN** the wishlist entry stores a `selectedVariantRef` for a tracked item
- **THEN** wishlist membership still remains keyed by the base item identity rather than the selected variant

### Requirement: Legacy wishlist entries migrate to the normalized schema

On loading legacy SavedVariables, the addon SHALL migrate existing wishlist entries to the normalized storage model before normal wishlist reads and writes occur. The migration SHALL preserve tracked membership and durable metadata where possible, derive a locale-neutral `selectedVariantRef` from a legacy tracked link when possible, remove legacy localized presentation fields, and be safe to run more than once.

#### Scenario: Legacy tracked entry is upgraded
- **WHEN** the addon loads a legacy wishlist entry whose stored state indicates that the item is tracked
- **THEN** the addon preserves durable fields such as remembered item level and stable source identifiers
- **AND** removes legacy localized presentation fields and the legacy `tracked` flag

#### Scenario: Legacy untracked tombstone is removed
- **WHEN** the addon loads a legacy wishlist entry whose stored state indicates that the item is not tracked
- **THEN** the addon removes that entry from the normalized wishlist storage

#### Scenario: Legacy link cannot produce a locale-neutral selected variant
- **WHEN** the addon loads a legacy tracked entry but cannot derive a valid locale-neutral `selectedVariantRef` from the legacy tracked link
- **THEN** the addon preserves the tracked entry's durable state
- **AND** leaves the normalized entry without a `selectedVariantRef` instead of failing the migration
