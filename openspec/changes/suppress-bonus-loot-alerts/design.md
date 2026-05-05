## Context

LootAwareness currently handles `CHAT_MSG_LOOT` by validating that the looter and message payloads are readable, extracting an item link from known loot-message patterns, matching the item against the active character's wishlist, and queueing an addon-owned alert record when the match is eligible. The parser currently returns only the item link, so once parsing succeeds the event handler no longer knows whether the message represented ordinary loot, pushed loot, roll-won loot, or Bonus loot.

Bonus loot chat lines are readable and include the tracked item link, but they are not actionable for the user because those items cannot be traded. The filter should therefore happen before wishlist matching and alert queueing, while the original alert dialog remains focused on presenting already-normalized eligible alert records.

## Goals / Non-Goals

**Goals:**
- Identify Bonus loot chat messages as non-alertable loot events.
- Suppress tracked-item alert dialogs for Bonus loot even when the dropped item matches the active character's wishlist.
- Preserve existing alert behavior for ordinary other-player tracked-item loot and other currently supported alertable loot patterns.
- Keep the classification inside LootAwareness-owned parsing/event handling modules rather than adding presentation logic to the alert dialog.
- Prefer localized Blizzard global strings for Bonus loot pattern recognition when available.

**Non-Goals:**
- Do not change saved-variable schemas or wishlist storage.
- Do not change Objective Tracker possession state behavior.
- Do not change the alert dialog visual presentation, queueing UX, tooltip behavior, or tag formatting for eligible alerts.
- Do not attempt to determine actual trade eligibility for every possible loot source beyond suppressing known Bonus loot messages.

## Decisions

### Classify loot messages before extracting alert candidates

The parser should expose whether a readable `CHAT_MSG_LOOT` message is alertable, not just which item link it contains. A parser result can carry the extracted `itemLink` plus a classification such as `isBonusLoot` or `alertable`.

Alternative considered: detect Bonus loot in `LootEventHandlers` with an ad hoc string check before calling the parser. This is simpler but scatters message-pattern ownership outside `ChatLootParser`, which already owns safe loot-message parsing and pattern construction.

### Reject non-alertable Bonus loot before wishlist matching

`LootEventHandlers.HandleChatLoot` should stop immediately when the parsed loot event is classified as non-alertable. This ensures Bonus loot never reaches `LootMatcher`, `AlertPresenter.BuildLootAlertRecord`, or `AlertQueue.Enqueue`.

Alternative considered: allow alert records to carry a non-alertable reason and let the presenter or queue suppress them. That leaks event semantics into alert presentation and makes it easier for future code paths to accidentally display suppressed events.

### Preserve existing readable-payload safety checks

The event handler should continue to reject unreadable or secret payloads before string matching. Bonus loot classification must operate only after `ChatLootParser.isReadableLootValue` has accepted the message.

Alternative considered: use protected-call fallback around Bonus loot parsing. Existing specs explicitly reject generic error suppression as a successful unsafe payload path, so this change should stay aligned with the current readable-payload guard model.

### Prefer Blizzard-localized patterns over hard-coded English

The implementation should use the relevant Blizzard global string for `<Player> receives Bonus loot: <Item>` if available in the client, converting it to a Lua pattern in the same spirit as the existing loot-message pattern handling. If no localized global is available, the implementation should keep any fallback narrow and isolated inside the parser.

Alternative considered: hard-code the observed English substring `receives Bonus loot:`. That may work in one locale but would make alert suppression inconsistent across localized clients.

## Risks / Trade-offs

- **Risk:** The exact Blizzard global name for Bonus loot may vary or be unavailable in some client versions. → **Mitigation:** Isolate Bonus loot pattern lookup in `ChatLootParser` and preserve current alert behavior when no Bonus loot pattern can be recognized.
- **Risk:** A broad Bonus loot string match could suppress ordinary loot in some locale or edge case. → **Mitigation:** Match complete localized message patterns when possible and require an item link to be present in the same parsed message.
- **Risk:** Changing parser return shape could break callers expecting a raw item link. → **Mitigation:** Either add a new parser function for normalized loot events or retain the existing item-link extraction function as a compatibility wrapper.
- **Risk:** Bonus loot may still trigger tracker refresh from `CHAT_MSG_LOOT`. → **Mitigation:** This change only suppresses alert queueing; existing refresh behavior may remain unchanged unless implementation discovers it is coupled to alert eligibility.
