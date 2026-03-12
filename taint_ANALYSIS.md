# Taint Analysis - DungeonsAndRaidsLootWishList

**Date:** March 11, 2026  
**Analyzer:** OpenSpec Architect - Explore Mode

---

## Executive Summary

This document captures the taint analysis performed on the LootWishList addon. Several potential taint sources have been identified, with the most critical being the collapse button's use of `SetScript` in TrackerUI.lua.

---

## 🚨 Critical Issues Found

### 1. Collapse Button SetScript (TrackerUI.lua, lines 29-92)

**Location:** `getOrCreateCollapseButton()` function, specifically line 89

```lua
local function getOrCreateCollapseButton(block)
  if block.collapseButton then
    return block.collapseButton
  end

  local button = CreateFrame("Button", nil, block)
  button:SetSize(16, 16)
  button:SetNormalAtlas(COLLAPSE_ATLAS)
  button:SetHighlightAtlas("ui-questtrackerbutton-yellow-highlight", "ADD")
  button:SetPushedAtlas("ui-questtrackerbutton-secondary-collapse-pressed")

  -- Ensure the button is clickable over the header text/frame.
  button:SetFrameLevel(block:GetFrameLevel() + 10)

  block.collapseButton = button
  return button
end
```

**Setup code (lines 89-92):**
```lua
button:SetScript("OnClick", function()
  ns.WishlistStore.toggleGroupCollapse(db, charKey, group.label)
  wishlistModule:MarkDirty()
end)
```

**Problem:** Using `SetScript` replaces the entire OnClick handler on a button that is a child of a secure block. This can introduce taint.

**Frame Hierarchy:**
```
block (native ObjectiveTracker block - SECURE)
   │
   ▼
┌─────────────────────┐
│ Button (created)   │ ◄── Created as child of block!
│  ├─ SetFrameLevel  │ ◄── Modifies frame level
│  └─ SetScript      │ ◄── ⚠️ REPLACES secure handler
│     (OnClick)      │
└─────────────────────┘
```

**Recommended Fix:** Use `HookScript` instead of `SetScript`:
```lua
button:HookScript("OnClick", function()
  ns.WishlistStore.toggleGroupCollapse(db, charKey, group.label)
  wishlistModule:MarkDirty()
end)
```

---

### 2. Texture Creation on Pooled Lines (TrackerUI.lua, line 136)

**Location:** `layoutContents()` function, lines 134-145

```lua
-- Tick texture for possessed items — placed where the Dash was.
if item.showTick and line.Dash then
  if not line.Check then
    line.Check = line:CreateTexture(nil, "ARTWORK")  -- ⚠️ TAINT RISK
  end
  line.Check:SetSize(ns.TrackerRowStyle.CHECK_SIZE, ns.TrackerRowStyle.CHECK_SIZE)
  line.Check:ClearAllPoints()
  line.Check:SetPoint("CENTER", line.Dash, "CENTER", -4, 0)
  line.Check:SetAtlas(ns.TrackerRowStyle.CHECK_ATLAS, false)
  line.Check:Show()
elseif line.Check then
  line.Check:Hide()
end
```

**Problem:** Creating a texture as a child of a natively pooled secure frame (the line returned from `block:AddObjective`) can introduce taint.

**Frame Hierarchy:**
```
block (native ObjectiveTracker block - SECURE POOL)
   │
   └── line (from block:AddObjective - NATIVE SECURE POOL)
        │
        ├── Dash (native)
        ├── Text (native FontString)
        └── Check (custom texture) ◄── Created as child = TAINT RISK
```

**Recommended Fix:** Consider one of the following approaches:
1. Create a separate overlay frame at the module level and position it over the line
2. Pre-create textures in `LayoutBlock` rather than on individual lines
3. Use a lookup table to track check visibility and render conditionally

---

### 3. Custom Properties on Pooled Lines (TrackerUI.lua, lines 147-150)

**Location:** `layoutContents()` function

```lua
-- Store item data on the line frame itself so the shared hook can access it.
line.lootWishList_tooltipRef = item.displayLink or item.tooltipRef
line.lootWishList_itemID = item.itemID
line.lootWishList_isBossHeader = item.isBossHeader
```

**Problem:** Attaching custom properties to natively pooled secure frames.

**Recommended Fix:** Use a lookup table keyed by `objectiveKey` instead:
```lua
local lineDataCache = {}  -- keyed by objectiveKey

-- Store data in lookup table
lineDataCache[objectiveKey] = {
  tooltipRef = item.displayLink or item.tooltipRef,
  itemID = item.itemID,
  isBossHeader = item.isBossHeader,
}
```

---

### 4. LootEvents.lua - GroupLootFrame Modification (LootEvents.lua, line 32)

**Location:** `HandleStartLootRoll()` function

```lua
if not frame.LootWishListTag then
  frame.LootWishListTag = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  -- ... font styling ...
end
frame.LootWishListTag:SetPoint("TOP", frame, "TOP", 0, 7)
frame.LootWishListTag:SetText(namespace.GetText("WISHLIST"))
frame.LootWishListTag:Show()
```

**Problem:** Creating a FontString as a child of the secure `GroupLootFrame` can propagate taint to the frame, breaking loot roll interactions.

