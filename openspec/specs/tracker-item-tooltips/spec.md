## Purpose

Define how tracked wishlist items in the Objective Tracker expose the standard Blizzard item tooltip on hover, using a tracker-dedicated tooltip surface, a custom row-relative anchor, and grouping-mode-aware footer behavior.

## Requirements

### Requirement: Tracker rows show the standard Blizzard item tooltip on hover

When the user hovers a tracked item row in the `Loot Wishlist` section, the addon SHALL show that item's standard Blizzard item tooltip. The tooltip's effective item reference SHALL prefer the best currently owned live item link, then the persisted locale-neutral selected variant reference, then stable base-item fallback. When the hovered item supports equipped-item comparison, the addon SHALL also show addon-owned equipped comparison tooltips from the tracker-dedicated tooltip surface, styled to match Blizzard compare panes. When the tracker refreshes while the cursor remains over the wishlist tracker, the addon SHALL reconcile hover against the current live row under the cursor after the refresh instead of unconditionally dismissing the tooltip. If that live hover target is still a valid tracked item row, the addon SHALL show the tooltip for that row's current item, even when the row has been rebound to a different tracked item during refresh. If the post-refresh hover target is no longer a valid tracked item row, the addon SHALL hide the tracker tooltip and any comparison panes associated with that row.

#### Scenario: Hover tracked row prefers best owned item link

- **WHEN** the user hovers a tracked item row
- **AND** the active character currently owns a resolved item link for that tracked item
- **THEN** the tracker tooltip uses that best owned item link as the effective item reference

#### Scenario: Hover tracked row falls back to selected variant reference

- **WHEN** the user hovers a tracked item row
- **AND** no best owned item link is available for that tracked item
- **AND** the wishlist entry has a persisted locale-neutral selected variant reference
- **THEN** the tracker tooltip uses that selected variant reference as the effective item reference

#### Scenario: Hover tracked row falls back to stable item identity

- **WHEN** the user hovers a tracked item row
- **AND** neither a best owned item link nor a persisted selected variant reference is available
- **THEN** the tracker tooltip falls back to a stable base-item reference for that tracked item

#### Scenario: Hover equippable tracked row shows equipped comparison

- **WHEN** the user hovers a tracked item row with a resolved item reference and the item supports equipped-item comparison
- **THEN** the tracker tooltip shows the item together with addon-owned equipped comparison tooltips styled to match Blizzard compare panes

#### Scenario: Leaving tracked row hides comparison panes

- **WHEN** the user stops hovering a tracked item row whose tooltip is showing equipped comparison
- **THEN** the addon hides the tracker tooltip and any comparison panes associated with that row

#### Scenario: Tracker refresh preserves tooltip for same hovered item row

- **WHEN** the user is hovering a valid tracked item row and its tooltip is showing
- **AND** the tracker refreshes while the cursor remains over that same valid tracked item row
- **THEN** the tooltip remains available for that row after refresh without requiring the user to move the cursor out and back in

#### Scenario: Tracker refresh switches tooltip when hovered row is rebound to a different item

- **WHEN** the user is hovering a valid tracked item row and its tooltip is showing
- **AND** a tracker refresh rebinds the row currently under the cursor to a different tracked item
- **THEN** the tracker tooltip updates to show the newly bound tracked item instead of being dismissed

#### Scenario: Tracker refresh hides tooltip when hover target is no longer a valid item row

- **WHEN** the user is hovering a tracked item row and its tooltip is showing
- **AND** a tracker refresh leaves the cursor over a group header, boss header, hidden row, collapsed tracker state, or no tracker item row at all
- **THEN** the addon hides the tracker tooltip and any comparison panes associated with that row

### Requirement: Tracker row tooltips use a custom anchor positioned near the row

The addon SHALL anchor wishlist tracker row tooltips so the tooltip's top-right corner aligns to the row's top-left corner with a 4px horizontal gap. The tooltip used for wishlist tracker rows SHALL be a tracker-dedicated tooltip surface and SHALL NOT rely on a shared Blizzard tooltip object that is concurrently used by other Blizzard UI surfaces.

#### Scenario: Hover tracked row

- **WHEN** the user hovers a tracked item row in the `Loot Wishlist` section
- **THEN** the tooltip is anchored to the row with its top-right aligned to the row top-left with a 4px horizontal gap

#### Scenario: Hover tracker row before hovering Blizzard-owned item UI

- **WHEN** the user hovers a tracked wishlist row and then hovers a Blizzard-owned item surface
- **THEN** the Blizzard-owned item surface still shows its normal tooltip behavior

### Requirement: Tooltip content remains purely Blizzard-native

In `Loot Source` mode, the addon SHALL NOT inject wishlist-specific lines, labels, markers, or footer text into the tooltip shown from tracker rows. In `Equipment Slot` mode, the addon SHALL append a spacer line followed by exactly one wishlist-specific footer line to the tracker-row tooltip when stable persisted source metadata is available and the addon can resolve localized instance and boss labels for the active client locale at render time. That footer line SHALL replace the `Drops from:` text prefix with a Blizzard atlas icon: a dungeon atlas for dungeon or other non-raid items and a raid atlas for raid items with a known boss name. The remaining footer text SHALL read `<Instance Name>` for dungeon items or non-raid items, and `<Instance Name> - <Boss Name>` for raid items with a known boss name. When equipped comparison tooltips are shown, addon-specific footer text MUST remain on the primary tracker tooltip only.

#### Scenario: Source mode tooltip has no addon-specific footer

- **WHEN** the addon shows an item tooltip from a tracked row while the active tracker grouping mode is `Loot Source`
- **THEN** the tooltip contents remain the standard Blizzard item tooltip without addon-specific text additions

#### Scenario: Slot mode tooltip shows dungeon atlas and source

- **WHEN** the addon shows an item tooltip from a tracked row while the active tracker grouping mode is `Equipment Slot`
- **AND** the tracked item has stable source metadata that resolves to a known localized dungeon or non-raid instance name
- **THEN** the tooltip appends a spacer line and then a single footer line with a dungeon atlas followed by `<Instance Name>`
- **AND** that footer line does not include localized `Drops from:` text

#### Scenario: Slot mode tooltip shows raid atlas, source, and boss

- **WHEN** the addon shows an item tooltip from a tracked row while the active tracker grouping mode is `Equipment Slot`
- **AND** the tracked item has stable source metadata that resolves to a known localized raid instance name and boss name
- **THEN** the tooltip appends a spacer line and then a single footer line with a raid atlas followed by `<Instance Name> - <Boss Name>`
- **AND** that footer line does not include localized `Drops from:` text

#### Scenario: Slot mode tooltip skips footer when localized drop source is unknown

- **WHEN** the addon shows an item tooltip from a tracked row while the active tracker grouping mode is `Equipment Slot`
- **AND** the tracked item does not have stable source metadata or localized source labels needed to produce the footer text
- **THEN** the addon does not append misleading fallback footer text

#### Scenario: Comparison tooltips stay visually Blizzard-like in slot mode

- **WHEN** the addon shows equipped comparison for a tracked row while the active tracker grouping mode is `Equipment Slot`
- **THEN** the wishlist footer appears only on the primary tracker tooltip and the comparison tooltips do not add wishlist-specific footer text
