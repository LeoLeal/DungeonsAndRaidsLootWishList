## Purpose

Define how the addon reacts to loot events, loot roll frames, and current character possession updates for tracked items.

## Requirements

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

When another player loots an item that matches the active character's tracked wishlist, the addon SHALL normalize the relevant alert data immediately into addon-owned values and SHALL show an addon-owned tracked-loot alert popup identifying the looting player and the item when the UI is in a safe state for dialog display. If the UI is already in a safe state, the alert SHALL appear immediately. The popup SHALL preserve the current StaticPopup-style user experience while staying fully addon-owned, including player-name text, item icon, item name, dismiss interaction, and item tooltip on hover. Loot matching SHALL continue to use stable tracked-item identity rather than variant-specific full-link equality, while alert normalization SHALL use the dropped item link extracted from the readable loot event as the alert record's display link so the popup presents the actual dropped variant. The addon SHALL NOT change the active character's possession indicator or persist remembered best-looted item-level history based on another player's loot. Loot-event handling SHALL process incoming loot payloads immediately at the event boundary rather than storing or replaying raw payloads later, SHALL use recent-self-loot correlation instead of comparing the reported looter name against the active player name, SHALL determine whether the `CHAT_MSG_LOOT` payload is safe to inspect before performing any string comparison or pattern matching on it, and SHALL NOT treat generic error suppression around unsafe payload parsing as an acceptable success path. LootAwareness-owned modules SHALL own loot-event parsing, tracked-item matching, recent-self-loot suppression, alert coordination, and loot-roll reaction coordination, while Core bootstrap code SHALL remain limited to initialization and top-level event wiring.

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

#### Scenario: LootAwareness coordinates loot reactions

- **WHEN** a tracked loot event requires an alert or loot-roll reaction
- **THEN** LootAwareness-owned modules coordinate the reaction flow
- **AND** Core bootstrap code does not remain the owner of feature-specific loot reaction behavior

### Requirement: Loot roll frames are tagged for tracked items

When a loot roll frame appears for a tracked item, the addon SHALL annotate that frame with a `Wishlist` badge so the player can recognize it immediately. The badge SHALL display the Blizzard atlas `Banker` to the left of the `Wishlist` label and SHALL keep both elements visible together as a single tracked-item marker on that loot roll frame.

#### Scenario: Loot roll for a tracked item appears

- **WHEN** a loot roll frame is shown for an item that matches the active character's wishlist
- **THEN** the frame displays a `Wishlist` badge

#### Scenario: Loot roll badge shows Banker atlas icon

- **WHEN** a loot roll frame is shown for an item that matches the active character's wishlist
- **THEN** the `Wishlist` badge includes the Blizzard atlas `Banker` positioned to the left of the `Wishlist` label

### Requirement: Possession state updates from current owned-item scans

The addon SHALL derive the green-tick possession indicator from the active character's currently equipped items, bag contents, and bank contents when bank data is known. The addon SHALL refresh tracker possession state when relevant owned-item state changes.

#### Scenario: Item is sold or destroyed

- **WHEN** the active character no longer has any version of a tracked item in equipped slots, bags, or known bank contents
- **THEN** the green tick is removed from that tracker row while the tracked item remains on the wishlist

#### Scenario: Bank state is unavailable

- **WHEN** the addon has not obtained current bank contents for the active session
- **THEN** possession determination falls back to equipped items and bags without assuming bank ownership

### Requirement: Loot roll badges show assigned wishlist tags

When a loot roll frame appears for a tracked item, the system SHALL display a wishlist badge using the existing badge icon together with the text `Wishlist: <tag1>, <tag2>, <tag3>, ...>` built from the tracked item's assigned tags in catalog order. Tracker filter selections SHALL NOT suppress that badge.

#### Scenario: Loot roll badge includes ordered tags
- **WHEN** a loot roll frame appears for an item that is on the active character's wishlist
- **THEN** the frame shows the wishlist badge icon
- **AND** the badge text reads `Wishlist: <tag1>, <tag2>, <tag3>, ...` using the item's assigned tags in catalog order

#### Scenario: Tracker filtering does not suppress loot roll badge
- **WHEN** a loot roll frame appears for a tracked item that is currently hidden by the tracker tag filter
- **THEN** the loot roll frame still shows the wishlist badge for that tracked item

### Requirement: Loot alerts include assigned wishlist tags

When another player loots a tracked item, the system SHALL format the alert message as `<player> looted an item on your Wishlist(<tag1>, <tag2>, <tag3>, ...)!` using the tracked item's assigned tags in catalog order. Tracker filter selections SHALL NOT suppress alert triggering or alter the displayed tag list.

#### Scenario: Loot alert message includes ordered tags
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the alert message reads `<player> looted an item on your Wishlist(<tag1>, <tag2>, <tag3>, ...)!` using that item's assigned tags in catalog order

#### Scenario: Tracker filtering does not suppress loot alert
- **WHEN** another player loots a tracked item that is currently hidden by the tracker tag filter
- **THEN** the system still triggers the tracked-item loot alert for that item
