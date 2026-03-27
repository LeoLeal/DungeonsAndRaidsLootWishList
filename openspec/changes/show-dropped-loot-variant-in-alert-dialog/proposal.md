## Why

Tracked-loot alerts currently present the wishlist's stored item link instead of the actual variant observed in the loot event. That hides the dropped upgrade track or item-level variant, making it harder for the player to recognize which version to expect if the item is traded to them.

## What Changes

- Preserve stable base-item matching for wishlist detection, but use the extracted dropped item link directly as the alert's display link when the loot message is readable.
- Change tracked-loot alert presentation so the dialog and primary tooltip show the actual dropped variant, while compare panes continue to compare the player's equipped items against that dropped item.
- Reject secret or unreadable loot-chat payloads before parsing and do not build a tracked-loot alert from unreadable payloads.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `loot-alert-dialog`: change alert item presentation requirements so the popup shows the actual dropped item variant when the loot event provides one.
- `wishlist-loot-awareness`: change loot-alert normalization requirements so matching stays base-item stable while alert records use the extracted dropped item link directly for presentation.

## Impact

- Affected code centers on `LootEvents.lua`, `LootWishList.lua`, and `WishListAlert.lua`.
- No saved-variable migration or wishlist identity changes are intended.
- The alert path now depends on a readable loot-message payload to derive the display item link; unreadable payloads are ignored rather than falling back to stored wishlist links.
