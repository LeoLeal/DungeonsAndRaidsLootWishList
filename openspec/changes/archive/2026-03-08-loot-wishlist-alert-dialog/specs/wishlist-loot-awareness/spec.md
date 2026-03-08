## MODIFIED Requirements

### Requirement: Other-player tracked-item loot shows an alert without changing local ownership state

When another player loots an item that matches the active character's tracked wishlist, the addon SHALL show an interactive item alert dialog (LOOT_WISHLIST_ALERT) identifying the looting player and the item. The addon SHALL NOT change the active character's possession indicator or remembered best looted item level based on another player's loot.

#### Scenario: Another player loots a tracked item

- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the addon shows the LOOT_WISHLIST_ALERT dialog naming the player and providing the interactive item frame

#### Scenario: Another player's loot does not modify local state

- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the addon does not change the active character's stored best looted item level or possession-derived green tick
