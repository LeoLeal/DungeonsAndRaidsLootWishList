local TrackerUI = {}

-- The native ObjectiveTracker module instance (created in Initialize).
local wishlistModule = nil

-- A private tooltip to prevent taint from propagating to the global shared GameTooltip when
-- using functions like SetItemByID which can allocate table data internally.
local trackerTooltip = CreateFrame("GameTooltip", "LootWishListTrackerTooltip", UIParent, "GameTooltipTemplate")

-- Cache of the last-known set of groups so LayoutContents can render them.
local currentGroups = {}

-- Track keys that have already appeared so we can detect newly-added items.
local knownRowKeys = {}

-- Reference to the addon namespace, set once during Initialize.
local ns = nil

-- Native WoW collapse/expand button atlases.
local COLLAPSE_ATLAS = "ui-questtrackerbutton-secondary-collapse"
local EXPAND_ATLAS = "ui-questtrackerbutton-secondary-expand"

local function getCharacterKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Unknown"
  return string.format("%s-%s", name, realm)
end

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

---------------------------------------------------------------------------
-- LayoutContents – called by the tracker manager during its update cycle.
-- Reads `currentGroups` and produces blocks (one per loot-source group)
-- with lines (one per tracked item).
---------------------------------------------------------------------------
local function layoutContents(self)
  if not currentGroups or #currentGroups == 0 then
    return
  end

  local seenKeys = {}
  local charKey = getCharacterKey()
  local db = LootWishListDB

  for groupIndex, group in ipairs(currentGroups) do
    local itemCount = #group.items
    if itemCount > 0 then
      local block = self:GetBlock(group.label)
      local isCollapsed = ns.WishlistStore.isGroupCollapsed(db, charKey, group.label)

      -- Update header with count if collapsed.
      local headerText = group.label
      if isCollapsed and itemCount > 0 then
        headerText = string.format("%s (%d)", group.label, itemCount)
      end
      block:SetHeader(headerText)

      -- Setup collapse button.
      block:AdjustRightEdgeOffset(-20)
      local button = getOrCreateCollapseButton(block)
      button:ClearAllPoints()
      if block.Header then
        -- Vertical alignment with the title text inside the Header.
        button:SetPoint("RIGHT", block.Header, "RIGHT", 0, 0)
      else
        -- Fallback if Header is not found for some reason.
        button:SetPoint("RIGHT", block, "RIGHT", 0, 0)
        button:SetPoint("TOP", block, "TOP", 0, 0)
      end
      button:SetNormalAtlas(isCollapsed and EXPAND_ATLAS or COLLAPSE_ATLAS)
      button:SetPushedAtlas(isCollapsed and (EXPAND_ATLAS .. "-pressed") or (COLLAPSE_ATLAS .. "-pressed"))

      button:SetScript("OnClick", function()
        ns.WishlistStore.toggleGroupCollapse(db, charKey, group.label)
        wishlistModule:MarkDirty()
      end)

      if not isCollapsed then
        for itemIndex, item in ipairs(group.items) do
          local objectiveKey = tostring(groupIndex) .. ":" .. tostring(item.itemID)

          -- Determine dash style: hide the dash for possessed items (show check instead) or boss headers.
          local dashStyle
          if item.showTick or item.isBossHeader then
            dashStyle = OBJECTIVE_DASH_STYLE_HIDE
          else
            dashStyle = OBJECTIVE_DASH_STYLE_SHOW
          end

          -- Determine text colour from item quality or use gray for boss headers.
          local colorStyle = nil
          if item.isBossHeader then
            colorStyle = { r = 0.65, g = 0.65, b = 0.65 }
          elseif item.displayLink and type(GetItemInfo) == "function" then
            local _, _, itemQuality = GetItemInfo(item.displayLink)
            if itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality] then
              local qc = ITEM_QUALITY_COLORS[itemQuality]
              colorStyle = { r = qc.r, g = qc.g, b = qc.b }
            end
          end

          local line = block:AddObjective(objectiveKey, item.displayText, nil, nil, dashStyle, colorStyle)
          if line and line.Text then
            line.Text:ClearAllPoints()
            if item.isBossHeader then
              -- Boss headers are flush with the left side (no indentation).
              line.Text:SetPoint("TOPLEFT", line, "TOPLEFT", 0, 0)
            else
              -- Regular items use the standard indentation from TrackerRowStyle.
              local layout = ns.TrackerRowStyle.getRowLayout(item.showTick)
              line.Text:SetPoint("TOPLEFT", line, "TOPLEFT", layout.textLeftOffset, 0)
            end
            line.Text:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 0, 0)
          end

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

            -- Store item data on the line frame itself so the shared hook can access it.
            line.lootWishList_tooltipRef = item.displayLink or item.tooltipRef
            line.lootWishList_itemID = item.itemID
            line.lootWishList_isBossHeader = item.isBossHeader

            -- Native Tracker lines are securely pooled. Overwriting them with SetScript permanently
            -- replaces their secure handler with our insecure handler, which taints them when they
            -- recycle for secure modules like World Quests. We MUST use HookScript.
            if not line.lootWishlistHooked then
              line.lootWishlistHooked = true

              line:HookScript("OnEnter", function(self)
                -- Only run our addon logic if this natively pooled frame currently belongs to our module.
                if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end

                -- Disable tooltip for boss headers.
                if self.lootWishList_isBossHeader then return end

                -- To avoid layout engine taint (attempting arithmetic on a secret number value)
                -- when anchoring tooltips to securely pooled native tracker lines, we must
                -- divorce the GameTooltip from the frame entirely using ANCHOR_NONE and SetPoint.
                trackerTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")

                local ref = self.lootWishList_tooltipRef
                local id = self.lootWishList_itemID

                if type(ref) == "string" and ref:find("item:") then
                  trackerTooltip:SetHyperlink(ref)
                elseif id then
                  if trackerTooltip.SetItemByID then
                    trackerTooltip:SetItemByID(id)
                  end
                end
                trackerTooltip:Show()
              end)

              line:HookScript("OnLeave", function(self)
                if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end
                trackerTooltip:Hide()
              end)

              -- Shift-click to remove.
              line:HookScript("OnMouseUp", function(self, button)
                if not self.parentBlock or self.parentBlock.parentModule ~= wishlistModule then return end
                if button == "LeftButton" and IsShiftKeyDown() and self.lootWishList_itemID then
                  ns.RemoveTrackedItem(self.lootWishList_itemID)
                end
              end)
            end
          end

          -- New-item detection.
          local uniqueKey = tostring(group.label) .. ":" .. tostring(item.itemID)
          seenKeys[uniqueKey] = true
          if not knownRowKeys[uniqueKey] then
            knownRowKeys[uniqueKey] = true
          end
        end
      end

      if not self:LayoutBlock(block) then
        return
      end
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

  -- The `ns` variable is already initialized at the top of the file.
  -- We assign the `namespace` parameter to it here to ensure it's the correct addon namespace.
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
