## MODIFIED Requirements

### Requirement: Player loot updates remembered item level without a popup

When the active character loots a tracked item, the addon SHALL NOT show a tracked-loot popup for the active character's own tracked-item loot, and MAY suppress a simultaneous same-item other-player alert when the addon has just recorded recent self loot for that tracked item. The addon SHALL NOT persist or update remembered best looted item level for that wishlist entry as part of self-loot handling.

#### Scenario: Player loots a tracked item
- **WHEN** the active character loots a tracked item
- **THEN** the addon does not store or update remembered best-looted item-level history for that tracked item
- **AND** the addon does not show a popup alert

#### Scenario: Simultaneous same-item local and remote loot suppresses popup
- **WHEN** the addon has just recorded recent self loot for a tracked item
- **AND** a tracked-loot alert candidate for that same tracked item arrives within the suppression window
- **THEN** the addon suppresses the popup for that alert candidate

### Requirement: Other-player tracked-item loot shows an addon-owned alert without changing local ownership state

When another player loots an item that matches the active character's tracked wishlist, the addon SHALL normalize the relevant alert data immediately into addon-owned values and SHALL show an addon-owned tracked-loot alert popup identifying the looting player and the item when the UI is in a safe state for dialog display. If the UI is already in a safe state, the alert SHALL appear immediately. The popup SHALL preserve the current StaticPopup-style user experience while staying fully addon-owned, including player-name text, item icon, item name, dismiss interaction, and item tooltip on hover. Loot matching SHALL continue to use stable tracked-item identity rather than variant-specific full-link equality, while alert normalization SHALL use the dropped item link extracted from the readable loot event as the alert record's display link so the popup presents the actual dropped variant. The addon SHALL NOT change the active character's possession indicator or persist remembered best-looted item-level history based on another player's loot. Loot-event handling SHALL process incoming loot payloads immediately at the event boundary rather than storing or replaying raw payloads later, SHALL use recent-self-loot correlation instead of comparing the reported looter name against the active player name, SHALL determine whether the `CHAT_MSG_LOOT` payload is safe to inspect before performing any string comparison or pattern matching on it, and SHALL NOT treat generic error suppression around unsafe payload parsing as an acceptable success path.

#### Scenario: Another player loots a tracked item while UI state is safe
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items and the UI is already in a safe state for dialog display
- **THEN** the addon shows the addon-owned tracked-loot alert popup naming the player and presenting the dropped item variant extracted from the readable loot event

#### Scenario: Another player loots a tracked item during unsafe UI state
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items while the UI is not in a safe state for dialog display
- **THEN** the addon shows the addon-owned tracked-loot alert popup after the UI returns to a safe state while preserving the dropped item variant extracted from the original readable event

#### Scenario: Alert popup shows dropped item icon and name
- **WHEN** the addon shows a tracked-loot alert popup for another player's loot and the normalized alert record contains the extracted dropped item link
- **THEN** the popup displays that dropped variant's icon and item name

#### Scenario: Hovering alert item shows tooltip for the dropped variant
- **WHEN** the addon shows a tracked-loot alert popup and the user hovers the popup's item presentation for an alert record with the extracted dropped item link
- **THEN** the addon shows the item tooltip for that dropped variant

#### Scenario: Another player's loot does not modify local state
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the addon does not change the active character's stored item-level history or possession-derived green tick

#### Scenario: Self-loot suppression does not compare looter name
- **WHEN** the addon decides whether to suppress a tracked-loot popup for a tracked item
- **THEN** it uses recent-self-loot correlation instead of comparing the reported loot-event looter name against the active player name

#### Scenario: Loot-event processing normalizes matching identity and display link
- **WHEN** the relevant loot event arrives for another player's tracked item loot
- **THEN** the addon derives the stable tracked-item identity immediately for wishlist matching
- **AND** the addon preserves the extracted dropped item link in the alert record for later alert presentation

#### Scenario: Secret or inaccessible loot-chat payload is rejected before parsing
- **WHEN** the relevant `CHAT_MSG_LOOT` payload is secret or inaccessible to the current caller
- **THEN** the addon rejects that event before any string comparison or pattern matching is attempted
- **AND** the addon does not queue or show a tracked-loot alert from that payload

#### Scenario: Unsafe payload does not become a hidden successful alert path
- **WHEN** the relevant loot event cannot be safely normalized into addon-owned values
- **THEN** the addon does not queue or show a tracked-loot alert from that unsafe payload
- **AND** the addon does not treat generic error suppression around unsafe parsing as a successful tracked-loot detection path

#### Scenario: Unreadable loot payload does not fall back to stored wishlist presentation
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items but the loot payload is unreadable before parsing
- **THEN** the addon does not queue or show a tracked-loot alert from that payload
