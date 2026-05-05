## MODIFIED Requirements

### Requirement: Other-player tracked-item loot shows an addon-owned alert without changing local ownership state

When another player loots an alertable item that matches the active character's tracked wishlist, the addon SHALL normalize the relevant alert data immediately into addon-owned values and SHALL show an addon-owned tracked-loot alert popup identifying the looting player and the item when the UI is in a safe state for dialog display. If the UI is already in a safe state, the alert SHALL appear immediately. The addon SHALL NOT queue or show a tracked-loot alert for Bonus loot events, even when the Bonus loot item matches the active character's wishlist, because Bonus loot is not tradeable to the active character. The popup SHALL preserve the current StaticPopup-style user experience while staying fully addon-owned, including player-name text, item icon, item name, dismiss interaction, and item tooltip on hover. Loot matching SHALL continue to use stable tracked-item identity rather than variant-specific full-link equality, while alert normalization SHALL use the dropped item link extracted from the readable loot event as the alert record's display link so the popup presents the actual dropped variant. The addon SHALL NOT change the active character's possession indicator or persist remembered best-looted item-level history based on another player's loot. Loot-event handling SHALL process incoming loot payloads immediately at the event boundary rather than storing or replaying raw payloads later, SHALL use recent-self-loot correlation instead of comparing the reported looter name against the active player name, SHALL determine whether the `CHAT_MSG_LOOT` payload is safe to inspect before performing any string comparison or pattern matching on it, SHALL classify non-alertable Bonus loot before alert record construction, and SHALL NOT treat generic error suppression around unsafe payload parsing as an acceptable success path. LootAwareness-owned modules SHALL own loot-event parsing, tracked-item matching, recent-self-loot suppression, Bonus loot suppression, alert coordination, and loot-roll reaction coordination, while Core bootstrap code SHALL remain limited to initialization and top-level event wiring.

#### Scenario: Another player loots a tracked item while UI state is safe

- **WHEN** another player loots an alertable item that matches one of the active character's tracked wishlist items and the UI is already in a safe state for dialog display
- **THEN** the addon shows the addon-owned tracked-loot alert popup naming the player and presenting the dropped item variant extracted from the readable loot event

#### Scenario: Another player loots a tracked item during unsafe UI state

- **WHEN** another player loots an alertable item that matches one of the active character's tracked wishlist items while the UI is not in a safe state for dialog display
- **THEN** the addon shows the addon-owned tracked-loot alert popup after the UI returns to a safe state while preserving the dropped item variant extracted from the original readable event

#### Scenario: Other-player Bonus loot is ignored

- **WHEN** the addon receives a readable loot-chat message in the form `<Player> receives Bonus loot: <Item>`
- **AND** `<Item>` matches one of the active character's tracked wishlist items
- **THEN** the addon does not queue or show a tracked-loot alert dialog
- **AND** the addon does not build an alert record for that Bonus loot event

#### Scenario: Ordinary other-player loot remains alertable

- **WHEN** another player receives an ordinary alertable loot drop for an item matching one of the active character's tracked wishlist items
- **THEN** the addon remains eligible to show the addon-owned tracked-loot alert popup for that event

#### Scenario: Alert popup shows dropped item icon and name

- **WHEN** the addon shows a tracked-loot alert popup for another player's alertable loot and the normalized alert record contains the extracted dropped item link
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

- **WHEN** the relevant loot event arrives for another player's alertable tracked item loot
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

#### Scenario: LootAwareness coordinates loot reactions

- **WHEN** a tracked loot event requires an alert or loot-roll reaction
- **THEN** LootAwareness-owned modules coordinate the reaction flow
- **AND** Core bootstrap code does not remain the owner of feature-specific loot reaction behavior