**Frame Hierarchy:**
```
GroupLootFrame (SECURE Blizzard UI)
   │
   ├── IconFrame
   ├── Name
   ├── Timer
   └── LootWishListTag ◄── Created as child = TAINT!
```

**Recommended Fix:** Create an independent frame positioned over the roll frame using `SetPoint` to `UIParent`:
```lua
if not frame.LootWishListTag then
  frame.LootWishListTag = CreateFrame("Frame", nil, UIParent)
  local fs = frame.LootWishListTag:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fs:SetPoint("TOP", frame, "TOP", 0, 7)
  frame.LootWishListTag.fs = fs
  
  -- Hook frame's movement to keep our frame attached
  frame:HookScript("OnDragStart", function()
    frame.LootWishListTag:Hide()
  end)
  frame:HookScript("OnDragStop", function()
    frame.LootWishListTag:Show()
  end)
end
```

---

## ✅ What's Already Done Well

### TrackerUI.lua - HookScript Usage (lines 155-194)

The code correctly uses `HookScript` for the pooled tracker lines:

```lua
-- Native Tracker lines are securely pooled. Overwriting them with SetScript permanently
-- replaces their secure handler with our insecure handler, which taints them when they
-- recycle for secure modules like World Quests. We MUST use HookScript.
if not line.lootWishlistHooked then
  line.lootWishlistHooked = true

  line:HookScript("OnEnter", function(self)
    -- Only run our addon logic if this natively pooled frame currently belongs to our module.
    if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end
    -- ... tooltip logic ...
  end)

  line:HookScript("OnLeave", function(self)
    if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end
    trackerTooltip:Hide()
  end)

  line:HookScript("OnMouseUp", function(self, button)
    if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end
    if button == "LeftButton" and IsShiftKeyDown() and self.lootWishList_itemID then
      ns.RemoveTrackedItem(self.lootWishList_itemID)
    end
  end)
end
```

### Dedicated Tooltip (TrackerUI.lua, line 8)

```lua
local trackerTooltip = CreateFrame("GameTooltip", "LootWishListTrackerTooltip", UIParent, "GameTooltipTemplate")
```

Creates a private tooltip to prevent taint from propagating to the global shared GameTooltip.

### Tooltip Anchoring (TrackerUI.lua, line 168)

```lua
-- To avoid layout engine taint (attempting arithmetic on a secret number value)
-- when anchoring tooltips to securely pooled native tracker lines, we must
-- divorce the GameTooltip from the frame entirely using ANCHOR_NONE and SetPoint.
trackerTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
```

---

## Boss Headers Structure

From TrackerModel.lua, boss headers are structured as:

```lua
-- Boss Header row (fake item)
{
  itemID = "header:" .. bname,
  displayText = bname,
  isBossHeader = true,    -- Disables tooltip (line 163)
  showTick = false,
}
```

In TrackerUI.lua, when `isBossHeader = true`:
- `dashStyle` = `OBJECTIVE_DASH_STYLE_HIDE` (no dash)
- `colorStyle` = gray `{0.65, 0.65, 0.65}`
- `line.Text` positioned flush left (no indent)
- Tooltip disabled in OnEnter hook

---

## Frame Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ ObjectiveTrackerFrame (Blizzard)                                    │
│   │                                                                 │
│   └── wishlistModule (LootWishList)                                │
│       │                                                             │
│       ├── block (per group - e.g., "Vault of the Incarnates")     │
│       │    │                                                        │
│       │    ├── Header (native)                                      │
│       │    │                                                        │
│       │    ├── collapseButton (custom) ◄── ⚠️ SetScript used     │
│       │    │                                                        │
│       │    └── line 1 (from AddObjective - SECURE POOL)           │
│       │         │                                                  │
│       │         ├── Dash (native)                                  │
│       │         ├── Text (native) ◄── Modified with SetPoint      │
│       │         └── Check (custom) ◄── ⚠️ CreateTexture on pool   │
│       │                                                              │
│       ├── block (per group - e.g., "Aberrus")                     │
│       │    └── ...                                                  │
│       │                                                             │
│       └── block ("Other")                                          │
│            └── ...                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Recommended Fix Priority

| Priority | Issue | Location | Fix |
|----------|-------|----------|-----|
| **CRITICAL** | SetScript on collapse button | TrackerUI.lua:89 | Change to HookScript |
| **HIGH** | CreateTexture on pooled line | TrackerUI.lua:136 | Use overlay frame or lookup |
| **MEDIUM** | Custom props on pooled lines | TrackerUI.lua:148-150 | Use lookup table |
| **MEDIUM** | GroupLootFrame font string | LootEvents.lua:32 | Create independent frame |

---

## Debugging Tips

1. **Enable taint logging:**
   ```
   /console taintLog 1
   ```

2. **Test with specific features disabled:**
   - Temporarily disable collapse button functionality
   - Temporarily disable loot roll tagging
   - Use `/reload` between tests

3. **Check for specific error messages:**
   - "attempt to index a nil value"
   - "secure frame locked"
   - "taint"

---

## References

- WoW Wiki: [Secure Frames and Taint](https://wow.gamepedia.com/Secure_Frame_Tutorial)
- WoW Wiki: [Taint and Secure Templates](https://wow.gamepedia.com/Secure_Templates_and_Taint)
- ObjectiveTrackerFrame API documentation
- GroupLootFrame template structure
