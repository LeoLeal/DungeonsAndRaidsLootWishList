## MODIFIED Requirements

### Requirement: Tracker rows show the standard Blizzard item tooltip on hover

When the user hovers a tracked item row in the `Loot Wishlist` section, the addon SHALL show that item's standard Blizzard item tooltip. When the hovered item supports equipped-item comparison, the addon SHALL also show addon-owned equipped comparison tooltips from the tracker-dedicated tooltip surface, styled to match Blizzard compare panes. When the tracker refreshes while the cursor remains over the wishlist tracker, the addon SHALL reconcile hover against the current live row under the cursor after the refresh instead of unconditionally dismissing the tooltip. If that live hover target is still a valid tracked item row, the addon SHALL show the tooltip for that row's current item, even when the row has been rebound to a different tracked item during refresh. If the post-refresh hover target is no longer a valid tracked item row, the addon SHALL hide the tracker tooltip and any comparison panes associated with that row.

#### Scenario: Hover tracked row with a resolved item reference
- **WHEN** the user hovers a tracked item row and the addon can resolve an item reference for that row
- **THEN** the standard Blizzard item tooltip is shown for that item

#### Scenario: Hover tracked row with no resolved item reference
- **WHEN** the user hovers a tracked item row and the addon cannot resolve a usable item reference
- **THEN** the addon does not show custom fallback tooltip text

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
