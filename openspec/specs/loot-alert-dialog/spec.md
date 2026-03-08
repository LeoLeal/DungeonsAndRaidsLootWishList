# Loot Alert Dialog

## Purpose

TBD: Manage the formatting and presentation of the custom loot alert dialog for wishlisted items.

## Requirements

### Requirement: Loot Alert Dialog Configuration

The system SHALL define a new custom `StaticPopupDialog` named `"LOOT_WISHLIST_ALERT"`. This dialog MUST be configured with `hasItemFrame = 1` to natively support item icons, color-coded names, and cursor tooltips when the player hovers over the item. The dialog MUST have a single "OK" button and NO timeout.

#### Scenario: Displaying the Alert Dialog

- **WHEN** the `LOOT_WISHLIST_ALERT` dialog is summoned
- **THEN** it displays the text prompt, an interactive item frame for the tracked item, and waits indefinitely for the user to click "OK" or press Escape.

### Requirement: Loot Alert Dialog Formatting

The system SHALL format the alert message text to be white (`|cFFFFFFFF`), and the looting player's name SHALL be highlighted in a distinct orange color (`|cFFFF8000` - legendary orange) to stand out.

#### Scenario: Highlighting the Player Name

- **WHEN** the active character receives a loot alert for another player
- **THEN** that player's name is rendered in the distinct alert color within the dialog text.
