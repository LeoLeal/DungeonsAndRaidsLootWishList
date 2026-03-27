## Context

The tracker already reuses row frames, but `TrackerUI.lua` performs a full row-state resync on each tracker refresh. Item rows install `OnEnter` / `OnLeave` handlers that show and hide a tracker-dedicated tooltip, yet `syncTrackerFrame()` currently calls `hideTrackerTooltip()` before rebuilding row state. In environments with frequent `CHAT_MSG_LOOT`, bag, equipment, or Objective Tracker updates, that unconditional teardown dismisses the tooltip while the mouse is still resting over the tracker, and no new `OnEnter` fires because the cursor never actually left the row.

This change should keep existing refresh triggers intact. The addon relies on those refreshes for possession state, grouping, and native tracker integration, and the bug is in hover lifecycle management rather than refresh frequency. The relevant design constraint from the existing tooltip behavior is that tracker row hover uses an addon-owned tooltip surface with addon-owned compare panes, so refresh logic must keep those surfaces coherent with the row currently under the cursor.

## Goals / Non-Goals

**Goals:**
- Preserve tracker tooltip visibility across background tracker refreshes when the cursor is still over a valid tracked item row.
- Make refresh behavior follow the row currently under the cursor after the refresh, including switching the tooltip to a different item if that row's bound item changes.
- Hide the tooltip and compare panes only when the post-refresh hover target is no longer a valid tracked item row.
- Keep existing tracker refresh triggers, grouping behavior, tooltip anchoring, and compare-pane presentation intact.

**Non-Goals:**
- Reducing or suppressing `CHAT_MSG_LOOT`, bag, equipment, or Objective Tracker refreshes.
- Replacing row pooling with a new virtualized or diff-only renderer.
- Changing tooltip content, footer rules, or comparison-tooltip styling.
- Changing right-click context menu behavior beyond whatever is necessary to avoid stale tooltip state during refresh.

## Decisions

### Reconcile hover after refresh instead of unconditionally tearing it down

`syncTrackerFrame()` should stop treating tooltip dismissal as the default first step of every refresh. Instead, the tracker should finish rebuilding visible rows, then run a hover-reconciliation pass that determines which tracker row is actually under the cursor after the refresh.

Rationale:
- The current bug exists because refresh happens while the cursor is stationary, so `OnEnter` is not a reliable mechanism for restoring hover UI after refresh.
- Reconciliation after render bases tooltip state on the latest visible UI rather than stale pre-refresh assumptions.
- This preserves refresh correctness while making hover resilient to harmless row-state churn.

Alternatives considered:
- Keep unconditional hide and rely on a new synthetic `OnEnter`: rejected because the cursor may now be over a different row item than before refresh.
- Suppress refreshes while hovered: rejected because refreshes are still needed for tracker correctness.

### Use the live post-refresh hover target as the source of truth

The tracker should decide tooltip state from the row currently under the cursor after refresh, not from the previously hovered item identity alone. If the row under the cursor is still a valid item row, `showTrackerTooltip(row)` should be invoked for that row's current `itemID` / `tooltipRef`. If refresh rebinding causes the row under the cursor to now represent a different item, the tooltip should switch to that new item instead of hiding.

Rationale:
- Rows are pooled and rebound by index, so a row frame can survive refresh while representing different item data.
- The user's intent is tied to the current visible row under the pointer, not to an abstract remembered item key.
- This model naturally handles row movement, regrouping, and data rebinding without special-case item preservation logic.

Alternatives considered:
- Preserve tooltip only when the old item identity still exists: rejected because it fails the desired UX when the row under the cursor legitimately changes to a different item.
- Track tooltip by row frame identity only: rejected because the same pooled frame can be rebound to a different item during refresh.

### Determine hover validity from item-row state, not generic frame visibility

The hover-reconciliation pass should only keep or show the tooltip when the live hover target resolves to a visible, non-header tracker item row with a valid tooltip reference (`tooltipRef` or `itemID`). Group headers, boss headers, hidden rows, collapsed tracker states, and fully hidden tracker frames should all invalidate hover and hide both the primary tooltip and compare panes.

Rationale:
- The tracker has mixed row types, and only item rows are valid tooltip owners.
- Explicit validity checks prevent stale tooltips when refresh collapses a section, removes an item, or turns a visible position into non-item content.
- Using item-row validity preserves the existing rule that leaving item-row hover should hide the tooltip.

Alternatives considered:
- Preserve tooltip whenever the mouse is somewhere inside the tracker frame: rejected because headers and empty space should not show item tooltips.

### Keep compare panes coupled to the primary tracker tooltip lifecycle

The tracker should continue to use the existing `showTrackerTooltip()` / `hideTrackerTooltip()` entry points so the addon-owned compare panes remain tied to the primary tooltip. Hover reconciliation should therefore re-show the full tooltip surface for the current row item or fully hide it; it should not try to manage compare panes independently.

Rationale:
- Compare panes are already owned by `TooltipCompare.lua` and intentionally coupled to the primary tracker tooltip.
- Reusing the existing show/hide path keeps tooltip content, anchor behavior, and comparison rendering consistent.
- Independent compare-pane management would add state complexity without solving the underlying bug.

Alternatives considered:
- Manage compare panes separately from primary tooltip during refresh: rejected as unnecessary additional state machinery.

## Risks / Trade-offs

- [Hover detection after refresh may misidentify row children or transient mouse focus] → Reconcile against tracker item rows only and treat child-frame focus as belonging to that row rather than as a separate hover target.
- [Calling the normal tooltip show path after refresh may cause minor visual churn when the same item remains hovered] → Accept a small re-show cost in exchange for correct behavior, since correctness is more important than avoiding an occasional redraw.
- [Tracker collapse or row removal could leave stale tooltip surfaces onscreen] → Treat hidden tracker states, hidden rows, and non-item rows as hard invalidation cases that always call the full hide path.
- [Future refresh logic could reintroduce unconditional tooltip teardown] → Document hover reconciliation as the required refresh model in the tooltip spec delta for this change.

## Migration Plan

No saved-variable or data migration is required.

Rollout plan:
- Update tracker refresh behavior in `TrackerUI.lua` so row rendering completes before hover reconciliation decides whether to show, switch, or hide the tooltip.
- Keep `LootWishList.lua` refresh triggers unchanged.
- Verify behavior with ambient city refresh traffic, quiet dungeon conditions, group collapse changes, item removal, and row switching under the cursor.

Rollback plan:
- Restore unconditional tooltip teardown at the start of tracker refreshes.

## Open Questions

- None currently. The desired hover rule is that the tooltip follows the current valid item row under the cursor after refresh and hides only when no valid item row remains there.
