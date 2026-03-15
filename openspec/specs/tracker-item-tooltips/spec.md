## Purpose

Define how tracked wishlist items in the Objective Tracker expose the standard Blizzard item tooltip on hover, using a tracker-dedicated tooltip surface, a custom row-relative anchor, and no addon-specific tooltip content.

## Requirements

### Requirement: Tracker rows show the standard Blizzard item tooltip on hover

When the user hovers a tracked item row in the `Loot Wishlist` section, the addon SHALL show that item's standard Blizzard item tooltip.

#### Scenario: Hover tracked row with a resolved item reference

- **WHEN** the user hovers a tracked item row and the addon can resolve an item reference for that row
- **THEN** the standard Blizzard item tooltip is shown for that item

#### Scenario: Hover tracked row with no resolved item reference

- **WHEN** the user hovers a tracked item row and the addon cannot resolve a usable item reference
- **THEN** the addon does not show custom fallback tooltip text

### Requirement: Tracker row tooltips use a custom anchor positioned near the row

The addon SHALL anchor wishlist tracker row tooltips so the tooltip's top-right corner aligns to the row's top-left corner with a 4px horizontal gap. The tooltip used for wishlist tracker rows SHALL be a tracker-dedicated tooltip surface and SHALL NOT rely on a shared Blizzard tooltip object that is concurrently used by other Blizzard UI surfaces.

#### Scenario: Hover tracked row

- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section
- **THEN** the tooltip is anchored to the row with its top-right aligned to the row top-left with a 4px horizontal gap

#### Scenario: Hover tracker row before hovering Blizzard-owned item UI

- **WHEN** the user hovers a tracked wishlist row and then hovers a Blizzard-owned item surface
- **THEN** the Blizzard-owned item surface still shows its normal tooltip behavior

### Requirement: Tooltip content remains purely Blizzard-native

The addon SHALL NOT inject wishlist-specific lines, labels, markers, or footer text into the tooltip shown from tracker rows.

#### Scenario: Tooltip is shown from a tracker row

- **WHEN** the addon shows an item tooltip from a tracked row
- **THEN** the tooltip contents remain the standard Blizzard item tooltip without addon-specific text additions
