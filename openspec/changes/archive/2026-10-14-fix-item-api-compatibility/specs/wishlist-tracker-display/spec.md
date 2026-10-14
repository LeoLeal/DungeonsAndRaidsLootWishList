# Spec Delta

## ADDED Requirements

### Requirement: Tracker item names and rarity colors work without legacy item API globals

The wishlist tracker SHALL display a tracked item's localized name when supported client item APIs provide that name, even when legacy global item API aliases are unavailable. The tracker SHALL color the item label according to the quality of its effective display variant when that quality is available. These behaviors SHALL apply in both attached and detached presentations and in both loot-source and equipment-slot grouping modes. If name or quality data is genuinely unavailable, the tracker SHALL retain a readable item-identity fallback or its normal default text color, respectively, without suppressing the row, its possession indicator, or its item tooltip reference. Resolving presentation data SHALL NOT change wishlist membership, tag assignments, saved metadata, or effective-variant selection.

#### Scenario: Namespaced item APIs resolve the name while legacy globals are absent

- **WHEN** legacy global item API aliases are unavailable
- **AND** supported client item APIs return a localized name for a tracked item
- **THEN** the tracker displays that name instead of its item-ID fallback

#### Scenario: Namespaced item APIs resolve effective-variant quality

- **WHEN** legacy global item API aliases are unavailable
- **AND** supported client item APIs return a quality for the tracked item's effective display variant
- **THEN** the tracker colors the item label with that variant's rarity color
- **AND** the existing best-owned, selected-variant, and base-item priority remains unchanged

#### Scenario: Name resolves through the base item when variant name data is missing

- **WHEN** name data for the effective display variant is unavailable
- **AND** supported client item APIs return a localized name for the stable base item
- **THEN** the tracker displays the base item's localized name
- **AND** retains the effective display variant as its tooltip reference

#### Scenario: Truly missing item data retains usable fallback presentation

- **WHEN** supported client item APIs do not provide a name or quality for a tracked item
- **THEN** the tracker keeps the row visible with a readable item-identity fallback and default text color
- **AND** preserves its independently determined possession indicator and tooltip reference

#### Scenario: Compatibility holds across tracker presentation modes

- **WHEN** a tracked item's name and effective-variant quality are available through supported client APIs
- **AND** the user switches attachment or grouping mode
- **THEN** the tracker continues displaying the resolved name and rarity color
- **AND** wishlist membership, tag assignments, and saved item metadata remain unchanged
