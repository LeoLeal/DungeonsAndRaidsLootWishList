## Why

Tracked loot-roll badges can appear on the wrong item when more loot rolls are active than the number of visible Blizzard loot-roll frames. The current badge flow decorates frames too early and does not fully account for Blizzard reusing `GroupLootFrame` objects, so queued or recycled rolls can inherit stale wishlist badge state.

## What Changes

- Tighten loot-roll badge behavior so badge visibility is always derived from the frame's current `rollID`, not stale frame state left behind from an earlier roll.
- Clear addon-owned wishlist badge state when a loot-roll frame hides or is recycled for a different roll.
- Re-evaluate wishlist badge state when queued loot rolls are promoted into visible frames after an earlier frame closes.
- Remove the blanket `QueueAfterCombat` deferral for loot-roll badge decoration so visible tracked rolls can badge immediately instead of waiting until combat ends.
- Preserve correct badge behavior when multiple simultaneous rolls refer to the same tracked wishlist item.

## Capabilities

### New Capabilities

### Modified Capabilities

- `wishlist-loot-awareness`: strengthen loot-roll badge correctness requirements so tracked badges stay accurate across frame reuse, queued-roll promotion, and duplicate tracked drops.

## Impact

- Affected code: `LootAwareness/RollBadge/RollBadgeView.lua`, `LootAwareness/RollBadge/RollFrameLocator.lua`, `LootAwareness/LootEventHandlers.lua`, and possibly `Core/Bootstrap.lua` if event wiring or lifecycle hooks change.
- Affected systems: loot-roll badge presentation, loot-roll event coordination, and Blizzard `GroupLootFrame` lifecycle integration.
- Risk areas: combat-safe frame hooks and one-time badge setup, transient Blizzard frame reuse timing, removing overly broad combat deferral without reintroducing taint, and keeping simultaneous duplicate tracked drops correctly badged without leaking state to unrelated rolls.
