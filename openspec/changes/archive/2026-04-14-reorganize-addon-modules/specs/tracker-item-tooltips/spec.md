## MODIFIED Requirements

### Requirement: Tracker rows show the standard Blizzard item tooltip on hover

When the user hovers a tracked item row in the `Loot Wishlist` section, the addon SHALL show that item's standard Blizzard item tooltip. The tooltip's effective item reference SHALL prefer the best currently owned live item link, then the persisted locale-neutral selected variant reference, then stable base-item fallback. When the hovered item supports equipped-item comparison and the tracked item is not currently possessed, the addon SHALL also show addon-owned equipped comparison tooltips from the tracker-dedicated tooltip surface, styled to match Blizzard compare panes. When the tracked item is currently possessed, the addon SHALL show only the tooltip for the possessed item and SHALL NOT open equipped comparison panes. When the tracker refreshes while the cursor remains over the wishlist tracker, the addon SHALL reconcile hover against the current live row under the cursor after the refresh instead of unconditionally dismissing the tooltip. If that live hover target is still a valid tracked item row, the addon SHALL show the tooltip for that row's current item, even when the row has been rebound to a different tracked item during refresh. If the post-refresh hover target is no longer a valid tracked item row, the addon SHALL hide the tracker tooltip and any comparison panes associated with that row. Tracker-owned modules SHALL own tracker tooltip orchestration and anchoring behavior, while shared tooltip primitives reused across features MAY live under `Core/Shared`.

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

#### Scenario: Hover unowned equippable tracked row shows equipped comparison
- **WHEN** the user hovers a tracked item row with a resolved item reference
- **AND** the item supports equipped-item comparison
- **AND** the tracked item is not currently possessed
- **THEN** the tracker tooltip shows the item together with addon-owned equipped comparison tooltips styled to match Blizzard compare panes

#### Scenario: Hover possessed tracked row suppresses equipped comparison
- **WHEN** the user hovers a tracked item row with a resolved item reference
- **AND** the tracked item is currently possessed
- **THEN** the tracker shows the possessed tooltip only
- **AND** does not show equipped comparison panes

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
