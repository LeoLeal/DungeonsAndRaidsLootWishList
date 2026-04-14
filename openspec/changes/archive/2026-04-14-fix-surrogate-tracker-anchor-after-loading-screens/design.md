## Context

The wishlist tracker is implemented as an addon-owned sidecar frame that visually integrates with the Blizzard Objective Tracker without registering as a native tracker module. When native Objective Tracker sections are visible, the addon appends itself beneath the last visible native tracker section. When no native sections are visible, the addon falls back to a standalone presentation with a surrogate `All Objectives` header.

Player reports and local investigation show the positioning bug is isolated to that standalone fallback mode. After loading-screen and teleport transitions, the wishlist frame can drift both horizontally and vertically until native tracker content appears again or the UI is reloaded. The issue reproduces in the default managed Objective Tracker position and must also remain correct when the tracker has been moved through Edit Mode.

Constraints:

- Keep the addon-owned tracker architecture; do not reintroduce native module registration.
- Preserve the existing append-below-native-content behavior, which is already acting as the self-correcting path.
- Prefer narrow tracker-layout ownership fixes in `Tracker/TrackerAnchoring.lua`, `Tracker/Feature.lua`, and closely related orchestration points instead of broader tracker rewrites.

## Goals / Non-Goals

**Goals:**
- Keep the standalone surrogate-header tracker correctly aligned across loading-screen and teleport transitions.
- Make the fallback anchor stable in both default-position and Edit Mode-moved tracker layouts.
- Preserve current native-content append behavior and collapse semantics.
- Fix the root cause in tracker anchoring and lifecycle timing rather than compensating with new offsets.

**Non-Goals:**
- Redesign tracker visuals, spacing, or group presentation.
- Change grouping, possession, tooltip, or persistence behavior.
- Replace the addon-owned tracker with Blizzard native module registration.
- Introduce broad always-on watchers when a narrow post-transition resync path is sufficient.

## Decisions

### Decision 1: Treat standalone fallback anchoring as its own anchoring mode

When native tracker sections are visible, the current bottommost-visible-child anchoring path remains the primary append behavior. When no native sections are visible and the surrogate `All Objectives` header is shown, anchoring should switch to a dedicated standalone mode that aligns to a stable Objective Tracker root reference rather than relying on transient native content-child state.

**Why:** The bug only persists in the standalone path, and it corrects itself once native tracker content reappears. That points to the fallback anchor basis being less stable than the append-under-native-child basis.

**Alternatives considered:**
- Continue using the same `BlocksFrame` / `ContentsFrame`-based fallback path for both modes. Rejected because the standalone path is the one drifting after relayout.
- Always anchor to the tracker root, even when native sections exist. Rejected because it would discard the already-correct natural append behavior beneath visible native sections.

### Decision 2: Use tracker-root geometry for standalone top positioning

In standalone mode, the wishlist frame's top/left alignment and width should derive from a stable tracker-root reference that survives managed relayouts, rather than from whichever internal content container happens to exist during a transition.

**Why:** The observed drift is both horizontal and vertical, which indicates the fallback problem is not just a bad gap constant. The standalone anchor needs a geometry source that remains valid when the Objective Tracker is in its default managed position and Blizzard is recomputing layout during teleport and loading-screen transitions.

**Alternatives considered:**
- Adjust vertical spacing constants only. Rejected because the bug has horizontal drift as well.
- Special-case only Edit Mode or only default-position trackers. Rejected because the requirement is correctness in both layouts and the bug is fundamentally about standalone anchor stability.

### Decision 3: Add a narrow post-transition resync after tracker relayout boundaries

The addon should keep its current tracker update/show/hide hooks, but add a narrow post-transition resync path for loading-screen and teleport lifecycle boundaries so the standalone anchor is recalculated after Blizzard-managed frame positions settle.

**Why:** Generic tracker interaction does not restore the correct position, but the appearance of native tracker content does. This suggests the existing hooks are not sufficient to repair the standalone anchor after managed relayout, and a focused post-transition sync is preferable to broad polling.

**Alternatives considered:**
- Rely only on existing `ObjectiveTrackerFrame` update/show/hide hooks. Rejected because those hooks are already present and are not preventing the bug.
- Add an always-on watcher or frequent `OnUpdate` geometry polling. Rejected because it adds complexity and coupling where a narrow lifecycle-triggered resync should be enough.

### Decision 4: Keep the fix local to tracker layout ownership

The change should remain owned by tracker layout modules, with only minimal orchestration support if a post-transition refresh trigger must be added. The design should not move tracker presentation ownership back into broad bootstrap logic.

**Why:** The architecture already assigns Objective Tracker layout bugs to `Tracker/Feature.lua`, `Tracker/TrackerFrame.lua`, and `Tracker/TrackerAnchoring.lua`. Keeping the fix local maintains the current module boundaries and makes the behavior easier to reason about.

**Alternatives considered:**
- Push the fix primarily into `Core/Bootstrap.lua`. Rejected because the root problem is tracker layout ownership, not general addon state management.

## Risks / Trade-offs

- **[Risk]** Blizzard tracker-root geometry may differ slightly between client states or future patches. **→ Mitigation:** Reference the smallest stable set of tracker root/header anchors possible and preserve the existing native-child append path.
- **[Risk]** A deferred post-transition resync may briefly show one stale frame position before correcting. **→ Mitigation:** Keep the resync path idempotent and narrowly timed so it runs once after transition settling rather than repeatedly.
- **[Risk]** Adding lifecycle triggers for teleport/loading events may overlap with existing refresh hooks. **→ Mitigation:** Reuse the existing sync function and avoid introducing separate parallel anchoring code paths.
- **[Risk]** A fix that only targets default-position trackers could regress moved trackers. **→ Mitigation:** Validate both default and Edit Mode-moved layouts as explicit acceptance cases.

## Migration Plan

1. Update the `wishlist-tracker-display` requirements to define stable standalone positioning across loading-screen and teleport transitions.
2. Implement a dedicated standalone anchor mode that derives geometry from a stable tracker-root reference.
3. Add a narrow post-transition resync so standalone positioning is recomputed after managed tracker relayout.
4. Verify behavior in both default-position and Edit Mode-moved tracker layouts, with and without visible native tracker content.
5. If rollback is needed, remove the standalone-specific anchor/resync changes and fall back to the previous tracker anchoring behavior. No saved-variable or data migration is required.

## Open Questions

- Which exact transition boundary is the most reliable final resync trigger on retail for portal, hearth, and loading-screen relayouts?
- Does the most stable standalone reference live on the Objective Tracker root, its header region, or another tracker-owned top anchor that survives managed repositioning consistently?
