## MODIFIED Requirements

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
