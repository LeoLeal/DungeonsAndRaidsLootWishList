## 1. Tracker preference persistence

- [x] 1.1 Extend `DataStore/TrackerPreferences.lua` to persist per-character tracker attachment mode, detached UIParent-relative position, and detached lock state with defaults of attached and unlocked.
- [x] 1.2 Expose read/write helpers through `DataStore/WishlistStore.lua` and any tracker-facing namespace accessors needed to consume attachment, lock, and detached-position preferences alongside existing grouping preferences.
- [x] 1.3 Ensure missing tracker-placement fields normalize safely for existing characters without disturbing current grouping-mode or collapse-state preferences.

## 2. Header controls and group interactions

- [x] 2.1 Update `Tracker/TrackerFrame.lua` and `Tracker/TrackerHeaders.lua` to add the inline attach or detach control, detached-only atlas-based lock-state control, and detached-header collapse layout in the correct control order.
- [x] 2.2 Wire `Tracker/Feature.lua` callbacks so detached header collapse, lock toggle, and attach or reattach actions update tracker state cleanly without conflicting with grouping-mode or wishlist-header collapse behavior.
- [x] 2.3 Update tracker group-header rendering so clicking either the header row or its collapse button uses one logical toggle path, changes collapse state once, and preserves the current non-EJ interaction contract.

## 3. Detached anchoring and drag behavior

- [x] 3.1 Extend `Tracker/TrackerAnchoring.lua` and related tracker orchestration to support a detached anchoring path while preserving the current attached append and standalone surrogate-header modes.
- [x] 3.2 Implement detached-frame dragging and saved-position restore in tracker-owned modules, gating movement on the persisted locked or unlocked state and restoring the last detached position when detaching again.
- [x] 3.3 Update tracker visibility and reattach flows so detached mode stays visible independently of native Objective Tracker collapse, while reattached mode resumes the existing tracker-managed layout rules.

## 4. Localization and detached-header polish

- [x] 4.1 Add the atlas-based detached lock-state control using `AdventureMapIcon-Lock`, with the unlocked state shown as a darkened version of the same atlas.
- [x] 4.2 Tune detached-header layout so the title, grouping toggle, lock-state atlas control, attach or detach button, and collapse control remain aligned without overlapping.
- [x] 4.3 Ensure detached-header collapse and expand behavior mirrors the existing wishlist-header interaction model, including the expected checkbox-style sound behavior on real state changes.

## 5. Validation

- [x] 5.1 Add or update pure-logic tests for tracker preference defaults, per-character attachment and lock persistence, and detached-position restore if test seams exist for those modules.
- [x] 5.2 Verify in-game that attached, detached, collapsed, expanded, locked, and unlocked tracker flows all behave correctly across reloads, relogs, and reattach/redetach cycles.
- [x] 5.3 Verify in-game that whole-row group-header clicks toggle collapse exactly once, detached dragging does not taint tracker behavior, and native Objective Tracker collapse only affects the wishlist while attached.
