## MODIFIED Requirements

### Requirement: All user-facing addon labels are localized for supported game locales
The addon SHALL provide localized strings for all user-facing labels and messages across every game locale supported by World of Warcraft. User-facing text SHALL NOT rely on hard-coded English fallbacks except where the game locale itself lacks a provided translation entry. Addon-wide localization primitives SHALL remain shared under `Core/Shared`, and feature modules SHALL consume those shared localized strings rather than duplicating localization sources per feature. Regional locale variants that share identical translations with their parent locale (e.g., `enGB`/`enUS`, `esMX`/`esES`) SHALL alias the parent table rather than duplicating all string entries. Translation strings SHALL use correct diacritical marks and typographic conventions for their locale.

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

#### Scenario: Regional locale variant aliases parent locale
- **WHEN** a regional locale variant (e.g., `enGB`, `esMX`) has identical translations to its parent locale (e.g., `enUS`, `esES`)
- **THEN** the locale data aliases the parent table instead of duplicating all string entries
- **AND** `getSupportedLocales()` still includes the regional variant in its returned list

#### Scenario: Translation strings contain correct diacritical marks
- **WHEN** the addon displays a localized string for deDE, esES, frFR, or ptBR
- **THEN** all characters with diacritical marks (umlauts, accents, cedillas, tildes) are rendered correctly
- **AND** the stored string data contains the proper Unicode characters rather than ASCII approximations
