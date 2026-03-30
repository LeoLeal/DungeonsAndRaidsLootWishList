## MODIFIED Requirements

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
