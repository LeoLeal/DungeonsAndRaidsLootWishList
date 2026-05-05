## 1. Parser Classification

- [ ] 1.1 Inspect Blizzard loot global strings available in the target client and identify the localized Bonus loot message constant for `<Player> receives Bonus loot: <Item>`.
- [ ] 1.2 Extend `LootAwareness/ChatLootParser.lua` with a normalized loot-message parsing path that returns the extracted item link and whether the message is alertable.
- [ ] 1.3 Keep existing readable-payload guards intact before any Bonus loot string matching or pattern matching occurs.
- [ ] 1.4 Preserve compatibility for existing item-link extraction callers, either by retaining `extractItemLinkFromLootMessage` as a wrapper or by updating all callers deliberately.

## 2. Alert Eligibility Handling

- [ ] 2.1 Update `LootAwareness/LootEventHandlers.lua` to reject parsed non-alertable Bonus loot before wishlist matching.
- [ ] 2.2 Verify Bonus loot events do not call `LootMatcher.matchTrackedItem`, `AlertPresenter.BuildLootAlertRecord`, or `AlertQueue.Enqueue`.
- [ ] 2.3 Verify ordinary other-player tracked-item loot still queues the existing addon-owned alert record with the dropped item link.
- [ ] 2.4 Confirm recent-self-loot suppression and unreadable-payload rejection behavior remain unchanged.

## 3. Verification

- [ ] 3.1 Add or update pure verification coverage for `ChatLootParser` Bonus loot classification if a local Lua test harness exists.
- [ ] 3.2 Add or update handler-level verification showing a tracked Bonus loot message is ignored and a comparable ordinary loot message remains alertable.
- [ ] 3.3 Perform in-client verification with a sample message matching `<Player> receives Bonus loot: <Item>` for a tracked item and confirm no alert dialog appears.
- [ ] 3.4 Perform in-client regression verification that ordinary other-player tracked-item loot still shows the alert dialog with the dropped variant and wishlist tags.
