local _, namespace = ...

local TrackerContextMenu = {}

local trackerContextMenu = nil
local CONTEXT_MENU_WIDTH = 120
local CONTEXT_MENU_ROW_HEIGHT = 20
local CONTEXT_MENU_PADDING_X = 8
local CONTEXT_MENU_PADDING_Y = 4

function TrackerContextMenu.Ensure(runtimeNamespace)
  if trackerContextMenu then
    return trackerContextMenu
  end

  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  trackerContextMenu = CreateFrame("Frame", "LootWishListTrackerContextMenu", UIParent, template)
  trackerContextMenu:SetToplevel(true)
  trackerContextMenu:SetFrameStrata("TOOLTIP")
  trackerContextMenu:SetClampedToScreen(true)
  trackerContextMenu:EnableMouse(true)
  trackerContextMenu:SetSize(CONTEXT_MENU_WIDTH, CONTEXT_MENU_ROW_HEIGHT + (CONTEXT_MENU_PADDING_Y * 2))

  if type(UISpecialFrames) == "table" then
    local alreadyRegistered = false
    for _, frameName in ipairs(UISpecialFrames) do
      if frameName == "LootWishListTrackerContextMenu" then
        alreadyRegistered = true
        break
      end
    end
    if not alreadyRegistered then
      table.insert(UISpecialFrames, "LootWishListTrackerContextMenu")
    end
  end

  if trackerContextMenu.SetBackdrop then
    trackerContextMenu:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    trackerContextMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    trackerContextMenu:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)
  end

  trackerContextMenu.actionButton = CreateFrame("Button", nil, trackerContextMenu)
  trackerContextMenu.actionButton:SetPoint("TOPLEFT", trackerContextMenu, "TOPLEFT", CONTEXT_MENU_PADDING_X, -CONTEXT_MENU_PADDING_Y)
  trackerContextMenu.actionButton:SetPoint("TOPRIGHT", trackerContextMenu, "TOPRIGHT", -CONTEXT_MENU_PADDING_X, -CONTEXT_MENU_PADDING_Y)
  trackerContextMenu.actionButton:SetHeight(CONTEXT_MENU_ROW_HEIGHT)
  trackerContextMenu.actionButton:RegisterForClicks("LeftButtonUp")

  trackerContextMenu.actionButton.highlight = trackerContextMenu.actionButton:CreateTexture(nil, "BACKGROUND")
  trackerContextMenu.actionButton.highlight:SetAllPoints()
  trackerContextMenu.actionButton.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  trackerContextMenu.actionButton.highlight:SetBlendMode("ADD")
  trackerContextMenu.actionButton.highlight:Hide()

  trackerContextMenu.actionButton.text = trackerContextMenu.actionButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  trackerContextMenu.actionButton.text:SetPoint("LEFT", trackerContextMenu.actionButton, "LEFT", 6, 0)
  trackerContextMenu.actionButton.text:SetPoint("RIGHT", trackerContextMenu.actionButton, "RIGHT", -6, 0)
  trackerContextMenu.actionButton.text:SetJustifyH("LEFT")
  trackerContextMenu.actionButton.text:SetWordWrap(false)
  trackerContextMenu.actionButton.text:SetTextColor(1, 1, 1)
  trackerContextMenu.actionButton.text:SetText(runtimeNamespace.GetText("REMOVE"))

  trackerContextMenu.actionButton:SetScript("OnEnter", function(self)
    self.highlight:Show()
  end)
  trackerContextMenu.actionButton:SetScript("OnLeave", function(self)
    self.highlight:Hide()
  end)
  trackerContextMenu.actionButton:SetScript("OnClick", function()
    local itemID = trackerContextMenu and trackerContextMenu.activeItemID or nil
    runtimeNamespace.TrackerHeaders.PlayMenuCheckboxSound()
    if trackerContextMenu then
      trackerContextMenu:Hide()
    end
    if itemID then
      runtimeNamespace.RemoveTrackedItem(itemID)
    end
  end)

  trackerContextMenu:SetScript("OnShow", function(self)
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
  end)
  trackerContextMenu:SetScript("OnHide", function(self)
    self.activeOwner = nil
    self.activeItemID = nil
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
    self.actionButton.highlight:Hide()
  end)
  trackerContextMenu:SetScript("OnUpdate", function(self)
    if self.activeOwner and not self.activeOwner:IsShown() then
      self:Hide()
      return
    end

    if type(IsMouseButtonDown) ~= "function" then
      return
    end

    local isDown = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
    if isDown and not self.mouseWasDown then
      self.mouseWasDown = true
      local focus = type(GetMouseFocus) == "function" and GetMouseFocus() or nil
      self.pendingOutsideDismiss = not runtimeNamespace.TrackerUtils.IsDescendantOf(focus, self)
    elseif not isDown and self.mouseWasDown then
      self.mouseWasDown = false
      if self.pendingOutsideDismiss then
        self:Hide()
        return
      end
    elseif not isDown then
      self.pendingOutsideDismiss = false
    end
  end)

  return trackerContextMenu
end

function TrackerContextMenu.Close()
  if trackerContextMenu then
    trackerContextMenu:Hide()
  end
end

function TrackerContextMenu.Show(runtimeNamespace, row, hideTooltip, clearHovered)
  if not row or row.isBossHeader or not row.itemID then
    return
  end

  local menu = TrackerContextMenu.Ensure(runtimeNamespace)
  if not menu then
    return
  end

  hideTooltip()
  clearHovered()
  TrackerContextMenu.Close()
  menu.activeOwner = row
  menu.activeItemID = row.itemID
  menu.actionButton.text:SetText(runtimeNamespace.GetText("REMOVE"))
  menu:SetWidth(math.max(CONTEXT_MENU_WIDTH, menu.actionButton.text:GetStringWidth() + (CONTEXT_MENU_PADDING_X * 2) + 24))
  menu:SetHeight(CONTEXT_MENU_ROW_HEIGHT + (CONTEXT_MENU_PADDING_Y * 2))

  local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (cursorX / scale) + 2, (cursorY / scale) - 2)
  menu:Show()
  runtimeNamespace.TrackerHeaders.PlayMenuCheckboxSound()
end

if type(namespace) == "table" then
  namespace.TrackerContextMenu = TrackerContextMenu
end

return TrackerContextMenu
