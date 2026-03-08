local TrackerUI = {}

-- The native ObjectiveTracker module instance (created in Initialize).
local wishlistModule = nil

-- Cache of the last-known set of groups so LayoutContents can render them.
local currentGroups = {}

-- Track keys that have already appeared so we can detect newly-added items.
local knownRowKeys = {}

-- Reference to the addon namespace, set once during Initialize.
local ns = nil

---------------------------------------------------------------------------
-- LayoutContents – called by the tracker manager during its update cycle.
-- Reads `currentGroups` and produces blocks (one per loot-source group)
-- with lines (one per tracked item).
---------------------------------------------------------------------------
local function layoutContents(self)
  if not currentGroups or #currentGroups == 0 then
    return
  end

  local addedNewItem = false
  local seenKeys = {}

  for groupIndex, group in ipairs(currentGroups) do
    local block = self:GetBlock(groupIndex)
    block:SetHeader(group.label)

    for itemIndex, item in ipairs(group.items) do
      local objectiveKey = tostring(groupIndex) .. ":" .. tostring(item.itemID)

      -- Determine dash style: hide the dash for possessed items (show check instead).
      local dashStyle
      if item.showTick then
        dashStyle = OBJECTIVE_DASH_STYLE_HIDE
      else
        dashStyle = OBJECTIVE_DASH_STYLE_SHOW
      end

      -- Determine text colour from item quality.
      local colorStyle = nil
      if item.displayLink and type(GetItemInfo) == "function" then
        local _, _, itemQuality = GetItemInfo(item.displayLink)
        if itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality] then
          local qc = ITEM_QUALITY_COLORS[itemQuality]
          colorStyle = { r = qc.r, g = qc.g, b = qc.b }
        end
      end

      local line = block:AddObjective(objectiveKey, item.displayText, nil, nil, dashStyle, colorStyle)

      if line then
        -- Tick texture for possessed items — placed where the Dash was.
        if item.showTick and line.Dash then
          if not line.Check then
            line.Check = line:CreateTexture(nil, "ARTWORK")
          end
          line.Check:SetSize(ns.TrackerRowStyle.CHECK_SIZE, ns.TrackerRowStyle.CHECK_SIZE)
          line.Check:ClearAllPoints()
          line.Check:SetPoint("CENTER", line.Dash, "CENTER", -4, 0)
          line.Check:SetAtlas(ns.TrackerRowStyle.CHECK_ATLAS, false)
          line.Check:Show()
        elseif line.Check then
          line.Check:Hide()
        end


        -- Tooltip on hover. Uses the shared GameTooltip to prevent secure
        -- environment taint.
        local tooltipRef = item.displayLink or item.tooltipRef
        local itemID = item.itemID
        line:SetScript("OnEnter", function(self)
          -- Set the owner to UIParent (safe/secure) instead of self (insecure)
          -- using ANCHOR_CURSOR natively handles the mouse tracking position
          GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")

          if type(tooltipRef) == "string" and tooltipRef:find("item:") then
            GameTooltip:SetHyperlink(tooltipRef)
          elseif itemID then
            if GameTooltip.SetItemByID then
              GameTooltip:SetItemByID(itemID)
            end
          end
          GameTooltip:Show()
        end)
        line:SetScript("OnLeave", function()
          GameTooltip:Hide()
        end)

        -- Shift-click to remove.
        line:SetScript("OnMouseUp", function(_, button)
          if button == "LeftButton" and IsShiftKeyDown() then
            ns.RemoveTrackedItem(item.itemID)
          end
        end)
      end

      -- New-item detection.
      local uniqueKey = tostring(group.label) .. ":" .. tostring(item.itemID)
      seenKeys[uniqueKey] = true
      if not knownRowKeys[uniqueKey] then
        knownRowKeys[uniqueKey] = true
        addedNewItem = true
      end
    end

    if not self:LayoutBlock(block) then
      return
    end
  end

  -- Purge stale known-row entries.
  for key in pairs(knownRowKeys) do
    if not seenKeys[key] then
      knownRowKeys[key] = nil
    end
  end

  -- The module's EndLayout → wasDisplayedLastLayout handles the native header
  -- add animation automatically.  For individual item-level animations we rely
  -- on the module framework (new blocks slide in).
end

---------------------------------------------------------------------------
-- Initialize – create the module and register it with the tracker manager.
---------------------------------------------------------------------------
function TrackerUI.Initialize(namespace)
  if wishlistModule then
    return
  end

  ns = namespace

  -- Bail out if the TWW ObjectiveTracker module system is not available.
  if not ObjectiveTrackerFrame
      or not ObjectiveTrackerModuleMixin then
    return
  end

  -- Create the module frame.  The XML template already mixes in
  -- ObjectiveTrackerModuleMixin and calls OnLoad for us.
  local module = CreateFrame("Frame", "LootWishListTrackerModule", UIParent, "ObjectiveTrackerModuleTemplate")
  module:SetHeader(namespace.GetText("LOOT_WISHLIST"))

  -- Override LayoutContents to render our groups/items.
  module.LayoutContents = layoutContents

  -- Give a high uiOrder so the wishlist section appears after native sections.
  module.uiOrder = 1000

  wishlistModule = module
  namespace.trackerFrame = module -- keep backward compat reference

  -- ObjectiveTrackerManager:Init() runs after PLAYER_ENTERING_WORLD +
  -- VARIABLES_LOADED (via EventUtil.ContinueAfterAllEvents).  Our addon
  -- initializes at PLAYER_LOGIN which fires *before* those events.
  -- We must defer the registration so the container is ready.
  local function tryRegister()
    if ObjectiveTrackerFrame.AddModule then
      -- AddModule is the container-level method — it does not check the
      -- manager's container map, so it works as long as the frame exists.
      ObjectiveTrackerFrame:AddModule(module)
      module:MarkDirty()
      return true
    end
    return false
  end

  -- Try immediately in case Init already ran (e.g. /reload).
  if tryRegister() then
    return
  end

  -- Otherwise wait for the manager to finish initializing.
  local registrar = CreateFrame("Frame")
  registrar:RegisterEvent("PLAYER_ENTERING_WORLD")
  registrar:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    -- Small delay so EventUtil.ContinueAfterAllEvents has time to fire.
    C_Timer.After(0, function()
      tryRegister()
    end)
  end)
end

---------------------------------------------------------------------------
-- Refresh – store the groups data and mark the module dirty so the tracker
-- manager re-lays-out on its next cycle.
---------------------------------------------------------------------------
function TrackerUI.Refresh(namespace, groups)
  if not wishlistModule then
    TrackerUI.Initialize(namespace)
  end

  if not wishlistModule then
    return
  end

  currentGroups = groups or {}
  wishlistModule:MarkDirty()
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TrackerUI = TrackerUI
end

return TrackerUI
