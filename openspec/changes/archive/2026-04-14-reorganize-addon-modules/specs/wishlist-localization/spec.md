## MODIFIED Requirements

### Requirement: All user-facing addon labels are localized for supported game locales
The addon SHALL provide localized strings for all user-facing labels and messages across every game locale supported by World of Warcraft. User-facing text SHALL NOT rely on hard-coded English fallbacks except where the game locale itself lacks a provided translation entry. Addon-wide localization primitives SHALL remain shared under `Core/Shared`, and feature modules SHALL consume those shared localized strings rather than duplicating localization sources per feature.

#### Scenario: Objective tracker label is displayed
- **WHEN** the addon renders the objective tracker section title for the active game locale
- **THEN** it uses the localized string for `Loot Wishlist`

#### Scenario: Popup message is displayed
- **WHEN** the addon shows an alert that another player looted a tracked item
- **THEN** the popup text uses localized strings for the active game locale

#### Scenario: Features consume shared localization primitives
- **WHEN** a feature renders user-facing wishlist text
- **THEN** it reads that text from shared localization primitives under `Core/Shared`
- **AND** the feature does not maintain an unrelated duplicate localization source
