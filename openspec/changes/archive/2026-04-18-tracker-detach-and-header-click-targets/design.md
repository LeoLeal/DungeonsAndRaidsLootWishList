## Context

The wishlist tracker is an addon-owned sidecar frame that visually integrates with the Blizzard Objective Tracker without registering as a native tracker module. In attached mode it currently has two runtime presentations: appended beneath visible native tracker content, or standalone with a surrogate `All Objectives` header when no native sections are visible. Group headers already support collapse state and native-style right-edge collapse buttons, but only the small button is clickable; by contrast, the surrogate header and the `Loot Wishlist` header already expose broader click targets.

This change adds two related interaction improvements:

- group headers should toggle collapse from the whole header row, not only the button
- the `Loot Wishlist` section should be able to detach into a movable, persisted sidecar frame with its own collapsible header, movement lock control, and Blizzard-native tracker visuals

Constraints:

- Keep tracker ownership in tracker modules rather than moving layout or persistence behavior into broad bootstrap logic.
- Preserve the existing attached append-below-native-content and surrogate-header fallback behavior when the tracker is not detached.
- Keep tracker preferences character-scoped and additive to the current saved-variable model.
- Detached mode should remain visible even when the native Objective Tracker is collapsed or hidden.
- Detached lock-state control must use Blizzard-provided atlases instead of localized text labels.

## Goals / Non-Goals

**Goals:**
- Make tracker group collapse easier by letting the whole group header row toggle the same state as the existing collapse button.
- Introduce a persisted attached-versus-detached tracker mode with attached as the default.
- In detached mode, show a single surrogate-style header labeled `Loot Wishlist`, keep the tracker collapsible, allow the player to toggle movement locking through an atlas-based lock-state control, and restore the last detached position on future detaches.
- Keep grouping toggle, header collapse, lock-state atlas control, and attach or reattach controls addon-owned and visually aligned with Blizzard tracker patterns.
- Preserve current tracker grouping, tooltip, animation, and item-rendering behavior outside the new interaction and placement changes.

**Non-Goals:**
- Adding account-wide tracker placement preferences.
- Making the detached tracker resizable.
- Changing how tracked items are grouped, rendered, or removed.
- Replacing the addon-owned tracker with Blizzard native module registration.
- Introducing a second stacked header in detached mode.

## Decisions

### Decision 1: Treat attachment state as a persisted tracker preference separate from runtime anchor mode

The design will distinguish between:

- **attachment state**: `attached` or `detached`, persisted per character
- **attached runtime anchor mode**: `append` or `standalone`, derived from native tracker visibility as it is today

When the tracker is attached, the current `append` and surrogate-header `standalone` logic remains in force. When the tracker is detached, anchoring no longer depends on native tracker section visibility and instead uses a detached positioning path.

**Why:** User intent to detach is durable UI preference, while append-versus-standalone is a transient consequence of current Objective Tracker state. Keeping those concepts separate avoids mixing persisted preference with relayout heuristics.

**Alternatives considered:**
- Model `detached` as just another `TrackerAnchoring.GetAnchorMode()` result. Rejected because it couples a persisted user preference to transient tracker-geometry logic.
- Store detach state only on the live frame. Rejected because the requested behavior must persist across reloads and relogs.

### Decision 2: Persist detached placement and lock state as tracker preference data

Detached position will be stored under tracker-scoped character preferences as a UIParent-relative anchor payload, using a stable point and offsets rather than references to Objective Tracker subframes. The same preference area will also persist whether the detached frame is currently locked against movement. The default state remains attached; detached position data is populated or updated only after the user moves the detached frame, and the default detached lock state is unlocked when no saved value exists.

The detached presentation may continue to inherit the tracker width that the addon already derives from Objective Tracker geometry, but width itself is not part of the persisted preference for this change.

**Why:** The Objective Tracker's internal frames are valid anchoring sources for attached layout, but they are not an appropriate persistence target for a movable detached frame. UIParent-relative placement survives tracker visibility changes, Edit Mode moves, and reloads cleanly, while a persisted lock flag lets the detached header control whether dragging is currently allowed.

