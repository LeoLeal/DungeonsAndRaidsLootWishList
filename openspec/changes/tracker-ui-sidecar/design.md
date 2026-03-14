# Design: TrackerUI Side-Car Refactor

## 1. Architectural Strategy

The `TrackerUI` module will transition from an injected `ObjectiveTrackerModule` to a standalone "Side-Car" frame. It will maintain its role as a pure rendering engine, completely decoupled from the AddOn's business state (`WishlistStore` and `TrackerModel`).

The core rendering loop will be completely stateless: on every `Refresh(groups)` call, the UI will be destroyed and rebuilt from scratch based entirely on the provided data.

## 2. Components

### 2.1 The Master Container (`LootWishlistSideCar`)
A single, invisible `Frame` that acts as the parent for all wishlist UI elements. 
- **Anchoring:** It will use `hooksecurefunc(ObjectiveTrackerFrame, "Update", ...)` to continuously position itself immediately below the native tracker.
- **Visibility:** It will observe the global `ObjectiveTrackerFrame.isCollapsed` state (or its TWW equivalent) to hide the entire wishlist when the main tracker is minimized.
- **Sizing:** Its height will be dynamically recalculated at the end of every `Refresh` cycle based on the active blocks and lines.

### 2.2 UI Object Pools
To prevent memory leaks and frame bloat, `TrackerUI` will utilize Blizzard's native frame pooling system (`CreateFramePool`) for its UI components. This replaces the secure pooling previously handled by Blizzard's module system.

- **`headerPool`**: Manages the group headers (e.g., "Nerub-ar Palace").
- **`linePool`**: Manages individual item rows.

**Lifecycle:**
1. At the start of `TrackerUI.Refresh()`, `ReleaseAll()` is called on both pools, instantly hiding and resetting all frames.
2. As the `groups` data is iterated, `Acquire()` is called to retrieve fresh frames.
3. The frames are positioned relative to the previous frame in the list (stacking vertically).

### 2.3 Visual Mimicry (Templates)
Because we cannot use Blizzard's secure templates without risking taint, we will define our own pure Lua frame constructors that strictly mimic the current visual output:

**Header Block:**
- Font: `ObjectiveTrackerHeaderFont`
- Text format: Exact match to current behavior (`group.label` or `group.label (count)` when collapsed).
- Collapse Button: Reuses `ui-questtrackerbutton-secondary-collapse` and `ui-questtrackerbutton-secondary-expand` atlases, anchored vertically to the Header text exactly as it is today.
- Interaction: Clicks route to the Encounter Journal.

**Item Line:**
- Font: `ObjectiveFont`
- Dash: Uses `OBJECTIVE_DASH_STYLE_SHOW` emulation or hides based on `item.showTick`/`item.isBossHeader`.
- Colors: Boss headers use `r=0.65, g=0.65, b=0.65`. Regular items use `ITEM_QUALITY_COLORS` based on `GetItemInfo(item.displayLink)`.
- Layout: Boss headers are flush left. Items adhere to the existing `TrackerRowStyle.lua` for offsets (`textLeftOffset`) and indentation.
- Checkmark: Uses the custom atlas `ns.TrackerRowStyle.CHECK_ATLAS` placed where the dash would be, exactly as currently implemented.

### 2.4 Taint-Safe Tooltips
The `OnEnter` script for Item Lines will adhere strictly to secure execution guidelines:
1. `GameTooltip:Hide()` is called immediately to clear any existing tainted state.
2. `GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")` is used. **We will intentionally avoid anchoring the tooltip to our custom line frames** to prevent frame-level taint propagation during combat.
3. Tooltip populations (`SetHyperlink`, `SetItemByID`) occur only after the owner is cleanly set.

## 3. Data Flow

The integration with `LootWishList.lua` remains unchanged:

```lua
-- Existing flow in LootWishList.lua (Unchanged)
local groups = ns.TrackerModel.buildTrackerGroups(trackedItems)
ns.TrackerUI.Refresh(ns, groups)
```

Inside `TrackerUI.lua`:
```lua
-- Conceptual rendering loop
function TrackerUI.Refresh(ns, groups)
    headerPool:ReleaseAll()
    linePool:ReleaseAll()
    
    local currentY = 0
    
    for _, group in ipairs(groups) do
        local header = headerPool:Acquire()
        -- Setup header text, position at currentY
        currentY = currentY - headerHeight
        
        if not isCollapsed(group) then
            for _, item in ipairs(group.items) do
                local line = linePool:Acquire()
                -- Setup line text/icon, position at currentY
                currentY = currentY - lineHeight
            end
        end
    end
    
    SideCarContainer:SetHeight(-currentY)
end
```
### 2.5 Anchoring Strategy (The War Within Architecture)
The native tracker in TWW is managed by `ObjectiveTrackerContainerMixin`. Its `Update()` method handles stacking the registered modules vertically and calculating the final frame height.

To maintain the illusion of integration without taint, the Side-Car will use a `hooksecurefunc` on `ObjectiveTrackerContainerMixin.Update`.

**Anchor Logic Rules:**
1. **Target:** Only intercept updates where `self == ObjectiveTrackerFrame`.
2. **Visibility:** If `ObjectiveTrackerFrame:IsShown()` is false or `ObjectiveTrackerFrame.isCollapsed` is true, the Side-Car must call `Hide()`.
3. **Positioning:** Iterate through `self.modules` to find the last visible module (`module:IsShown() and module:GetContentsHeight() > 0`).
4. **Anchor Point:**
   - If a last module exists: `SetPoint("TOPLEFT", lastModule, "BOTTOMLEFT", 0, -self.moduleSpacing)`
   - If no native modules exist: `SetPoint("TOPLEFT", self, "TOPLEFT", 0, -self.topModulePadding)`
