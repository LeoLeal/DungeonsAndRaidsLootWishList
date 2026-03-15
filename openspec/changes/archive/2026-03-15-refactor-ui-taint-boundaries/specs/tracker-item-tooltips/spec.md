## MODIFIED Requirements

### Requirement: Tracker row tooltips use a custom anchor positioned near the row

The addon SHALL anchor wishlist tracker row tooltips so the tooltip's top-right corner aligns to the row's top-left corner with a 4px horizontal gap. The tooltip used for wishlist tracker rows SHALL be a tracker-dedicated tooltip surface and SHALL NOT rely on a shared Blizzard tooltip object that is concurrently used by other Blizzard UI surfaces.

#### Scenario: Hover tracked row

- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section
- **THEN** the tooltip is anchored to the row with its top-right aligned to the row top-left with a 4px horizontal gap

#### Scenario: Hover tracker row before hovering Blizzard-owned item UI

- **WHEN** the user hovers a tracked wishlist row and then hovers a Blizzard-owned item surface
- **THEN** the Blizzard-owned item surface still shows its normal tooltip behavior
