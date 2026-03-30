## Why

Slot-mode tracker tooltips currently append a localized `Drops from:` text prefix before the source label. That works, but it is visually heavier than the rest of the Blizzard-native tooltip styling and repeats meaning that could be conveyed more cleanly with dungeon and raid iconography.

## What Changes

- Replace the slot-mode tooltip footer's `Drops from:` text prefix with an atlas-based source icon.
- Show a dungeon atlas before dungeon or other non-raid source labels and a raid atlas before raid source labels.
- Keep the existing slot-mode footer content model, including `<Instance Name>` for dungeon items and `<Instance Name> - <Boss Name>` for raid items.
- Remove the now-unused localized `Drops from:` footer-prefix strings from `Locales.lua` across supported languages.
- Keep loot-source mode unchanged so it continues to show no addon-specific footer text.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `tracker-item-tooltips`: Slot-mode tooltip footer presentation changes from localized `Drops from:` text to atlas-prefixed source labels that distinguish dungeon and raid sources.

## Impact

- Affected code will likely center on `LootWishList.lua`, `TrackerUI.lua`, `Locales.lua`, and any tooltip-related tests.
- This change depends on choosing Blizzard atlas names that render cleanly inside tracker tooltip footer lines.
- Localization burden should decrease because the footer prefix will no longer rely on localized `Drops from:` text for slot-mode presentation and the obsolete locale entries can be removed.
