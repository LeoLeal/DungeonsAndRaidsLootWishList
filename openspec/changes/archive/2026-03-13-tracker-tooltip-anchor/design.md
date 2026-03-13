## Context

Wishlist tracker item tooltips are shown on hover using the default Blizzard anchor behavior. The desired behavior is to anchor the tooltip to the hovered row so the tooltip appears consistently aligned with the item name. The tooltip must remain a UIParent-owned tooltip and no changes should be made to how the tooltip is created. Existing early-return guards (including the combat check) must remain the first operations in the hover handler.

## Goals / Non-Goals

**Goals:**
- Anchor wishlist tracker tooltips to the hovered row: tooltip top-right aligns to row top-left with a 4px horizontal gap.
- Keep tooltip ownership and creation unchanged (UIParent-owned tooltip, no new tooltip instances).
- Limit the change to Objective Tracker wishlist rows only.

**Non-Goals:**
- Changing tooltip content or adding wishlist-specific lines.
- Re-anchoring tooltips in other UI surfaces (Adventure Guide, bags, etc.).
- Modifying combat guard behavior or other early-return logic.

## Decisions

### D1: Anchor to the line frame (row) instead of the text frame

**Decision:** Use the tracker line frame as the anchor target and position the tooltip so its top-right aligns to the line's top-left with a 4px horizontal gap.

**Rationale:**
- The line frame is stable and already the hover target.
- Avoids dependence on text sub-frame availability.
- Preserves existing tooltip creation while changing only the anchor location.

**Alternative Considered:** Anchoring to the text frame for more precise text alignment. Rejected to avoid sub-frame coupling and to honor the request to anchor to the line frame.

### D2: Preserve early-return guards before any anchoring work

**Decision:** Keep all existing early-return checks (module ownership, boss headers, combat lock) before any tooltip anchor calculations.

**Rationale:**
- Avoids any combat-time calculations and preserves taint-safe behavior.

## Risks / Trade-offs

- **Risk:** Line frame geometry could change in future versions, shifting tooltip alignment. → **Mitigation:** Use a small, fixed horizontal gap and keep fallback to the existing cursor anchor if the line frame is not valid.
- **Risk:** Users expect default anchoring elsewhere. → **Mitigation:** Scope change strictly to wishlist tracker rows.

## Migration Plan

- Deploy in a single release that updates the tracker hover anchor logic.
- Rollback is trivial by reverting the anchor adjustment.

## Open Questions

- None.
