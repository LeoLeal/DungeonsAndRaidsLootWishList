## Context

Tracked-loot alert matching currently works at the correct identity layer: `LootEvents.lua` extracts an item link from `CHAT_MSG_LOOT`, resolves a stable base `itemID`, and uses that stable identity to determine whether the loot belongs to the active character's wishlist. The change keeps that matching model, but the alert path now uses the extracted dropped `itemLink` directly as the alert's display link instead of rebuilding display state from stored wishlist metadata.

That means the alert dialog can identify the correct tracked item while still showing the wrong variant. In practice, players see the baseline or previously stored wishlist version rather than the actual dropped link, which is the detail they need when watching for a tradeable upgrade-track variant.

The change spans three UI-facing modules:

- `LootEvents.lua` owns loot-event parsing and normalization boundaries.
- `LootWishList.lua` owns alert-record construction and queued dialog display.
- `WishListAlert.lua` owns item presentation, tooltip setup, and compare panes for the popup.

The repository guidance in `AGENTS.md` favors stable item identity for tracking while keeping UI behavior additive and localized to the responsible modules. This change therefore needs to separate match identity from presentation identity without changing wishlist storage semantics.

## Goals / Non-Goals

**Goals:**

- Preserve stable base-item matching for wishlist detection.
- Carry the extracted dropped item link through alert normalization and deferred alert display.
- Make the alert dialog and primary alert tooltip present the dropped variant when available, while leaving compare panes sourced from the player's equipped items.
- Reject unreadable or secret loot-chat payloads before parsing instead of falling back to stored wishlist links.

**Non-Goals:**

- Changing wishlist identity rules to track variants separately.
- Migrating saved variables or replacing stored wishlist item metadata with per-variant state.
- Changing tracker row presentation or possession-state behavior.
- Reworking the alert dialog ownership model away from the existing addon-owned popup.

## Decisions

### Preserve stable matching identity while requiring a readable dropped display link

The alert pipeline continues to use the stable base `itemID` for tracking decisions, but the alert record now requires a caller-supplied dropped `itemLink` for display. If the loot payload is unreadable or secret, the addon rejects the alert before parsing rather than synthesizing display state from stored wishlist metadata.

Rationale:
- The addon is intentionally variant-insensitive for wishlist membership, and this change does not weaken that rule.
- The player-facing problem is presentation accuracy, so the alert should show the exact dropped link extracted from the readable loot event.
- Requiring the dropped `itemLink` keeps the alert record simple and prevents silent fallback to stale stored wishlist metadata.

Alternatives considered:
- Replace stable matching with full-link matching: rejected because it would incorrectly make wishlist membership variant-specific.
- Reconstruct the dropped variant later from stored state: rejected because it reintroduces the wrong-variant alert problem.
- Fall back to stored wishlist links when the loot payload is unreadable: rejected because unreadable payloads cannot safely provide the item/player data needed for a trustworthy alert.

### Use a single effective item link in the alert record

`WishListAlert.lua` should treat `record.itemLink` as the alert's single source of truth for the row's item icon, item name, and primary tooltip content. `LootEvents.lua` supplies that field from the extracted dropped loot link, and `ShowLootDialog` uses the same field directly for manual dialog calls. The compare panes continue to represent the player's currently equipped comparison items, using the alert's displayed item as the primary compared item.

Rationale:
- The dialog should answer "what dropped?" rather than "what base item is tracked?"
- A single display-link field is easier to reason about than layered observed/fallback aliases.
- The main alert surface and primary tooltip need to reflect the dropped variant, while the compare panes keep their current semantic role as equipped-item comparisons.

Alternatives considered:
- Show dropped link in the tooltip only while keeping the stored tracked name in the dialog row: rejected because it creates contradictory UI.
- Keep the stored link when it has richer metadata: rejected because accuracy of the actual dropped variant is the primary UX goal.

## Risks / Trade-offs

- [Unreadable loot payloads now produce no alert instead of a degraded fallback] -> Accept the loss of those alerts in exchange for taint-safe parsing and correct variant display.
- [Dropped-link normalization may preserve a link string whose item data is not yet cached] -> Keep the dropped link in the alert record and allow the popup helpers to fall back only to base item APIs such as `GetItemInfo`/`GetItemIcon`, not to stored wishlist links.
- [Future code may reintroduce stored-link fallback into the alert path] -> Document in specs that readable loot events must supply the alert display link directly.

## Migration Plan

No saved-variable migration is required.

Rollout plan:
- Update loot-event handling to reject unreadable payloads before parsing and pass the extracted dropped `itemLink` into alert normalization.
- Simplify alert-record construction so the record carries a single caller-supplied display `itemLink` plus stable `itemID` gating.
- Update alert presentation helpers to use that single `itemLink` for the alert row and primary tooltip, while leaving compare panes tied to equipped-item comparison behavior.

Rollback plan:
- Revert the direct dropped-link alert path and restore stored-link presentation.

## Open Questions

- Do we want any explicit visual cue in the dialog text when the dropped variant differs materially from the tracked stored link, or is showing the dropped link itself sufficient?
