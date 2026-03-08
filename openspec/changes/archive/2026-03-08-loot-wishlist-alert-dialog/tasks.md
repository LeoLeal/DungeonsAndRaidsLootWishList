## 1. Dialog Configuration

- [x] 1.1 Register `StaticPopupDialogs["LOOT_WISHLIST_ALERT"]` in `LootWishList.lua`.
- [x] 1.2 Configure dialog with `hasItemFrame = 1`, `button1 = "OK"`, and zero timeout.

## 2. Alert Logic Refactoring

- [x] 2.1 Refactor `namespace.ShowAlert(message)` into `namespace.ShowLootDialog(playerName, itemLink, message)`.
- [x] 2.2 Re-route `HandleChatLoot` in `LootEvents.lua` to call the new structured dialog function.
- [x] 2.3 Implement white text and player name coloration (`|cFFFF8000` Orange) inside `HandleChatLoot` or `ShowLootDialog`.
