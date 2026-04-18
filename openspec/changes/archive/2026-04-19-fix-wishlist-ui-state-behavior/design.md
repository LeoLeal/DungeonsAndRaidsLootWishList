## Context

This change corrects two UI-state mismatches in separate feature areas without altering the underlying wishlist data model. In the Adventure Guide, the favorite control already swaps foreground and background atlases by tracked state, but only the foreground heart opacity changes across visual states. In the tracker, anchoring logic currently applies screen clamping uniformly, even when the wishlist is attached to Objective Tracker layout and should behave like appended native tracker content.

The repository architecture already assigns ownership cleanly:

- `AdventureGuide/WishlistCheckboxes.lua` owns the favorite control presentation for Encounter Journal loot rows.
- `Tracker/TrackerAnchoring.lua` owns attachment-mode positioning and detached drag behavior.
- `Tracker/Feature.lua` owns tracker sizing and content layout but should not become the owner of attachment-mode screen-bound rules.

The design should keep both fixes small, local, and reversible while preserving Blizzard-native tracker behavior.

## Goals / Non-Goals

**Goals:**
- Keep Adventure Guide favorite foreground and background opacity synchronized for every rendered visual state.
- Allow all non-detached tracker presentations to extend below the visible screen when Objective Tracker content pushes them down.
- Preserve detached tracker screen clamping and existing detached drag or lock behavior.
- Keep behavior ownership in the narrowest responsible modules.

**Non-Goals:**
- Redesigning the favorite control atlases, colors, or placement.
- Changing tracker attachment preferences, persisted detached position data, or grouping behavior.
- Refactoring tracker rendering or Adventure Guide popover behavior beyond what is needed for these fixes.

## Decisions

### 1. Centralize favorite-control opacity application inside the Adventure Guide button state logic

**Decision**

Treat the heart icon and background ring as one visual control state. The Adventure Guide favorite button should use a shared local helper or equivalent state path so every state transition applies the same alpha value to both foreground and background textures.

**Rationale**

The bug exists because atlas selection and alpha changes are currently split across separate calls. Synchronizing alpha in one control-owned path prevents idle, pressed, and restored states from drifting apart again.

**Alternatives considered**

- **Only update the untracked idle state**: rejected because press and release interactions would still allow the heart and ring to diverge.
- **Push opacity rules into a shared style module**: rejected because this is a narrow Adventure Guide control concern rather than a cross-feature style system.

### 2. Make screen clamping attachment-mode-aware in tracker anchoring

**Decision**

Apply `SetClampedToScreen(true)` only while the tracker is detached. Attached append mode and attached standalone mode should disable screen clamping so the frame can follow Objective Tracker layout even when that places part of the wishlist below the bottom of the viewport.

**Rationale**

Attached tracker presentations are semantically part of tracker layout, not floating windows. Detached mode is the only mode that behaves like a movable standalone frame and therefore should remain constrained to the screen.

**Alternatives considered**

- **Keep all modes clamped and adjust offsets near the screen bottom**: rejected because it fights the natural Objective Tracker stack and introduces layout-specific compensations.
- **Allow only append mode to overflow while keeping attached standalone clamped**: rejected because the agreed behavior is for all non-detached presentations to behave consistently.

### 3. Keep sizing and visibility logic separate from screen-bound rules

**Decision**

Continue to let `Tracker/Feature.lua` compute content height and row layout, while `Tracker/TrackerAnchoring.lua` remains the owner of whether the frame is clamped in a given attachment mode.

**Rationale**

The current issue is not caused by height calculation but by anchor-mode policy. Fixing it in the anchoring module aligns with the repository rule to solve the root cause in the owning module rather than compensating elsewhere.

**Alternatives considered**

- **Limit tracker height in `Tracker/Feature.lua`**: rejected because the requested behavior is specifically to allow offscreen overflow when attached.
- **Introduce mode-specific frame wrappers**: rejected as unnecessary complexity for a small behavior correction.

## Risks / Trade-offs

- **Interaction-state regression on the Adventure Guide favorite button** → Verify tracked, untracked, pressed, mouse-up, and mouse-leave transitions all restore matched alpha values.
- **Unexpected detached overflow after reattachment changes** → Keep clamping mode-specific and re-run attachment toggles to verify detached still stays within screen bounds.
- **Tooltip or popup anchoring near offscreen attached tracker rows** → Smoke-test tracker tooltip, filter menu, and context menu with a tall attached tracker to confirm independent popup clamping still behaves acceptably.

## Migration Plan

No data migration is required. This is a runtime UI-behavior correction only.

## Open Questions

No open questions remain for artifact creation. The user has already confirmed that background opacity should mirror foreground opacity for each state, all non-detached tracker modes may go offscreen, and the work should be captured as one combined change.
