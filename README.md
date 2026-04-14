Loot WishList

This is a World of Warcraft addon to manage Loot Wishlists written in LUA that integrates with Adventure Journals (Dungeon and Raid Journals) and loot notifications.

This project was built using Spec Driven Development. (OpenSpec Workflow)

Current module layout:

- `Core/` contains bootstrap and shared cross-feature primitives.
- `DataStore/` owns saved-variable reads, writes, migration, and tracker preferences.
- `AdventureGuide/` owns Encounter Journal hooks, loot-row scanning, metadata capture, and wishlist checkboxes.
- `Tracker/` owns tracker grouping, row styling, frame rendering, tooltip handling, and possession-aware presentation.
- `LootAwareness/` owns loot event handling, alert presentation, and roll badge behavior.
