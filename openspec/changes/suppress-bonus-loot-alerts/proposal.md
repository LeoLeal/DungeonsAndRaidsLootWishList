## Why

Tracked-item loot alerts are intended to surface actionable opportunities when another player receives wishlist loot that may be tradeable. Bonus loot events are not tradeable to the user, so showing the same alert dialog for those events creates noise and implies an action the user cannot take.

## What Changes

- Suppress tracked-item alert dialogs for readable loot-chat messages that report another player receiving Bonus loot.
- Preserve existing alert behavior for ordinary other-player tracked-item loot and other alertable loot events.
- Classify Bonus loot at the LootAwareness event parsing/handling boundary so non-alertable loot never reaches alert record construction or dialog queueing.
- Keep loot matching based on stable tracked-item identity and continue using the dropped item link for alertable loot presentation.

## Capabilities

### New Capabilities

### Modified Capabilities
- `wishlist-loot-awareness`: Refine other-player tracked-item alert eligibility so Bonus loot events are ignored even when the item matches the active character's wishlist.

## Impact

- Affected modules: `LootAwareness/ChatLootParser.lua`, `LootAwareness/LootEventHandlers.lua`, and related alert/event tests or verification seams if present.
- Affected specs: `openspec/specs/wishlist-loot-awareness/spec.md` via a delta spec for Bonus loot suppression.
- No saved-variable schema changes are expected.
- No changes are expected for the addon-owned alert dialog presentation itself; it should continue to consume only normalized alert records for eligible alerts.
