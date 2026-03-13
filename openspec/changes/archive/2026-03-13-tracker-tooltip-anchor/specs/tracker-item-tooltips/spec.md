## MODIFIED Requirements

### Requirement: Tracker row tooltips use the game's default anchor behavior

The addon SHALL anchor wishlist tracker row tooltips so the tooltip's top-right corner aligns to the row's top-left corner with a 4px horizontal gap, while keeping the tooltip owned by UIParent.

#### Scenario: Hover tracked row
- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section
- **THEN** the tooltip is anchored to the row with its top-right aligned to the row top-left with a 4px horizontal gap
