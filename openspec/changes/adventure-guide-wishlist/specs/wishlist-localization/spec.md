## ADDED Requirements

### Requirement: All user-facing addon labels are localized for supported game locales
The addon SHALL provide localized strings for all user-facing labels and messages across every game locale supported by World of Warcraft. User-facing text SHALL NOT rely on hard-coded English fallbacks except where the game locale itself lacks a provided translation entry.

#### Scenario: Objective tracker label is displayed
- **WHEN** the addon renders the objective tracker section title for the active game locale
- **THEN** it uses the localized string for `Loot Wishlist`

#### Scenario: Popup message is displayed
- **WHEN** the addon shows an alert that another player looted a tracked item
- **THEN** the popup text uses localized strings for the active game locale

### Requirement: Interactive wishlist markers are localized
The addon SHALL localize user-facing text associated with interactive wishlist markers, including loot roll tags and any visible checkbox labels or tooltips used by the addon.

#### Scenario: Loot roll tag is shown
- **WHEN** the addon annotates a loot roll frame for a tracked item
- **THEN** the `Wishlist` marker uses the localized string for the active game locale

#### Scenario: Checkbox help text is shown
- **WHEN** the addon displays any user-facing checkbox label or tooltip in the Adventure Guide
- **THEN** that text uses the localized string for the active game locale

### Requirement: Localization must cover fallback tracker groups
The addon SHALL localize tracker grouping labels introduced by wishlist source grouping, including the fallback `Other` group.

#### Scenario: Unknown-source item is rendered in the tracker
- **WHEN** a tracked item has no identified loot source and is shown under the fallback group
- **THEN** the group label uses the localized string for `Other` in the active game locale