**Alternatives considered:**
- Persist position relative to Objective Tracker internals. Rejected because those references are transient and defeat the purpose of independent detached placement.
- Persist width together with position. Rejected because the request only requires movable placement persistence, and width can continue to follow existing tracker sizing rules.
- Keep lock state purely runtime-only. Rejected because the user explicitly wants the lock state persisted in Saved Variables.

### Decision 3: Detached mode uses a single surrogate-style `Loot Wishlist` header with collapsible content semantics

Detached mode will not stack the current surrogate `All Objectives` header above the existing wishlist module header. Instead, it will render a single header that borrows the surrogate header appearance but is labeled with the localized `Loot Wishlist` title and owns the detached tracker controls.

In that mode:

- the single detached header keeps the main wishlist collapse semantics (content hidden vs shown) and must be able to collapse and expand the detached content directly
- the surrogate-only hidden-state behavior remains attached-standalone specific and is not reused for detached mode
- the detached header includes the grouping control, a lock-state atlas control, the attach or reattach toggle, and the existing wishlist collapse control

**Why:** A double-header detached frame would feel redundant and would expose two different collapse concepts in one small surface. A single header makes detached mode feel intentional while preserving the existing per-section collapse behavior users already understand.

**Alternatives considered:**
- Keep both headers in detached mode. Rejected because it duplicates controls and introduces unnecessary visual weight.
- Reuse surrogate hidden-state semantics for detached mode. Rejected because detached mode has only one header and should continue to behave like a collapsible wishlist section, not like an attached standalone fallback.

### Decision 4: Group header rows and their collapse buttons share one logical toggle action

Each group header row will use the same collapse callback as the existing button so left-clicking either surface changes the group's persisted collapse state exactly once, plays the existing checkbox-style sound on real state change, and rebuilds the tracker. The row remains informational only beyond collapse behavior: it does not open the Adventure Guide, show a context menu, or gain tracked-item actions.

The implementation should treat button clicks and row clicks as one logical interaction path, with explicit protection against a single button click causing a double toggle through both handlers.

**Why:** The row-level click target makes group collapse feel consistent with the rest of the tracker headers while preserving the current group-collapse persistence model and interaction boundaries.

**Alternatives considered:**
- Leave only the small button clickable. Rejected because that preserves the current usability issue.
- Create a separate invisible overlay that excludes the button area entirely. Rejected as the primary design because the important requirement is a single logical toggle path, not a specific widget layering strategy.

### Decision 5: Detached header controls remain addon-owned and separate by concern

The `Loot Wishlist` header will gain an addon-owned icon attach or detach button that remains in the right-side control cluster rather than sitting directly after the localized title text. While attached, it uses `RedButton-Expand` and `RedButton-Expand-Pressed`; while detached, it uses `RedButton-Condense` and `RedButton-Condense-Pressed`.

Detached mode will also expose an addon-owned atlas button between the grouping control and the attach or detach button:

- it uses atlas `AdventureMapIcon-Lock` at full brightness while the detached tracker is currently locked and fixed in place
- it uses the same atlas darkened while the detached tracker is currently unlocked and movable
- it remains a dedicated icon control rather than a localized text label

To keep the header layout visually stable:

- attached mode orders right-side controls as `grouping → attach/detach → collapse`
- detached mode orders right-side controls as `grouping → lock-state atlas → attach/detach → collapse`
- the title text occupies the remaining left-side space and truncates before colliding with the control cluster

The button toggles only attachment state:

- attached → detached: preserve the current on-screen location as the starting detached position, then allow dragging
- detached → attached: stop free movement, return to tracker-managed anchoring, and preserve the last detached position for the next detach

Other header controls remain separate concerns: grouping continues to switch grouping mode, the lock-state atlas control toggles whether dragging is currently allowed, and the collapse control continues to collapse or expand the wishlist content.

**Why:** Keeping the new controls addon-owned matches existing header controls, limits Blizzard UI coupling, and fits the requested combination of icon-based attachment control plus atlas-based movement-state control. Keeping the grouping label fixed on the left of the detached control cluster reduces visible control shuffling as the detached lock state changes.

