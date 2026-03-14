# Proposal: TrackerUI Side-Car Refactor

## 1. Problem Statement

The Loot Wishlist addon currently integrates with the default game UI by registering a custom module into the `ObjectiveTrackerFrame` using the `AddModule` API. 

Recent research into the World of Warcraft secure execution environment ("taint" system) reveals that this approach is inherently unstable. By injecting third-party code directly into the Objective Tracker's update loop, the addon inadvertently taints the execution path whenever the tracker updates in combat. This contamination spreads to shared global frames—most notably the `GameTooltip`—resulting in "Action Forbidden" errors and the total failure of item tooltips across the entire game interface.

## 2. Proposed Solution

We must completely decouple the AddOn's UI rendering from Blizzard's `ObjectiveTrackerModuleMixin` architecture while maintaining the visual illusion that the wishlist is part of the native tracker.

This will be achieved by implementing a **"Side-Car" Architecture**:
- **Independent Rendering:** The addon will construct and manage its own pure-Lua frames (Headers and Item Lines) instead of using the secure Objective Tracker pooling system.
- **Dynamic Anchoring:** A master container frame will be visually anchored to the bottom of the native `ObjectiveTrackerFrame`.
- **Post-Hook Alignment:** We will use `hooksecurefunc` on the tracker's layout update cycle to continuously adjust our container's position, ensuring it flows naturally below active quests and achievements without participating in their secure update loop.

## 3. Scope

### In Scope
- Refactoring `TrackerUI.lua` to remove all usage of `ObjectiveTrackerModuleTemplate` and `ObjectiveTrackerFrame:AddModule`.
- Creating a custom, lightweight frame pooling system within `TrackerUI.lua` for reusing header and line frames.
- Replicating the exact visual appearance of the native tracker (fonts, spacing, atlases, highlight behaviors).
- Implementing the post-hook anchoring logic to keep the Side-Car glued to the native tracker.
- Implementing strict, taint-safe tooltip handling (explicitly clearing tooltip ownership before use).
- Handling the native tracker's global "collapsed" state so the Side-Car hides when the main tracker is minimized.

### Out of Scope
- Changes to data persistence (`WishlistStore.lua`).
- Changes to how item identities are resolved (`ItemResolver.lua`).
- Changes to how items are grouped by source (`TrackerModel.lua` and `SourceResolver.lua`).
- Adding new UI features (e.g., custom animations or new sorting options).

## 4. Success Criteria

1. **No Taint Logs:** Running the game with `/console taintLog 2`, entering combat, and hovering over tracker items must not produce taint errors originating from `TrackerUI.lua`.
2. **Visual Parity:** The new Side-Car must look indistinguishable from the current module implementation to the end user.
3. **Responsive Layout:** The Side-Car must seamlessly move up and down as quests are added/removed from the native tracker above it.
4. **Tooltip Stability:** Item tooltips must render reliably both in and out of combat without causing "Action Forbidden" errors.