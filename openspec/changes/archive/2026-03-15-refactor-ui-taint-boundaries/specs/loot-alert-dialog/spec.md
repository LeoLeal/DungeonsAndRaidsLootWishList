## MODIFIED Requirements

### Requirement: Loot Alert Dialog Configuration

The system SHALL present a custom loot alert dialog for tracked items looted by another player. The dialog MUST display the alert text, an interactive item presentation, a single `OK` dismissal action, and NO timeout. The implementation MAY use Blizzard's `StaticPopupDialog` infrastructure when that path is safe, or an addon-owned equivalent dialog surface when the native popup path would taint Blizzard UI execution.

#### Scenario: Displaying the Alert Dialog

- **WHEN** the tracked-item alert dialog is shown
- **THEN** it displays the text prompt, an interactive item presentation for the tracked item, and waits indefinitely for the user to click `OK` or dismiss it with Escape

#### Scenario: Deferred display preserves the same dialog experience

- **WHEN** the dialog is shown after being deferred until a safe UI state
- **THEN** it presents the same text, item presentation, and dismissal behavior as an immediately shown alert dialog

### Requirement: Loot Alert Dialog Formatting

The system SHALL format the alert message text to be white (`|cFFFFFFFF`), and the looting player's name SHALL be highlighted in a distinct orange color (`|cFFFF8000`) to stand out. This formatting requirement SHALL remain the same whether the dialog is shown immediately or reconstructed later from normalized addon-owned alert data.

#### Scenario: Highlighting the Player Name

- **WHEN** the active character receives a loot alert for another player
- **THEN** that player's name is rendered in the distinct alert color within the dialog text

#### Scenario: Deferred alert preserves message formatting

- **WHEN** the addon shows a previously deferred loot alert
- **THEN** the dialog still renders white body text and the player's name in the distinct alert color