**Alternatives considered:**
- Put detach on the far right with other buttons. Rejected because the requested interaction is specifically inline after the label.
- Fold detach into a context menu or slash command. Rejected because the change is explicitly a direct tracker-header affordance.
- Keep a text-based locked/unlocked label. Rejected because the lock-state label was not working well visually and the atlas-based control is clearer in the available space.

### Decision 6: Detached visibility is independent from native Objective Tracker collapse, but tracked-item presence still owns frame existence

The tracker will continue to hide entirely when the active character has no tracked wishlist items. Beyond that:

- in attached mode, the existing native-tracker-collapse and native-visibility rules remain in effect
- in detached mode, native Objective Tracker collapse or hiding no longer suppresses the detached tracker frame

This keeps detached mode independent without changing the meaning of “no wishlist content to show.”

**Why:** The user explicitly wants a detached tracker that can be moved freely and remain usable even when the Objective Tracker itself is collapsed or hidden.

**Alternatives considered:**
- Mirror native tracker collapse even while detached. Rejected because it undermines the value of detaching.
- Keep the detached tracker always visible, even with zero tracked items. Rejected because it changes the existing content-owned visibility contract unnecessarily.

### Decision 7: Detached lock state gates dragging only and does not change detached visibility or collapse state

When the detached tracker is unlocked, the detached header may initiate movement and the addon's drag-save path can update persisted placement. When the detached tracker is locked, movement initiation is suppressed, but the tracker remains detachable, reattachable, collapsible, and visible under the same detached visibility rules.

**Why:** Locking is about preventing accidental repositioning, not about changing whether the detached tracker can be used.

**Alternatives considered:**
- Make lock also collapse or hide the detached tracker. Rejected because it conflates unrelated concerns.
- Make unlocking temporary until the next move. Rejected because the user asked for lock state persistence.

## Risks / Trade-offs

- **[Risk]** Header controls may crowd localized titles, especially when the grouping label and icon controls all compete for header width. **→ Mitigation:** Keep both detached icon controls compact, reserve explicit spacing between title and controls, and allow title truncation before controls overlap.
- **[Risk]** A button click on a group header may also trigger the row click and toggle twice. **→ Mitigation:** Route both surfaces through one guarded logical toggle path and test button-hit behavior specifically.
- **[Risk]** Detached drag behavior could save unstable anchors if stored relative to transient frames. **→ Mitigation:** Normalize saved placement to UIParent-relative anchor data only.
- **[Risk]** Reusing attached header helpers in detached mode could leak surrogate standalone hidden-state behavior into the new single-header presentation. **→ Mitigation:** Keep detached header state separate from attached standalone hidden-state handling and limit detached collapse to the existing wishlist content collapse state.
- **[Risk]** Detached mode introduces another visibility branch that may regress current append or standalone anchoring. **→ Mitigation:** Preserve attached anchoring as the default path and isolate detached behavior to narrow tracker ownership modules.
- **[Risk]** Persisted lock state could desynchronize from actual movability after attach-detach transitions. **→ Mitigation:** Reapply lock-derived movability each time detached state is entered or restored, not only when the button is clicked.

## Migration Plan

1. Extend tracker preference storage to include attachment mode, detached position, and detached lock state as additive character-scoped fields, defaulting missing values to attached mode and unlocked detached state.
2. Update tracker-display requirements to cover full-row group-header collapse behavior, detached-header collapse behavior, and detached lock controls.
3. Add tracker-frame and tracker-header support for the inline attach or detach control, the detached single-header presentation, and the atlas-based lock-state control.
5. Add a detached anchoring and drag-save path while preserving the current attached append and surrogate standalone anchoring behavior, and gate dragging based on the persisted lock state.
6. Verify attached, attached-standalone, and detached behavior with tracked items present, with and without native tracker visibility, after reload or relog, and in both locked and unlocked detached states.
7. If rollback is needed, ignore the new attachment, detached-position, and detached-lock preference fields and fall back to the current always-attached tracker behavior.

## Open Questions

- None at this time. The desired detached behavior, persistence scope, header shape, atlas-based lock-state control, and default unlocked lock state have been decided.
