## Why

The current notification system (`RaidNotice_AddMessage` to `RaidWarningFrame`) displays an ephemeral text message when a tracked item drops. In the heat of a dungeon or raid, this un-clickable text disappears quickly and can easily be overlooked. Moving this alert to a prominent, interactive dialog with an embedded item frame provides a massive UX improvement, ensuring the player doesn't miss when their wishlist item drops and allowing them to immediately inspect the item's tooltip.

## What Changes

- Register a new custom `StaticPopupDialog` named `"LOOT_WISHLIST_ALERT"`.
- Configure the dialog with `hasItemFrame = 1` so WoW natively displays the item icon, name, and provides standard tooltip hovering.
- Update `namespace.ShowAlert(message)` to a more structured function `namespace.ShowLootDialog(playerName, itemLink)`.
- Format the dialog text in crisp white (`|cFFFFFFFF`) and highlight the looter's name in a distinct orange (`|cFFFF8000`) to make it pop against the default gold text.

## Capabilities

### New Capabilities

- `loot-alert-dialog`: Defines the customized Static Popup that triggers when a tracked item is looted.

### Modified Capabilities

- `wishlist-loot-awareness`: The requirement is changing from showing a Raid Warning message to launching the structured Alert Dialog.

## Impact

- **Affected Code**: `LootWishList.lua`, `LootEvents.lua`
- **APIs**: Native `StaticPopupDialogs` API and `StaticPopup_Show`.
- **User Flow**: Intrusive but necessary shift; the user must explicitly click "OK" (or hit escape) to dismiss the dialog instead of it fading away automatically.
