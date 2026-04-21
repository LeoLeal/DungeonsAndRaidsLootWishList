## Context

The addon currently reacts to `START_LOOT_ROLL` by locating a visible `GroupLootFrame` by `rollID` and decorating it once with an addon-owned wishlist badge. That flow works when the roll immediately owns one of Blizzard's visible loot-roll frames, but Blizzard only keeps a small pool of reusable `GroupLootFrame` objects and queues additional rolls until a visible slot opens. When a queued roll is later promoted into a recycled frame, the addon can miss the new assignment or leave stale badge state attached to the reused frame.

This change sits inside the existing LootAwareness boundary. The architecture guidance in `AGENTS.md` already says loot-roll behavior belongs in `LootAwareness/*`, while `Core/Bootstrap.lua` should stay limited to top-level event wiring. The design therefore needs to fix badge correctness without moving frame lifecycle ownership back into bootstrap or changing the persisted wishlist model.

## Goals / Non-Goals

**Goals:**
- Ensure a visible loot-roll frame's wishlist badge always reflects that frame's current `rollID`.
- Clear stale addon-owned badge state when Blizzard hides or reuses a `GroupLootFrame`.
- Correctly badge queued rolls when they later become visible.
- Preserve correct behavior when multiple simultaneous loot rolls represent the same tracked item.
- Keep loot-roll lifecycle coordination owned by LootAwareness modules.

**Non-Goals:**
- Redesign the loot-roll badge visuals, wording, or wishlist tag formatting.
- Change tracked-item identity resolution or wishlist persistence.
- Introduce a new saved-variable model or persistent roll history.
- Rework non-loot-roll alert behavior beyond what is needed to keep roll badges correct.

## Decisions

### 1. Drive badge synchronization from frame lifecycle, not from a one-shot start event alone

The addon should treat `START_LOOT_ROLL` as an early signal, not the authoritative moment when badge state becomes correct. LootAwareness should install lifecycle-aware hooks for Blizzard loot-roll frames so badge state is refreshed when a frame is shown for its current `rollID` and cleared when the frame hides.

Rationale:
- Queued rolls do not necessarily have a visible frame when `START_LOOT_ROLL` fires.
- Blizzard reuses `GroupLootFrame` objects, so correctness depends on the current frame assignment, not just the original roll event.
- Hooking frame show/hide behavior aligns the badge with the actual visible UI surface.

Alternatives considered:
- Retry `findById` after `START_LOOT_ROLL` with delays or polling. Rejected because it treats the queue/reuse behavior as timing noise instead of a normal lifecycle.
- Keep only the start event and accept missed queued rolls. Rejected because it leaves the known wrong-badge bug unresolved.

### 2. Make badge rendering idempotent and fully derived from the frame's current state

A single LootAwareness-owned synchronization path should resolve the visible frame's current `rollID`, current item link, tracked status, and assigned tags, then either show the badge with the correct text or hide it entirely. The badge widget may remain attached to the frame object, but its visibility and text should never be trusted from prior state alone.

Rationale:
- Reused frames are safe only if every refresh recomputes the visible state from the current roll assignment.
- A single sync path reduces drift between initial render, queued-roll promotion, and cleanup behavior.
- This keeps duplicate tracked drops correct because each visible frame is evaluated independently.

Alternatives considered:
- Maintain a global roll-to-badge map and push updates into frames opportunistically. Rejected because the frame can still outlive or change independently of the original map entry.
- Deduplicate visible roll badges by `itemID`. Rejected because two simultaneous rolls for the same tracked item are both legitimate tracked surfaces.

### 3. Keep frame discovery as a helper, but move correctness ownership into lifecycle coordination

`RollFrameLocator` can continue to help enumerate or resolve Blizzard loot-roll frames, but the correctness contract should move to a lifecycle coordinator that owns hook installation and per-frame sync. `RollBadgeView` should focus on rendering and hiding a badge for one frame once the current tracked state has been resolved.

Rationale:
- The existing `findById` helper is useful, but by itself it cannot guarantee that the badge stays correct after frame reuse.
- Separating lifecycle coordination from rendering keeps module boundaries narrow and testable.
- The design stays consistent with the repository guidance to keep feature-specific loot behavior inside LootAwareness modules rather than in bootstrap.

Alternatives considered:
- Expand `Core/Bootstrap.lua` into the owner of frame lifecycle handling. Rejected because the repository guidance explicitly discourages putting feature logic there.
- Collapse lifecycle, lookup, and rendering into one large badge module. Rejected because it would increase hidden coupling between frame hooks and UI presentation.

### 4. Treat duplicate tracked drops as independent frame presentations

The badge system should not attempt to collapse concurrent rolls for the same tracked `itemID` into one shared presentation state. Each visible loot-roll frame should be evaluated and rendered independently from its own current `rollID`.

