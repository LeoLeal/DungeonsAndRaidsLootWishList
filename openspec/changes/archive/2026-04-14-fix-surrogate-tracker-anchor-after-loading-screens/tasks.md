## 1. Standalone anchor mode

- [x] 1.1 Update `Tracker/TrackerAnchoring.lua` to distinguish between append-below-native-content anchoring and standalone surrogate-header anchoring when no native Objective Tracker sections are visible.
- [x] 1.2 Change the standalone anchor path to derive position and width from a stable Objective Tracker root reference instead of transient content-child state.

## 2. Post-transition resync

- [x] 2.1 Add a narrow post-transition tracker resync for loading-screen and teleport lifecycle boundaries so standalone anchoring recomputes after Blizzard-managed tracker relayout settles.
- [x] 2.2 Keep the resync path idempotent and reuse the existing tracker sync/refresh flow so native-content append behavior and collapse handling remain unchanged.

## 3. Verification

- [x] 3.1 Verify the wishlist remains correctly aligned when it is the only visible tracker-area content with the Objective Tracker in its default managed position across portal, hearth, and loading-screen transitions.
- [x] 3.2 Verify the wishlist remains correctly aligned when it is the only visible tracker-area content after the Objective Tracker has been moved through Edit Mode, and confirm native tracker content still appends beneath the last visible native section without regressions.
