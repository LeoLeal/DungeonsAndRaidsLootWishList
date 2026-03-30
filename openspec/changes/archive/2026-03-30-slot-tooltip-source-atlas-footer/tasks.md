## 1. Apply the confirmed atlas choice and footer formatting path

- [x] 1.1 Use the confirmed `Dungeon` and `Raid` atlas names from `objecticonsatlas` for slot-mode tracker tooltip source icons
- [x] 1.2 Update the slot-mode tooltip footer builder so it produces icon-prefixed footer text without the localized `Drops from:` prefix
- [x] 1.3 Remove the obsolete `DROPS_FROM` and `DROPS_FROM_RAID` entries from `Locales.lua` across supported languages once the footer no longer depends on them

## 2. Keep tooltip rendering narrow and Blizzard-native

- [x] 2.1 Keep the footer on the existing primary tracker tooltip line path so loot-source mode and comparison tooltip behavior remain unchanged
- [x] 2.2 Verify raid footers still show `<Instance Name> - <Boss Name>` and dungeon footers still show `<Instance Name>` after the icon-only prefix change

## 3. Add verification coverage

- [x] 3.1 Update or add tests for slot-mode tooltip footer formatting so dungeon and raid items use atlas-prefixed footers without localized `Drops from:` text
- [x] 3.2 Manually validate in-game that slot-mode tooltips render the chosen atlas cleanly, loot-source mode tooltips remain unchanged, and locale cleanup did not remove any still-used strings