Rationale:
- Two identical tracked drops are both real player decisions and should both remain visibly marked.
- Shared deduplication state would make the original frame-reuse bug harder to reason about and easier to reintroduce.

Alternatives considered:
- Track only one active badge per tracked item. Rejected because it can suppress a legitimate second roll or leak state between unrelated frames.

### 5. Remove the blanket `QueueAfterCombat` deferral for loot-roll badge synchronization

The addon should stop treating combat as a reason to delay all loot-roll badge decoration until `PLAYER_REGEN_ENABLED`. Instead, visible roll-frame synchronization should happen immediately from the current frame lifecycle and current `rollID`, including during combat. For this change, "safe to resolve immediately" means the frame currently has a non-nil `rollID` and the addon can read that roll's current item link through normal read-only loot-roll APIs at sync time. To keep this safe, one-time structural setup such as hook installation and reusable badge widget creation should happen ahead of combat when possible, while combat-time work should stay limited to idempotent sync of addon-owned badge visibility, text, and positioning on already known frames. If the current roll state is not readable yet, the sync path should leave the badge hidden and wait for the next roll event or frame lifecycle signal rather than queueing stale badge work for post-combat replay.

Rationale:
- The current after-combat queue increases the chance that delayed badge work lands on a frame that Blizzard has already recycled for a different roll.
- A visible tracked roll should not wait until combat ends to show its badge if the addon can safely resolve the current roll state immediately.
- The taint risk is higher for structural frame setup than for recomputing addon-owned badge state on a currently visible frame, so the design should separate setup from sync.
- Treating unreadable state as "hide and retry on the next safe sync opportunity" is safer than replaying stale frame work after combat.

Alternatives considered:
- Keep the existing `QueueAfterCombat` path for all roll-badge work. Rejected because it trades correctness for a broad safety assumption and directly amplifies the recycled-frame bug.
- Remove all combat caution and allow arbitrary first-time frame setup during combat. Rejected because the addon has a history of taint-sensitive UI work and should keep one-time setup conservative.

### 6. Treat lifecycle coordination as the sole owner of roll-badge synchronization

After implementation, the change intentionally centralizes roll-badge synchronization in `LootAwareness/RollBadge/RollBadgeLifecycle.lua`. Lifecycle installation is explicitly one-time through runtime state, and `START_LOOT_ROLL` now routes directly into lifecycle synchronization instead of keeping a secondary fallback path in the event handler.

Rationale:
- A single owner makes later debugging easier during the planned live-validation period because every visible roll-badge update follows the same path.
- Removing the fallback path avoids split behavior where some updates would use lifecycle coordination and others would bypass it.
- Explicit one-time initialization reduces repeated setup work and makes the intended steady-state behavior easier to reason about in future sessions.

Alternatives considered:
- Keep a fallback `RollBadgeView.ShowForRoll` path in `LootEventHandlers` in case lifecycle coordination is unavailable. Rejected after implementation because the TOC/runtime wiring now guarantees lifecycle availability, and the fallback would preserve unnecessary branching in the hot path.
- Re-run lifecycle installation opportunistically on every roll event. Rejected because the implementation now has a clearer one-time initialization contract and future issues should be treated as bugs rather than masked by repeated setup.

## Risks / Trade-offs

- [Blizzard frame hooks fire in an unexpected order on some clients] → Use additive hooks, guard installation so it happens once, and make sync idempotent so repeated calls remain safe.
- [The current item link is temporarily unavailable when a frame first appears] → Allow the lifecycle coordinator to resync from both the early roll event and the visible frame lifecycle, hiding the badge unless the current roll can be resolved safely.
- [Combat-delayed badge work applies to a frame that has already been recycled] → Always verify the frame's current `rollID` at sync time and hide stale state instead of trusting delayed work.
- [One-time badge widget creation or hook installation during combat could taint a Blizzard-owned surface] → Install hooks and reusable badge containers ahead of combat where practical, and keep combat-time work limited to sync on existing addon-owned badge objects.
- [Lifecycle coordination spreads across too many modules] → Keep explicit ownership boundaries: coordinator for hooks/sync timing, locator for frame discovery, and view for frame-local badge rendering.

## Migration Plan

No data migration is required. This is a runtime-only UI lifecycle correction. Rollback is straightforward: remove the lifecycle coordination changes and return to the current event-driven badge flow.

This change is expected to remain open through an extended live-validation period. The implementation work is considered complete aside from explicit in-game validation of overflow and combat scenarios, so `tasks.md` should keep the validation task open until that testing is finished. During this period, future issues discovered in live testing should be treated as follow-up bugs unless they demonstrate that the lifecycle-owned architecture itself is incorrect.

## Open Questions

- Whether a lightweight debug trace should be added temporarily during implementation to confirm recycled-frame cleanup in hard-to-reproduce overflow cases.
