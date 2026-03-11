## Context

The Loot Wishlist addon displays tracked dungeon and raid loot in the Objective Tracker, grouped by source (dungeon/raid name). Currently, all groups are always expanded, which can lead to a long, unwieldy list as players track more items.

The Objective Tracker system provides module-level collapse (the entire wishlist section can collapse), but individual blocks within a module do not have native collapse support. We need to implement custom collapse behavior while maintaining visual consistency with the native WoW UI.

## Goals / Non-Goals

**Goals:**
- Add collapsible behavior to each source group in the wishlist tracker
- Persist collapsed/expanded state per character across sessions
- Display item count in group header when collapsed (e.g., "Brackenhide Hollow (3)")
- Use native WoW collapse button atlases for visual consistency
- Hide groups with zero items (preserve existing behavior)

**Non-Goals:**
- Collapsing individual boss headers within raids (not in scope)
- Auto-expand groups when new items are added (stay collapsed, update count)
- Multi-select or bulk collapse/expand operations

## Decisions

### 1. Single Module Architecture (Option B)

**Decision:** Implement custom collapse within a single module rather than creating multiple modules (one per source group).

**Rationale:** Keeps all wishlist content under a single module header, avoiding "UI pollution" from multiple module headers. The native module header remains the single collapse point for the entire wishlist section.

**Alternative Considered:** Multiple modules (one per source group) - would leverage native collapse but creates one header per group, which was deemed too cluttered.

### 2. Button Placement: Right Edge of Header

**Decision:** Anchor collapse buttons to the right edge of the group header frame, using `AdjustRightEdgeOffset` to reserve space.

**Rationale:** This matches how native WoW headers work (e.g., quest block buttons, right-edge frames). The title text automatically shifts left to make room for the button.

**Implementation:**
```lua
block:AdjustRightEdgeOffset(-20)  -- Reserve 20px on right
button:SetPoint("RIGHT", block, "RIGHT", -5, 0)  -- 5px padding
```

### 3. Native Atlases for Buttons

**Decision:** Use the native WoW collapse/expand atlases:
- Collapsed (expand button): `ui-questtrackerbutton-secondary-expand`
- Expanded (collapse button): `ui-questtrackerbutton-secondary-collapse`
- Pressed variants: `ui-questtrackerbutton-secondary-expand-pressed` / `-collapse-pressed`

**Rationale:** Matches the look and feel of the native module header minimize button exactly.

### 4. Persistence Structure

**Decision:** Store collapsed groups as a simple set in character data:

```lua
db.characters[characterKey].collapsedGroups = {
  ["Vault of the Incarnates"] = true,  -- true = collapsed
  ["Brackenhide Hollow"] = true,
}
```

**Rationale:** Simple key-value structure. `true` means collapsed. Missing key means expanded (default). No need to store expanded groups explicitly.

### 5. Default State: Expanded

**Decision:** Groups default to expanded when the addon first loads for a character.

**Rationale:** Less surprising to new users. Users who want collapse can manually collapse groups.

### 6. Item Count Display

**Decision:** Show item count in parentheses when group is collapsed: `"Group Name (3)"`. Do not show count when expanded.

**Rationale:** Provides useful context about what's hidden without needing to expand. Matches common UI patterns.

## Risks / Trade-offs

### Risk: Block Pooling / Recycling

**Risk:** The Objective Tracker pools and recycles block frames. Our collapse button must handle this correctly - either reuse existing button or create new one per block acquisition.

**Mitigation:** Check for existing `block.collapseButton` before creating. Use the block's Reset() lifecycle to manage button state appropriately.

### Risk: Button Interaction with Header Click

**Risk:** The block header has existing click handlers (e.g., for context menus). Our button click must not interfere.

**Mitigation:** Button handles its own clicks via `SetScript("OnClick")`. The button sits beside the header text, not on top of it. Test in-game for any conflicts.

### Risk: Dynamic Group Changes

**Risk:** Groups can appear/disappear as items are tracked/untracked. Collapse state for a newly appearing group should be expanded by default (not inherited from some other group).

**Mitigation:** When rendering a group, always look up its specific label in `collapsedGroups`. If not present, default to expanded.

### Risk: Layout After Collapse Toggle

**Risk:** Toggling collapse changes the content height, which may affect the overall tracker layout and scrolling.

**Mitigation:** After toggling, call `wishlistModule:MarkDirty()` to trigger a full layout recalculation. The Objective Tracker will handle repositioning.

### Trade-off: Custom Implementation vs Native

**Trade-off:** Native blocks don't support collapse, so we implement custom behavior. This means:
- More code to maintain
- Potential for visual inconsistencies if WoW UI changes

**Mitigation:** Use native APIs where possible (atlases, right-edge positioning). Keep implementation focused and isolated in TrackerUI.lua.
