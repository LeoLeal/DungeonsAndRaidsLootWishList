## 1. Normalize alert records with dropped variant data

- [x] 1.1 Update loot-event handling to reject unreadable payloads before parsing and pass the extracted dropped item link into alert normalization.
- [x] 1.2 Simplify `BuildLootAlertRecord` so it keeps tracked-item gating but requires the caller-provided dropped item link for alert display.

## 2. Present the dropped variant in the alert dialog

- [x] 2.1 Update `WishListAlert.lua` helpers to use `record.itemLink` for icon, item name, and primary tooltip presentation.
- [x] 2.2 Remove stored-link fallback logic from the alert display path.
- [x] 2.3 Preserve compare-pane behavior as equipped-item comparison against the dropped variant rather than replacing compare content with the dropped item link.

## 3. Verify alert behavior

- [x] 3.1 Add or update tests for any pure alert-record normalization logic that can be covered locally.
- [ ] 3.2 Verify in-game or manual test flows for immediate alerts, deferred alerts, tooltip hover, compare panes, and unreadable-payload suppression.
