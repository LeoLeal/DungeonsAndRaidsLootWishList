## MODIFIED Requirements

### Requirement: Loot Alert Dialog Configuration

The system SHALL present an addon-owned tracked-loot alert popup for tracked items looted by another player. The popup MUST preserve a StaticPopup-like user experience while remaining fully addon-owned, including the player-name text, item icon, item name, item tooltip on hover, a single `OK` dismissal action, Escape-key dismissal, and NO timeout. When the loot event yields a readable dropped item link, the popup SHALL present that dropped variant for the item icon, item name, and primary alert tooltip content. When the alerted item supports equipped-item comparison, hovering the alert item MUST continue to show addon-owned comparison panes for the player's currently equipped items using the dropped variant as the primary compared item.

#### Scenario: Displaying the Alert Dialog with dropped variant presentation
- **WHEN** the tracked-item alert dialog is shown for a loot event that includes a readable dropped item link
- **THEN** it displays the text prompt, the item icon, the item name, and interactive item presentation for that dropped variant and waits indefinitely for the user to click `OK` or dismiss it with Escape

#### Scenario: Deferred display preserves the dropped variant
- **WHEN** the dialog is shown after being deferred until a safe UI state
- **THEN** it presents the same dropped item variant, text, and dismissal behavior that would have been shown immediately

#### Scenario: Hovering the alert item shows a tooltip for the dropped variant
- **WHEN** the tracked-item alert dialog is shown and the user hovers the item presentation for an alert with a readable dropped item link
- **THEN** the popup shows the tooltip for that dropped item variant

#### Scenario: Hovering an equippable alert item shows equipped comparison against the dropped variant
- **WHEN** the tracked-item alert dialog is shown and the user hovers an alerted item with a readable dropped item link that supports equipped-item comparison
- **THEN** the popup shows the dropped item's tooltip together with addon-owned equipped comparison tooltips for the player's currently equipped items styled to match Blizzard compare panes

#### Scenario: Leaving the alert item hides comparison panes
- **WHEN** the tracked-item alert dialog is showing equipped comparison for an alerted item
- **THEN** moving the pointer away from the item presentation or dismissing the dialog hides both the primary alert tooltip and any comparison panes

#### Scenario: Unreadable loot payload does not produce an alert dialog
- **WHEN** the relevant tracked-loot event payload does not provide a readable dropped item link
- **THEN** the addon does not show a tracked-loot alert dialog from that payload
