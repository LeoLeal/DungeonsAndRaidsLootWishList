## MODIFIED Requirements

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
