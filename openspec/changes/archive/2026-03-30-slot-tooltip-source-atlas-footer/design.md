## Context

Slot-mode tracker tooltips currently append a single gray footer line built in `LootWishList.lua` and rendered in `TrackerUI.lua`. That footer line uses localized `Drops from:` text from `Locales.lua`, followed by the instance name for dungeon items or the instance-and-boss pair for raid items. The behavior is correct, but visually it adds more prose than the surrounding Blizzard-native tooltip treatment and repeats meaning that can be conveyed more compactly with iconography.

This is a narrow presentation change, but it still benefits from an explicit design because it touches tooltip formatting, Blizzard atlas usage, and localization scope. The addon should keep the existing data flow and slot-mode-only behavior while changing the footer prefix from text to a dungeon-or-raid atlas and cleaning up the now-unused localization keys that previously powered that text prefix.

## Goals / Non-Goals

**Goals:**
- Replace the `Drops from:` text prefix in slot-mode tracker tooltip footers with a Blizzard atlas icon.
- Show a dungeon icon for dungeon or non-raid sources and a raid icon for raid sources.
- Preserve the existing footer content after the prefix: `<Instance Name>` for dungeon/non-raid items and `<Instance Name> - <Boss Name>` for raid items.
- Remove the obsolete localized `DROPS_FROM` and `DROPS_FROM_RAID` entries from `Locales.lua` once the slot-mode footer no longer uses them.
- Keep the change presentation-only so it does not alter wishlist storage, grouping, tooltip anchoring, or tooltip ownership.

**Non-Goals:**
- Changing loot-source mode tooltip behavior.
- Changing tracker row text or grouping logic.
- Introducing new persisted footer metadata.
- Adding difficulty-specific, Mythic+, or other source-subtype icons in this change.

## Decisions

### 1. Use inline atlas markup in the existing footer line pipeline

The slot-mode footer will remain a single tooltip line rendered through the current `trackerTooltip:AddLine(...)` path, but the string content will begin with inline atlas markup rather than localized `Drops from:` text.

Target shape:
- dungeon / non-raid source: `[Dungeon Atlas] <Instance Name>`
- raid source: `[Raid Atlas] <Instance Name> - <Boss Name>`

Rationale:
- This keeps the change narrowly scoped to footer formatting rather than introducing a structured tooltip row-rendering system.
- It preserves the existing tooltip surface and avoids deeper manipulation of tooltip internals.
- It matches the user's preferred Option A: icon-only prefix, no remaining `Drops from:` label text.

Alternatives considered:
- Keep the `Drops from:` text and prepend an icon: rejected because the user wants the text prefix replaced, not augmented.
- Convert tooltip footer data into a structured payload object with separate atlas and text fields: rejected for now because it adds presentation machinery without enough benefit for a single-line footer.

### 2. Keep source-kind selection binary: dungeon/non-raid vs raid

Footer icon choice will be based on the same raid-vs-non-raid distinction already used by the tooltip footer path.

- Raid sources use the raid atlas.
- Dungeon and other non-raid sources use the dungeon atlas.

Rationale:
- The current footer behavior already branches this way for boss-name inclusion.
- It avoids introducing new source taxonomies or difficulty semantics.
- It keeps the visual distinction aligned with the addon's existing source model.

Alternatives considered:
- Introduce additional icon variants for different non-raid content types: rejected because the current change only asks for dungeon vs raid.

### 3. Remove slot-mode footer localization strings from the visual prefix path

The visible slot-mode footer prefix should no longer depend on localized `DROPS_FROM` or `DROPS_FROM_RAID` strings. Only the source names themselves remain localized through Blizzard APIs such as instance and boss name resolution. Because the icon-only footer removes the last intended use of those prefix strings, the change should also remove the obsolete locale entries from `Locales.lua` across supported languages.

Rationale:
- This simplifies localization burden for the footer prefix.
- It avoids mixing iconography with an unnecessary textual label.
- It keeps locale-sensitive content where it matters most: the resolved instance and boss names.
- It prevents stale, unused localization entries from lingering after the footer format changes.

Alternatives considered:
- Keep `DROPS_FROM` strings in `Locales.lua` as the rendered prefix: rejected because the change goal is to replace that prefix visually.

### 4. Use the confirmed `Dungeon` and `Raid` atlases from `objecticonsatlas`

The implementation should use the already-confirmed Blizzard atlas names `Dungeon` and `Raid` from `objecticonsatlas` for inline slot-mode tooltip footer markup.

Rationale:
- The atlas names are now known, so the implementation can stay narrowly focused on footer formatting rather than atlas discovery.
- Using confirmed Blizzard atlases reduces the risk of broken or invisible footer icons.

Alternatives considered:
- Continue treating atlas selection as an open discovery task: rejected because the relevant atlas names are already known.

## Risks / Trade-offs

- [Confirmed atlas names may not render cleanly inline in tooltip text at the first chosen size] → Validate atlas appearance in the tracker tooltip and keep sizing/spacing adjustments narrowly scoped.
- [Tooltip inline atlas markup may look too cramped next to long instance names] → Tune icon size or spacing while keeping the footer as a single gray line.
- [Removing the text prefix may reduce clarity for some players] → Use source-type-specific Blizzard iconography so the remaining line still clearly reads as loot-source metadata.
- [Non-English locales may expose spacing or punctuation issues around the icon and raid boss separator] → Validate the formatted line using Blizzard-resolved localized instance and boss names.

## Migration Plan

1. Update the slot-mode footer-building path to produce atlas-prefixed footer text instead of localized `Drops from:` strings.
2. Verify the confirmed `Dungeon` and `Raid` atlases render correctly in the tracker tooltip.
3. Remove the obsolete `DROPS_FROM` and `DROPS_FROM_RAID` locale entries across supported languages.
4. Update tests that currently assert the old footer prefix behavior.
5. Validate in-game that loot-source mode remains unchanged and slot-mode tooltips show the correct atlas for dungeon vs raid items.

Rollback plan:
- Revert the footer-formatting change and return to the prior localized `Drops from:` strings. Because this is presentation-only and does not affect persistence, rollback risk is low.

## Open Questions

- What inline atlas size and spacing look most Blizzard-native for `Dungeon` and `Raid` inside the tracker tooltip footer?
