## 1. Saved data and item identity

- [ ] 1.1 Define the character-specific saved-variable structure for tracked items and remembered best looted item levels.
- [ ] 1.2 Implement stable item identity normalization so Adventure Guide entries, loot events, and owned items resolve to the same wishlist key.
- [ ] 1.3 Add source-resolution logic that maps tracked items to dungeon or raid names and falls back to `Other` when no source can be identified.

## 2. Adventure Guide wishlist controls

- [ ] 2.1 Hook Adventure Guide dungeon and raid loot rows to inject a wishlist toggle using native Blizzard checkbox visuals.
- [ ] 2.2 Sync checkbox state from the character wishlist and keep row updates idempotent as Adventure Guide content refreshes.
- [ ] 2.3 Implement checkbox toggle behavior to add and remove tracked items without coupling it to ownership or loot-history state.

## 3. Objective tracker rendering

- [ ] 3.1 Add a `Loot Wishlist` objective-tracker section that appears only when the active character has tracked items.
- [ ] 3.2 Render tracked items grouped by loot source with localized source headings and an `Other` fallback group.
- [ ] 3.3 Render tracker rows with current-possession green ticks, remembered best item level suffixes, and native Blizzard visual patterns.
- [ ] 3.4 Reuse the native objective-tracker add-entry animation when a newly tracked item first appears in the wishlist section.
- [ ] 3.5 Implement `Shift+Click` removal for tracker entries and refresh the grouped tracker output afterward.

## 4. Loot awareness and possession refresh

- [ ] 4.1 Detect player loot for tracked items and update remembered best looted item levels without showing self-loot popup alerts.
- [ ] 4.2 Detect other-player loot for tracked items and show localized alert popups without mutating local wishlist ownership state.
- [ ] 4.3 Annotate loot roll frames for tracked items with a localized `Wishlist` tag using native Blizzard UI patterns where practical.
- [ ] 4.4 Recompute current possession from equipped items, bags, and bank contents when known, and remove the green tick when no owned copy remains.
- [ ] 4.5 Refresh tracker possession state on relevant bag, equipment, bank, and loot-driven updates.

## 5. Localization and verification

- [ ] 5.1 Define localization entries for all user-facing strings, including `Loot Wishlist`, `Wishlist`, `Other`, popup text, and any Adventure Guide marker text.
- [ ] 5.2 Ensure every supported World of Warcraft locale has the required translation keys or explicit fallback handling.
- [ ] 5.3 Verify the change against the proposal, design, and specs by checking Adventure Guide toggling, grouped tracker rendering, loot alerts, loot-roll tagging, possession ticks, and localization coverage.
