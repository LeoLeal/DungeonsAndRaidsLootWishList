local _, namespace = ...

local TrackerFilterMenu = {}

local FILTER_BUTTON_NORMAL_ATLAS = "UI-QuestTrackerButton-Filter"
local FILTER_BUTTON_PRESSED_ATLAS = "UI-QuestTrackerButton-Filter-Pressed"
local FILTER_BUTTON_HIGHLIGHT_ATLAS = "UI-QuestTrackerButton-Red-Highlight"
local MENU_MIN_WIDTH = 150
local MENU_ROW_HEIGHT = 26
local MENU_PADDING_X = 12
local MENU_PADDING_Y = 10

local filterMenu = nil

local function getSelectionState(runtimeNamespace)
  if not runtimeNamespace or type(runtimeNamespace.GetTrackerTagFilterSelection) ~= "function" then
    return {}
  end

  return runtimeNamespace.GetTrackerTagFilterSelection()
end

local function getTagCounts(runtimeNamespace)
  local allTags = runtimeNamespace.GetWishlistTags()
  local usedTags = runtimeNamespace.GetUsedWishlistTags()
  return allTags, usedTags
end

local function pruneSelection(runtimeNamespace)
  local selection = getSelectionState(runtimeNamespace)
  local allTags, usedTags = getTagCounts(runtimeNamespace)
  local selectedCount = 0
  local usedLookup = {}

  if #allTags <= 1 then
    for normalized in pairs(selection) do
      selection[normalized] = nil
    end
    return selection, usedTags, 0, #allTags
  end

  for _, tagLabel in ipairs(usedTags) do
    local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(tagLabel)
    if normalized then
      usedLookup[normalized] = true
    end
  end

  for normalized in pairs(selection) do
    if usedLookup[normalized] then
      selectedCount = selectedCount + 1
    else
      selection[normalized] = nil
    end
  end

  return selection, usedTags, selectedCount, #allTags
end

local function tintButtonTextures(button, r, g, b, a)
  if not button then
    return
  end

  local textures = {
    button.GetNormalTexture and button:GetNormalTexture() or nil,
    button.GetPushedTexture and button:GetPushedTexture() or nil,
    button.GetHighlightTexture and button:GetHighlightTexture() or nil,
  }

  for _, texture in ipairs(textures) do
    if texture and texture.SetVertexColor then
      texture:SetVertexColor(r, g, b, a or 1)
    end
  end
end

function TrackerFilterMenu.ApplyButtonState(runtimeNamespace, button)
  if not button then
    return
  end

  local allTags = runtimeNamespace.GetWishlistTags()
  button:SetNormalAtlas(FILTER_BUTTON_NORMAL_ATLAS)
  button:SetPushedAtlas(FILTER_BUTTON_PRESSED_ATLAS)
  button:SetHighlightAtlas(FILTER_BUTTON_HIGHLIGHT_ATLAS, "ADD")
  button:SetEnabled(#allTags > 1)

  if #allTags > 1 then
    tintButtonTextures(button, 1, 1, 1, 1)
  else
    tintButtonTextures(button, 0.45, 0.45, 0.45, 1)
  end
end

function TrackerFilterMenu.GetSelectedTagLookup(runtimeNamespace)
  local selection, usedTags, selectedCount = pruneSelection(runtimeNamespace)
  if selectedCount == 0 or selectedCount == #usedTags then
    return nil
  end

  local selectedLookup = {}
  for normalized in pairs(selection) do
    selectedLookup[normalized] = true
  end

  return selectedLookup
end

local function ensureMenu(runtimeNamespace)
  if filterMenu then
    return filterMenu
  end

  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  filterMenu = CreateFrame("Frame", "LootWishListTrackerFilterMenu", UIParent, template)
  filterMenu:SetToplevel(true)
  filterMenu:SetFrameStrata("TOOLTIP")
  filterMenu:SetClampedToScreen(true)
  filterMenu:EnableMouse(true)

  if type(UISpecialFrames) == "table" then
    local known = false
    for _, frameName in ipairs(UISpecialFrames) do
      if frameName == "LootWishListTrackerFilterMenu" then
        known = true
        break
      end
    end
    if not known then
      table.insert(UISpecialFrames, "LootWishListTrackerFilterMenu")
    end
  end

  if filterMenu.SetBackdrop then
    filterMenu:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    filterMenu:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    filterMenu:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)
  end

  filterMenu.title = filterMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  filterMenu.title:SetPoint("TOPLEFT", filterMenu, "TOPLEFT", MENU_PADDING_X, -MENU_PADDING_Y)
  filterMenu.title:SetJustifyH("LEFT")

  filterMenu.rows = {}

  filterMenu:SetScript("OnShow", function(self)
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
  end)
  filterMenu:SetScript("OnHide", function(self)
    self.ownerButton = nil
    self.runtimeNamespace = nil
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
  end)
  filterMenu:SetScript("OnUpdate", function(self)
    if not self.ownerButton or not self.ownerButton:IsShown() then
      self:Hide()
      return
    end

    if type(IsMouseButtonDown) ~= "function" then
      return
    end

    local isDown = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
    if isDown and not self.mouseWasDown then
      self.mouseWasDown = true
      self.pendingOutsideDismiss = not (namespace.FrameUtils.IsCursorOverFrame(self) or namespace.FrameUtils.IsCursorOverFrame(self.ownerButton))
    elseif not isDown and self.mouseWasDown then
      self.mouseWasDown = false
      if self.pendingOutsideDismiss then
        self:Hide()
      end
    elseif not isDown then
      self.pendingOutsideDismiss = false
    end
  end)

  filterMenu:Hide()
  return filterMenu
