## ADDED Requirements

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
