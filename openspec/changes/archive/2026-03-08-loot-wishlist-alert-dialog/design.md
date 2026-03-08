## Context

Currently, `DungeonsAndRaidsLootWishList` notifies the user of tracked item drops using `RaidNotice_AddMessage` and `UIErrorsFrame:AddMessage`. These message types are transient and lack interactivity, making it difficult for users to inspect the looted item's tooltip if they miss the short visual window. A prominent dialog box solves this issue.

## Goals / Non-Goals

**Goals:**

- Replace the ephemeral text alert with a structured, interactive `StaticPopupDialog`.
- Provide an embedded, natively hoverable item icon and name within the alert dialog.
- Highlight the looting player's name distinctly.
- Provide a slash command to test the new dialog visually.

**Non-Goals:**

- Do not create a completely custom frame from scratch; stick to Blizzard's native `StaticPopupDialogs` API to match the game's aesthetic and behavior.
- Do not track loot history natively inside the addon; the dialog is just an instantaneous alert.

## Decisions

**Decision 1: Use `hasItemFrame` on `StaticPopupDialogs` instead of a custom UI frame.**

- _Rationale:_ Building custom frames for layout and text takes significant effort just to mimic the native feel. Using the built-in `hasItemFrame = 1` perfectly matches the behavior of native BoP confirmation dialogs and standardizes the item hovering logic.
- _Alternatives Considered:_ Building a `SimpleHTML` or custom `Frame` from scratch. Rejected due to complexity.

**Decision 2: Player Name Formatting.**

- _Rationale:_ Because the dialog text uses simple formatting, we will prepend and append `|cFFFFFFFF` (White) to the main text, and `|cFFFF8000` (Orange) to the parsed player name inside `namespace.ShowLootDialog`. This ensures the player's name stands out brilliantly against a crisp white message, avoiding the default gold text of the dialog box.

**Decision 3: Update `namespace.ShowAlert` Signature.**

- _Rationale:_ Returning a raw generated string to `ShowAlert` makes it hard to extract the `itemLink` needed for the `hasItemFrame` API. We will update the signature to `namespace.ShowAlert(playerName, itemLink, rawMessage)` or process it within `HandleChatLoot` so that `StaticPopup_Show` receives the `itemLink` specifically. Actually, the easiest approach is to have `HandleChatLoot` call the new popup directly, passing the raw string as `text_arg1` and the `itemLink` as the hidden item pointer.

## Risks / Trade-offs

- **[Risk] Intrusiveness:** The dialog will steal focus and require the user to dismiss it (click OK or press ESC). If 10 tracked items drop simultaneously, 10 popups might queue.
  - _Mitigation:_ The `StaticPopupDialogs` queue limits how many display at once natively, protecting the screen space. We accept this trade-off because missing the alert is worse than having to dismiss it.
- **[Risk] Taint:** If we manipulate the `GameTooltip` or `StaticPopup` incorrectly, we could invite taint.
  - _Mitigation:_ `hasItemFrame` is entirely native. We just pass `link` to `StaticPopup_Show("NAME", nil, nil, data)` and the native code handles the tooltip securely.
