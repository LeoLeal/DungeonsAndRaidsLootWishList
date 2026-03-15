## Purpose

Define how the addon reacts to loot events, loot roll frames, and current character possession updates for tracked items.

## Requirements

### Requirement: Player loot updates remembered item level without a popup

When the active character loots a tracked item, the addon SHALL update the remembered best looted item level for that wishlist entry if the newly looted item level is higher than the stored value. The addon SHALL NOT show a loot popup alert for the active character's own tracked-item loot.

#### Scenario: Player loots a tracked item for the first time

- **WHEN** the active character loots a tracked item and no best looted item level has been stored yet
- **THEN** the addon stores that looted item level for the tracked item and does not show a popup alert

#### Scenario: Player loots a higher item-level version

- **WHEN** the active character loots a tracked item at a higher item level than the remembered value
- **THEN** the addon replaces the remembered best looted item level with the higher value and does not show a popup alert

#### Scenario: Player loots a lower item-level version

- **WHEN** the active character loots a tracked item at a lower item level than the remembered value
- **THEN** the addon keeps the existing remembered best looted item level and does not show a popup alert

### Requirement: Other-player tracked-item loot shows an alert without changing local ownership state

When another player loots an item that matches the active character's tracked wishlist, the addon SHALL normalize the relevant alert data immediately and SHALL show an interactive item alert dialog identifying the looting player and the item when the UI is in a safe state for dialog display. If the UI is already in a safe state, the alert MAY appear immediately. The addon SHALL NOT change the active character's possession indicator or remembered best looted item level based on another player's loot.

#### Scenario: Another player loots a tracked item while UI state is safe

- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items and the UI is already in a safe state for dialog display
- **THEN** the addon shows the tracked-item alert dialog naming the player and providing the interactive item presentation

#### Scenario: Another player loots a tracked item during unsafe UI state

- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items while the UI is not in a safe state for dialog display
- **THEN** the addon shows the tracked-item alert dialog after the UI returns to a safe state

#### Scenario: Another player's loot does not modify local state

- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the addon does not change the active character's stored best looted item level or possession-derived green tick

### Requirement: Loot roll frames are tagged for tracked items

When a loot roll frame appears for a tracked item, the addon SHALL annotate that frame with a `Wishlist` tag so the player can recognize it immediately.

#### Scenario: Loot roll for a tracked item appears

- **WHEN** a loot roll frame is shown for an item that matches the active character's wishlist
- **THEN** the frame displays a `Wishlist` tag

### Requirement: Possession state updates from current owned-item scans

The addon SHALL derive the green-tick possession indicator from the active character's currently equipped items, bag contents, and bank contents when bank data is known. The addon SHALL refresh tracker possession state when relevant owned-item state changes.

#### Scenario: Item is sold or destroyed

- **WHEN** the active character no longer has any version of a tracked item in equipped slots, bags, or known bank contents
- **THEN** the green tick is removed from that tracker row while the tracked item remains on the wishlist

#### Scenario: Bank state is unavailable

- **WHEN** the addon has not obtained current bank contents for the active session
- **THEN** possession determination falls back to equipped items and bags without assuming bank ownership
