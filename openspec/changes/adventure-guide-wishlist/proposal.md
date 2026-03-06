## Why

Players need a lightweight way to mark desirable dungeon and raid loot while browsing the Adventure Guide and keep that information visible during normal gameplay. This change defines a character-specific loot wishlist that persists across sessions, surfaces tracked items in the objective tracker, and reacts to loot events so players can quickly see what they still want to farm.

## What Changes

- Add Adventure Guide wishlist controls that let players toggle tracked dungeon and raid loot directly from loot rows.
- Add a `Loot Wishlist` section to the objective tracker that groups tracked items by loot source, supports `Shift+Click` removal, shows current-possession state with a green tick, and shows the best looted item level in parentheses when known.
- Add persistent character-specific wishlist storage using saved variables.
- Add loot-event reactions for tracked items, including other-player loot alerts, loot roll frame tagging, and best-looted item level updates for the player.
- Add localization coverage for all user-facing addon labels across every game locale.

## Capabilities

### New Capabilities
- `adventure-guide-wishlist-toggle`: Track and untrack dungeon and raid loot items from Adventure Guide loot rows using item-level-agnostic item identity.
- `wishlist-tracker-display`: Render tracked items in the objective tracker grouped by loot source, with removal interactions, possession indicators, remembered best looted item levels, and an `Other` fallback group when no source can be identified.
- `wishlist-loot-awareness`: Detect tracked items in loot events and loot roll frames, update player loot state, and alert when other players loot tracked items.
- `wishlist-localization`: Provide localized labels and user-facing strings for all supported World of Warcraft game locales.

### Modified Capabilities
- None.

## Impact

- Affects Adventure Guide UI integration, objective tracker rendering and grouping, saved-variable persistence, loot event handling, inventory/equipment/bank possession checks, and localization data.
- Introduces character-specific wishlist data and runtime state derived from current possession plus remembered best looted item level.
- Depends on World of Warcraft UI APIs for Adventure Guide rows, loot notifications, loot roll frames, inventory/equipment state, bank visibility when available, and localization lookup.
