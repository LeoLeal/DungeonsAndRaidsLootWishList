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

### Requirement: Loot roll frames are tagged for tracked items

When a loot roll frame is visible for a tracked item, the addon SHALL annotate that visible frame with a `Wishlist` badge so the player can recognize it immediately. The badge SHALL display the Blizzard atlas `Banker` to the left of the `Wishlist` label and SHALL keep both elements visible together as a single tracked-item marker on that loot roll frame. Badge visibility SHALL be derived from the frame's current `rollID`, and the addon SHALL clear addon-owned badge state when a loot roll frame hides or is later reused for a different roll. If the frame has a non-nil current `rollID` and the addon can read that roll's current item link through the normal read-only loot-roll APIs at synchronization time, the addon SHALL synchronize the badge immediately and SHALL NOT defer that visible badge update until combat ends. If that current roll state is not yet readable, the addon SHALL keep the badge hidden for that frame and SHALL retry on a later roll event or frame lifecycle signal instead of replaying stale badge work only after combat ends.

#### Scenario: Visible tracked loot roll shows a wishlist badge

- **WHEN** a loot roll frame is shown for an item that matches the active character's wishlist
- **THEN** the frame displays a `Wishlist` badge

#### Scenario: Loot roll badge shows Banker atlas icon

- **WHEN** a loot roll frame is shown for an item that matches the active character's wishlist
- **THEN** the `Wishlist` badge includes the Blizzard atlas `Banker` positioned to the left of the `Wishlist` label

#### Scenario: Recycled frame for an untracked roll does not keep a stale badge

- **WHEN** a loot roll frame that previously showed a tracked-item badge is hidden and later reused for an item that is not on the active character's wishlist
- **THEN** the reused frame does not display the old `Wishlist` badge

#### Scenario: Queued tracked roll gains a badge when promoted into a visible frame

- **WHEN** a tracked loot roll starts while all visible Blizzard loot roll frames are already occupied
- **AND** that tracked roll later becomes visible after one of those frames is reused
- **THEN** the newly visible frame displays the `Wishlist` badge for that tracked roll

#### Scenario: Visible tracked roll badges during combat without waiting for combat end

- **WHEN** a tracked loot roll becomes visible while the player is in combat
- **AND** the frame has a non-nil current `rollID`
- **AND** the addon can read that roll's current item link through the normal read-only loot-roll APIs at synchronization time
- **THEN** the frame displays the `Wishlist` badge during combat
- **AND** the addon does not wait until combat ends to apply that visible badge update

#### Scenario: Unreadable current roll state stays hidden until a later sync opportunity

- **WHEN** a visible loot roll frame does not yet have a readable current roll state for badge synchronization
- **THEN** the frame does not show a stale `Wishlist` badge from an earlier roll
- **AND** the addon waits for a later roll event or frame lifecycle signal to retry synchronization
- **AND** the addon does not rely on a blanket post-combat replay of that stale frame work

### Requirement: Possession state updates from current owned-item scans

The addon SHALL derive the green-tick possession indicator from the active character's currently equipped items, bag contents, and bank contents when bank data is known. The addon SHALL refresh tracker possession state when relevant owned-item state changes.

#### Scenario: Item is sold or destroyed

- **WHEN** the active character no longer has any version of a tracked item in equipped slots, bags, or known bank contents
- **THEN** the green tick is removed from that tracker row while the tracked item remains on the wishlist

#### Scenario: Bank state is unavailable

- **WHEN** the addon has not obtained current bank contents for the active session
- **THEN** possession determination falls back to equipped items and bags without assuming bank ownership

### Requirement: Loot roll badges show assigned wishlist tags

When a loot roll frame is visible for a tracked item, the system SHALL display a wishlist badge using the existing badge icon together with the text `Wishlist: <tag1>, <tag2>, <tag3>, ...>` built from the tracked item's assigned tags in catalog order. The badge text SHALL be recomputed from the frame's current roll assignment whenever a visible loot roll frame is reused for a different tracked roll. If the frame has a non-nil current `rollID` and the addon can read the current tracked state for that roll through normal read-only APIs, tag text synchronization SHALL happen immediately even during combat rather than waiting for a blanket after-combat replay. If that current tracked state is not yet readable, the frame SHALL NOT keep stale tag text from an earlier roll while waiting for a later sync opportunity. Tracker filter selections SHALL NOT suppress that badge, and simultaneous visible rolls for the same tracked item SHALL each show the correct badge text for their own current roll.

#### Scenario: Loot roll badge includes ordered tags
- **WHEN** a loot roll frame appears for an item that is on the active character's wishlist
- **THEN** the frame shows the wishlist badge icon
- **AND** the badge text reads `Wishlist: <tag1>, <tag2>, <tag3>, ...` using the item's assigned tags in catalog order

#### Scenario: Recycled frame updates badge text for a different tracked roll
- **WHEN** a loot roll frame that previously displayed one tracked item's wishlist tags is later reused for a different tracked item
- **THEN** the badge text updates to the newly assigned tracked item's tag list
- **AND** the frame does not keep the previous tracked item's tag text

#### Scenario: Tracker filtering does not suppress loot roll badge
- **WHEN** a loot roll frame appears for a tracked item that is currently hidden by the tracker tag filter
- **THEN** the loot roll frame still shows the wishlist badge for that tracked item

#### Scenario: Duplicate tracked drops badge independently
- **WHEN** two visible loot roll frames at the same time both correspond to the same tracked wishlist item
- **THEN** each visible frame shows the wishlist badge for its own current roll
- **AND** neither frame loses or inherits badge text because another visible frame is showing the same tracked item

### Requirement: Loot alerts include assigned wishlist tags

When another player loots a tracked item, the system SHALL format the alert message as `<player> looted an item on your Wishlist(<tag1>, <tag2>, <tag3>, ...)!` using the tracked item's assigned tags in catalog order. Tracker filter selections SHALL NOT suppress alert triggering or alter the displayed tag list.

#### Scenario: Loot alert message includes ordered tags
- **WHEN** another player loots an item that matches one of the active character's tracked wishlist items
- **THEN** the alert message reads `<player> looted an item on your Wishlist(<tag1>, <tag2>, <tag3>, ...)!` using that item's assigned tags in catalog order

#### Scenario: Tracker filtering does not suppress loot alert
- **WHEN** another player loots a tracked item that is currently hidden by the tracker tag filter
- **THEN** the system still triggers the tracked-item loot alert for that item

