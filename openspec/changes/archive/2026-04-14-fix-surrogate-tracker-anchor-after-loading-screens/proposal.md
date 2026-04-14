## Why

When no native Objective Tracker sections are visible, the addon displays a surrogate `All Objectives` header so the wishlist can remain visible in the tracker area. Players are reporting that after loading-screen and teleport transitions, this standalone tracker presentation can drift out of position until native tracker content reappears or the UI is reloaded.

## What Changes

- Clarify the tracker-display requirements for the standalone `All Objectives` fallback so the wishlist remains correctly positioned across loading-screen and teleport transitions.
- Define expected behavior for both default-position and Edit Mode-moved Objective Tracker layouts.
- Document the tracker-area integration impact on the addon-owned anchoring path used when no native Objective Tracker sections are visible.

## Capabilities

### New Capabilities

### Modified Capabilities
- `wishlist-tracker-display`: tighten the tracker positioning requirements so the standalone surrogate-header presentation remains correctly aligned across loading-screen relayouts and teleport transitions, whether the Objective Tracker is in its default managed position or moved in Edit Mode.

## Impact

- Affected specs: `openspec/specs/wishlist-tracker-display/spec.md`
- Affected systems: tracker-area anchoring, standalone surrogate header behavior, Objective Tracker integration during relayouts
- Likely affected code: `Tracker/TrackerAnchoring.lua`, `Tracker/Feature.lua`, `Tracker/TrackerFrame.lua`, and any refresh/orchestration points that participate in post-transition tracker resync
