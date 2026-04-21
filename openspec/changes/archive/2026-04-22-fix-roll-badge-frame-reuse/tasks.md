## 1. Loot Roll Frame Lifecycle Coordination

- [x] 1.1 Add a LootAwareness-owned lifecycle coordinator that installs one-time hooks for Blizzard `GroupLootFrame` instances and clears addon-owned badge state when those frames hide.
- [x] 1.2 Refresh tracked badge state when a visible loot roll frame is shown or reused so queued rolls promoted into recycled frames are evaluated against the frame's current `rollID`.
- [x] 1.3 Preinstall or otherwise safely initialize reusable badge widgets and hooks so combat-time badge work can stay in a sync-only path.

## 2. Badge Synchronization Logic

- [x] 2.1 Refactor loot-roll badge synchronization so badge visibility and tag text are always recomputed from the frame's current `rollID`, current item link, tracked state, and assigned tags.
- [x] 2.2 Ensure recycled frames update to the new tracked item's tags or hide the badge completely for untracked rolls without leaking state from an earlier roll.
- [x] 2.3 Preserve independent badge rendering for simultaneous duplicate tracked drops instead of collapsing them into shared item-level state.

## 3. Event Wiring and Validation

- [x] 3.1 Remove the blanket `QueueAfterCombat` deferral from loot-roll badge decoration so visible tracked rolls can synchronize immediately from current frame state.
- [x] 3.2 Adjust `START_LOOT_ROLL` handling so early event work acts only as a sync hint and cannot reapply stale badge state to a recycled frame.
- [x] 3.3 Validate overflow scenarios where active rolls exceed visible frames, including queued tracked-roll promotion, recycled untracked rolls, duplicate tracked drops, and tracked rolls that become visible during combat.
