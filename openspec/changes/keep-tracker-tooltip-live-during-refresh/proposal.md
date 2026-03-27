## Why

Tracker item tooltips currently disappear while the mouse is still resting on a wishlist row because tracker refreshes unconditionally tear down hover UI. This is especially visible in busy city environments where frequent loot or inventory-related refreshes make tracker tooltips feel unstable and force the user to hover out and back in to recover them.

## What Changes

- Change tracker tooltip behavior so refreshes re-evaluate the current hover target instead of blindly hiding the tooltip.
- Preserve tracker tooltip visibility while the cursor remains over a valid tracked item row, even if the tracker refreshes in the background.
- When a refresh causes the row under the cursor to represent a different tracked item, switch the tooltip to that new row item instead of dismissing it.
- Hide the tooltip only when the post-refresh hover target is no longer a valid tracked item row, such as when the row disappears, becomes a header, or the tracker is hidden or collapsed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `tracker-item-tooltips`: change tracker hover requirements so tooltip lifecycle follows the current row under the cursor across tracker refreshes instead of being unconditionally dismissed.

## Impact

- Affected code centers on `TrackerUI.lua` and the tracker tooltip / compare-tooltip lifecycle it owns.
- Refresh-triggering paths in `LootWishList.lua` remain active; the goal is to make hover behavior resilient to refreshes rather than suppress updates.
- No saved-variable, wishlist identity, loot matching, or Adventure Guide checkbox changes are intended.