end

local function ensureRow(menu, index)
  local row = menu.rows[index]
  if row then
    return row
  end

  row = CreateFrame("Button", nil, menu)
  row:SetHeight(MENU_ROW_HEIGHT)
  row:RegisterForClicks("LeftButtonUp")

  row.highlight = row:CreateTexture(nil, "BACKGROUND")
  row.highlight:SetAllPoints()
  row.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  row.highlight:SetBlendMode("ADD")
  row.highlight:Hide()

  row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.checkbox:SetSize(22, 22)
  row.checkbox:EnableMouse(false)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.label:SetPoint("LEFT", row.checkbox, "RIGHT", 4, 0)
  row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)

  row:SetScript("OnEnter", function(self)
    self.highlight:Show()
  end)
  row:SetScript("OnLeave", function(self)
    self.highlight:Hide()
  end)
  row:SetScript("OnClick", function(self)
    local runtimeNamespace = self.runtimeNamespace
    if not runtimeNamespace or not self.tagLabel then
      return
    end

    local selection = getSelectionState(runtimeNamespace)
    local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(self.tagLabel)
    if not normalized then
      return
    end

    if selection[normalized] then
      selection[normalized] = nil
    else
      selection[normalized] = true
    end

    runtimeNamespace.TrackerHeaders.PlayMenuCheckboxSound()
    runtimeNamespace.RefreshTracker()
  end)

  menu.rows[index] = row
  return row
end

function TrackerFilterMenu.Refresh(runtimeNamespace)
  local menu = ensureMenu(runtimeNamespace)
  menu.runtimeNamespace = runtimeNamespace
  menu.title:SetText(runtimeNamespace.GetText("TAG_FILTER"))

  local selection, usedTags, _, totalTags = pruneSelection(runtimeNamespace)
  if totalTags <= 1 then
    menu:Hide()
    return
  end

  local longestWidth = menu.title:GetStringWidth()
  local topOffset = MENU_PADDING_Y + 20

  for index, tagLabel in ipairs(usedTags) do
    local row = ensureRow(menu, index)
    local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(tagLabel)
    row.runtimeNamespace = runtimeNamespace
    row.tagLabel = tagLabel
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", MENU_PADDING_X, -topOffset)
    row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -MENU_PADDING_X, -topOffset)
    row.checkbox:SetChecked(selection[normalized] == true)
    row.label:SetText(tagLabel)
    row:Show()
    longestWidth = math.max(longestWidth, row.label:GetStringWidth())
    topOffset = topOffset + MENU_ROW_HEIGHT
  end

  for index = #usedTags + 1, #menu.rows do
    menu.rows[index]:Hide()
    menu.rows[index].runtimeNamespace = nil
    menu.rows[index].tagLabel = nil
  end

  menu:SetWidth(math.max(MENU_MIN_WIDTH, longestWidth + 52))
  menu:SetHeight(topOffset + MENU_PADDING_Y)
end

function TrackerFilterMenu.Close()
  if filterMenu then
    filterMenu:Hide()
  end
end

function TrackerFilterMenu.Toggle(runtimeNamespace, ownerButton)
  local allTags = runtimeNamespace.GetWishlistTags()
  if #allTags <= 1 or not ownerButton or not ownerButton:IsEnabled() then
    TrackerFilterMenu.Close()
    return
  end

  local menu = ensureMenu(runtimeNamespace)
  if menu:IsShown() and menu.ownerButton == ownerButton then
    menu:Hide()
    return
  end

  menu.ownerButton = ownerButton
  menu.runtimeNamespace = runtimeNamespace
  TrackerFilterMenu.Refresh(runtimeNamespace)
  menu:ClearAllPoints()
  menu:SetPoint("TOPRIGHT", ownerButton, "BOTTOMRIGHT", 0, -4)
  menu:Show()
end

if type(namespace) == "table" then
  namespace.TrackerFilterMenu = TrackerFilterMenu
end

return TrackerFilterMenu
