local _, namespace = ...

local WishlistTagPopover = {}

local DELETE_NORMAL_ATLAS = "128-RedButton-Delete"
local DELETE_PRESSED_ATLAS = "128-RedButton-Delete-Pressed"
local DELETE_DISABLED_ATLAS = "128-RedButton-Delete-Disabled"
local DELETE_HIGHLIGHT_ATLAS = "128-RedButton-Delete-Highlight"
local TAG_ROW_HEIGHT = 26
local TAG_CHECKBOX_SIZE = 24
local TAG_LABEL_GAP = 4
local TAG_LABEL_FONT_DELTA = 2
local TAG_DELETE_BUTTON_SIZE = 24
local POPOVER_ADD_INPUT_OFFSET_X = 8
local POPOVER_MIN_WIDTH = 180
local POPOVER_WIDTH_REDUCTION = 0
local POPOVER_PADDING = 16
local POPOVER_ROW_GAP = 2
local POPOVER_BUTTON_GAP = 8
local TAG_DELETE_DIALOG_WIDTH = 280
local TAG_DELETE_DIALOG_HEIGHT = 256
local TAG_DELETE_ITEM_ICON_SIZE = 40
local TAG_DELETE_ITEM_NAME_WIDTH = 150
local TAG_DELETE_ITEM_GAP = 16
local TAG_DELETE_ITEM_ROW_HEIGHT = 42
local TAG_DELETE_ITEM_PANEL_HEIGHT = 112
local TAG_DELETE_ITEM_CONTENT_WIDTH = 220
local TAG_DELETE_DIALOG_BASE_HEIGHT = TAG_DELETE_DIALOG_HEIGHT - TAG_DELETE_ITEM_PANEL_HEIGHT
local TAG_DELETE_ITEM_LIST_OFFSET_X = 10
local POPOVER_HEADER_HEIGHT = 32
local POPOVER_BOTTOM_PADDING = 34

local tagPopover = nil
local tagDeleteDialog = nil

local function buildAssignedLookup(tags)
  local lookup = {}

  for _, tagLabel in ipairs(tags or {}) do
    local normalized = namespace.WishlistStore.normalizeTagLabel(tagLabel)
    if normalized then
      lookup[normalized] = true
    end
  end

  return lookup
end

local function getDisplayItemName(runtimeNamespace, itemID)
  return runtimeNamespace.GetItemInfoName(itemID) or ("Item " .. tostring(itemID))
end

local function applyHistoryFrameChrome(frame)
  if not frame then
    return
  end

  if frame.SetBackdrop then
    frame:SetBackdrop(nil)
  end

  if not frame.historyChrome then
    frame.historyChrome = CreateFrame("Frame", nil, frame, "DefaultPanelFlatTemplate")
    frame.historyChrome:SetAllPoints(frame)
    frame.historyChrome:EnableMouse(false)
  end

  frame.historyChrome:Show()
end

local function getDeleteDialogTooltipRef(runtimeNamespace, itemData)
  local tooltipRef = runtimeNamespace.ItemResolver.getTooltipRef(itemData)
  if type(tooltipRef) == "string" and tooltipRef ~= "" then
    return tooltipRef
  end

  local itemID = itemData and itemData.itemID or nil
  if type(GetItemInfo) == "function" then
    local itemLink = select(2, GetItemInfo(itemID))
    if type(itemLink) == "string" and itemLink ~= "" then
      return runtimeNamespace.ItemResolver.getTooltipRef({ itemID = itemID, itemLink = itemLink }) or itemLink
    end
  end

  return string.format("|Hitem:%d::::::::::::|h[%s]|h", itemID, getDisplayItemName(runtimeNamespace, itemID))
end

local function getDeleteDialogItemIcon(runtimeNamespace, itemData)
  local tooltipRef = getDeleteDialogTooltipRef(runtimeNamespace, itemData)
  if type(GetItemIcon) == "function" then
    return GetItemIcon(tooltipRef) or GetItemIcon(itemData and itemData.itemID or nil)
  end

  return nil
end

local function getDeleteDialogItemColor(itemLink)
  if type(itemLink) == "string" then
    local hexColor = itemLink:match("|c[fF][fF](%x%x%x%x%x%x)")
    if hexColor and #hexColor == 6 then
      local r = tonumber(hexColor:sub(1, 2), 16)
      local g = tonumber(hexColor:sub(3, 4), 16)
      local b = tonumber(hexColor:sub(5, 6), 16)
      if r and g and b then
        return r / 255, g / 255, b / 255
      end
    end
  end

  if type(GetItemInfo) == "function" and type(itemLink) == "string" then
    local quality = select(3, GetItemInfo(itemLink))
    if quality and type(GetItemQualityColor) == "function" then
      local r, g, b = GetItemQualityColor(quality)
      if r and g and b then
        return r, g, b
      end
    end
  end

  return 1, 1, 1
end

local function ensureDeleteDialogItemRow(dialog, index)
  dialog.itemRows = dialog.itemRows or {}

  local row = dialog.itemRows[index]
  if row then
    return row
  end

  row = CreateFrame("Button", nil, dialog.itemListContent)
  row:SetHeight(TAG_DELETE_ITEM_ROW_HEIGHT)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetSize(TAG_DELETE_ITEM_ICON_SIZE, TAG_DELETE_ITEM_ICON_SIZE)
  row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)

  row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.name:SetPoint("LEFT", row.icon, "RIGHT", TAG_DELETE_ITEM_GAP, 0)
  row.name:SetWidth(TAG_DELETE_ITEM_NAME_WIDTH)
  row.name:SetHeight(TAG_DELETE_ITEM_ROW_HEIGHT)
  row.name:SetJustifyH("LEFT")
  row.name:SetJustifyV("MIDDLE")
  row.name:SetSpacing(1)
  do
    local font, size, flags = row.name:GetFont()
    if font and size then
      row.name:SetFont(font, size + 2, flags)
    end
  end

  row.nameFrame = row:CreateTexture(nil, "ARTWORK")
  row.nameFrame:SetTexture("Interface\\QuestFrame\\UI-QuestItemNameFrame")
  row.nameFrame:SetSize(140, 62)
  row.nameFrame:SetPoint("BOTTOMRIGHT", row.name, "BOTTOMRIGHT", 13, -12)
  row.nameFrame:SetPoint("TOPLEFT", row.name, "TOPLEFT", -21, 12)

  row:SetScript("OnEnter", function(self)
    if not self.tooltipRef then
      return
    end

    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
    GameTooltip:SetHyperlink(self.tooltipRef)
    if ShoppingTooltip1 then
      ShoppingTooltip1:Hide()
    end
    if ShoppingTooltip2 then
      ShoppingTooltip2:Hide()
    end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function()
    GameTooltip:Hide()
    if ShoppingTooltip1 then
      ShoppingTooltip1:Hide()
    end
    if ShoppingTooltip2 then
      ShoppingTooltip2:Hide()
    end
  end)

  dialog.itemRows[index] = row
  return row
end

local function updateDeleteDialogRows(runtimeNamespace, dialog, affectedItems)
  local topOffset = 0

  for index, item in ipairs(affectedItems or {}) do
    local row = ensureDeleteDialogItemRow(dialog, index)
    local tooltipRef = getDeleteDialogTooltipRef(runtimeNamespace, item)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", dialog.itemListContent, "TOPLEFT", 0, -topOffset)
    row:SetPoint("TOPRIGHT", dialog.itemListContent, "TOPRIGHT", 0, -topOffset)
    row.tooltipRef = tooltipRef
    row.icon:SetTexture(getDeleteDialogItemIcon(runtimeNamespace, item) or 134400)
    row.name:SetText(getDisplayItemName(runtimeNamespace, item.itemID))
    row.name:SetTextColor(getDeleteDialogItemColor(tooltipRef))
    row:Show()
    topOffset = topOffset + TAG_DELETE_ITEM_ROW_HEIGHT
  end

  for index = #(affectedItems or {}) + 1, #(dialog.itemRows or {}) do
    dialog.itemRows[index].tooltipRef = nil
    dialog.itemRows[index]:Hide()
  end

  local contentHeight = math.max(TAG_DELETE_ITEM_ROW_HEIGHT, topOffset)
  dialog.itemPanel:SetHeight(contentHeight)
  dialog.itemListContent:SetHeight(contentHeight)

  return contentHeight
end

local function hideTagDeleteDialog()
  if tagDeleteDialog then
    tagDeleteDialog:Hide()
  end
end

local function hideTagPopover()
  hideTagDeleteDialog()

  if tagPopover then
    tagPopover.activeOwner = nil
    tagPopover.activeItemData = nil
    tagPopover:Hide()
  end
end

local function populateDeleteDialog(runtimeNamespace, tagLabel, affectedItems)
  local dialog = tagDeleteDialog
  if not dialog then
    return
  end

  dialog.activeTag = tagLabel
  dialog.runtimeNamespace = runtimeNamespace
  if dialog.title then
    dialog.title:SetText(runtimeNamespace.GetText("TAG_DELETE_CONFIRMATION_TITLE"))
  end
  dialog.text:SetText(runtimeNamespace.GetText("TAG_DELETE_CONFIRMATION"))
  local contentHeight = updateDeleteDialogRows(runtimeNamespace, dialog, affectedItems)
  dialog:SetHeight(TAG_DELETE_DIALOG_BASE_HEIGHT + contentHeight)
  dialog:ClearAllPoints()
  if tagPopover and tagPopover:IsShown() then
    dialog:SetPoint("TOPLEFT", tagPopover, "TOPRIGHT", 0, 0)
  else
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
  end
  dialog:Show()
end

local function ensureTagDeleteDialog(runtimeNamespace)
  if tagDeleteDialog then
    return tagDeleteDialog
  end

  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  tagDeleteDialog = CreateFrame("Frame", "LootWishListTagDeleteDialog", UIParent, template)
  tagDeleteDialog:SetSize(TAG_DELETE_DIALOG_WIDTH, TAG_DELETE_DIALOG_HEIGHT)
  tagDeleteDialog:SetFrameStrata("DIALOG")
  tagDeleteDialog:SetToplevel(true)
  tagDeleteDialog:SetClampedToScreen(true)
  tagDeleteDialog:EnableMouse(true)

  if type(UISpecialFrames) == "table" then
    local known = false
    for _, frameName in ipairs(UISpecialFrames) do
      if frameName == "LootWishListTagDeleteDialog" then
        known = true
        break
      end
    end
    if not known then
      table.insert(UISpecialFrames, "LootWishListTagDeleteDialog")
    end
  end

  applyHistoryFrameChrome(tagDeleteDialog)

  tagDeleteDialog.title = tagDeleteDialog.historyChrome and tagDeleteDialog.historyChrome.TitleContainer and
      tagDeleteDialog.historyChrome.TitleContainer.TitleText or nil
  if tagDeleteDialog.title then
    tagDeleteDialog.title:SetText(runtimeNamespace.GetText("TAG_DELETE_CONFIRMATION_TITLE"))
  end

  tagDeleteDialog.closeButton = CreateFrame("Button", nil, tagDeleteDialog, "UIPanelCloseButtonNoScripts")
  tagDeleteDialog.closeButton:SetPoint("TOPRIGHT", tagDeleteDialog, "TOPRIGHT", 1, 0)
  tagDeleteDialog.closeButton:SetScript("OnClick", function()
    hideTagDeleteDialog()
  end)

  tagDeleteDialog.text = tagDeleteDialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  tagDeleteDialog.text:SetPoint("TOPLEFT", tagDeleteDialog, "TOPLEFT", 24, -40)
  tagDeleteDialog.text:SetPoint("TOPRIGHT", tagDeleteDialog, "TOPRIGHT", -24, -40)
  tagDeleteDialog.text:SetJustifyH("CENTER")
  tagDeleteDialog.text:SetJustifyV("TOP")

  tagDeleteDialog.itemPanel = CreateFrame("Frame", nil, tagDeleteDialog, template)
  tagDeleteDialog.itemPanel:SetPoint("TOP", tagDeleteDialog.text, "BOTTOM", 0, -14)
  tagDeleteDialog.itemPanel:SetWidth(TAG_DELETE_ITEM_CONTENT_WIDTH)
  tagDeleteDialog.itemPanel:SetHeight(TAG_DELETE_ITEM_PANEL_HEIGHT)

  tagDeleteDialog.itemListContent = CreateFrame("Frame", nil, tagDeleteDialog.itemPanel)
  tagDeleteDialog.itemListContent:SetPoint("TOP", tagDeleteDialog.itemPanel, "TOP", TAG_DELETE_ITEM_LIST_OFFSET_X, 0)
  tagDeleteDialog.itemListContent:SetWidth(TAG_DELETE_ITEM_CONTENT_WIDTH)
  tagDeleteDialog.itemListContent:SetHeight(TAG_DELETE_ITEM_PANEL_HEIGHT)
  tagDeleteDialog.itemRows = {}

  tagDeleteDialog.confirmButton = CreateFrame("Button", nil, tagDeleteDialog, "UIPanelButtonTemplate")
  tagDeleteDialog.confirmButton:SetSize(110, 22)
  tagDeleteDialog.confirmButton:SetPoint("BOTTOMRIGHT", tagDeleteDialog, "BOTTOM", -6, 18)
  tagDeleteDialog.confirmButton:SetText(runtimeNamespace.GetText("REMOVE"))
  tagDeleteDialog.confirmButton:SetScript("OnClick", function(self)
    local dialog = self:GetParent()
    if not dialog.activeTag or not dialog.runtimeNamespace then
      dialog:Hide()
      return
    end

    dialog.runtimeNamespace.DeleteWishlistTag(dialog.activeTag)
    dialog:Hide()
  end)

  tagDeleteDialog.cancelButton = CreateFrame("Button", nil, tagDeleteDialog, "UIPanelButtonTemplate")
  tagDeleteDialog.cancelButton:SetSize(110, 22)
  tagDeleteDialog.cancelButton:SetPoint("BOTTOMLEFT", tagDeleteDialog, "BOTTOM", 6, 18)
  tagDeleteDialog.cancelButton:SetText(CANCEL or "Cancel")
  tagDeleteDialog.cancelButton:SetScript("OnClick", function()
    hideTagDeleteDialog()
  end)

  tagDeleteDialog:SetScript("OnHide", function(self)
    self.activeTag = nil
    self.runtimeNamespace = nil
    if self.itemRows then
      for _, row in ipairs(self.itemRows) do
        row:Hide()
      end
    end
  end)

  tagDeleteDialog:Hide()
  return tagDeleteDialog
end

local function requestDeleteTag(runtimeNamespace, tagLabel)
  local canonicalTag, affectedItems = runtimeNamespace.PreviewDeleteWishlistTag(tagLabel)
  if not canonicalTag then
    return
  end

  if affectedItems and #affectedItems > 0 then
    ensureTagDeleteDialog(runtimeNamespace)
    populateDeleteDialog(runtimeNamespace, canonicalTag, affectedItems)
    return
  end

  runtimeNamespace.DeleteWishlistTag(canonicalTag)
end

local function ensureTagPopover(runtimeNamespace)
  if tagPopover then
    return tagPopover
  end

  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  tagPopover = CreateFrame("Frame", "LootWishListTagPopover", UIParent, template)
  tagPopover:SetFrameStrata("FULLSCREEN_DIALOG")
  tagPopover:SetToplevel(true)
  tagPopover:SetClampedToScreen(true)
  tagPopover:EnableMouse(true)

  if type(UISpecialFrames) == "table" then
    local known = false
    for _, frameName in ipairs(UISpecialFrames) do
      if frameName == "LootWishListTagPopover" then
        known = true
        break
      end
    end
    if not known then
      table.insert(UISpecialFrames, "LootWishListTagPopover")
    end
  end

  applyHistoryFrameChrome(tagPopover)

  tagPopover.title = tagPopover.historyChrome and tagPopover.historyChrome.TitleContainer and
      tagPopover.historyChrome.TitleContainer.TitleText or nil

  tagPopover.closeButton = CreateFrame("Button", nil, tagPopover, "UIPanelCloseButtonNoScripts")
  tagPopover.closeButton:SetPoint("TOPRIGHT", tagPopover, "TOPRIGHT", 1, 0)
  tagPopover.closeButton:SetScript("OnClick", function()
    hideTagPopover()
  end)

  tagPopover.rows = {}

  tagPopover.inputBox = CreateFrame("EditBox", nil, tagPopover, "InputBoxTemplate")
  tagPopover.inputBox:SetAutoFocus(false)
  tagPopover.inputBox:SetHeight(20)
  tagPopover.inputBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)

  tagPopover.inputLabel = tagPopover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tagPopover.inputLabel:SetJustifyH("LEFT")

  tagPopover.addButton = CreateFrame("Button", nil, tagPopover, "UIPanelButtonTemplate")
  tagPopover.addButton:SetHeight(20)
  tagPopover.addButton:SetWidth(68)
  tagPopover.addButton:SetScript("OnClick", function(self)
    local popover = self:GetParent()
    local runtimeNamespace = popover.runtimeNamespace
    if not runtimeNamespace then
      return
    end

    local created = runtimeNamespace.AddWishlistTag(popover.inputBox:GetText())
    if created then
      popover.inputBox:SetText("")
      popover.inputBox:ClearFocus()
    end
  end)

  tagPopover.inputBox:SetScript("OnEnterPressed", function(self)
    local parent = self:GetParent()
    if parent and parent.addButton then
      parent.addButton:Click()
    end
  end)

  tagPopover:SetScript("OnShow", function(self)
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
  end)
  tagPopover:SetScript("OnHide", function(self)
    self.activeOwner = nil
    self.activeItemData = nil
    self.runtimeNamespace = nil
    self.mouseWasDown = false
    self.pendingOutsideDismiss = false
    self.inputBox:SetText("")
    self.inputBox:ClearFocus()
  end)
  tagPopover:SetScript("OnUpdate", function(self)
    if not self.activeOwner or not self.activeOwner:IsShown() then
      hideTagPopover()
      return
    end

    if tagDeleteDialog and tagDeleteDialog:IsShown() then
      return
    end

    if type(IsMouseButtonDown) ~= "function" then
      return
    end

    local isDown = IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")
    if isDown and not self.mouseWasDown then
      self.mouseWasDown = true
      self.pendingOutsideDismiss = not (namespace.FrameUtils.IsCursorOverFrame(self) or namespace.FrameUtils.IsCursorOverFrame(self.activeOwner))
    elseif not isDown and self.mouseWasDown then
      self.mouseWasDown = false
      if self.pendingOutsideDismiss then
        hideTagPopover()
      end
    elseif not isDown then
      self.pendingOutsideDismiss = false
    end
  end)

  tagPopover:Hide()
  return tagPopover
end

local function ensureTagRow(popover, index)
  local row = popover.rows[index]
  if row then
    return row
  end

  row = CreateFrame("Frame", nil, popover)
  row:SetHeight(TAG_ROW_HEIGHT)

  row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.checkbox:SetSize(TAG_CHECKBOX_SIZE, TAG_CHECKBOX_SIZE)
  row.checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
  row.checkbox:SetScript("OnClick", function(self)
    local parentRow = self:GetParent()
    local parentPopover = parentRow and parentRow:GetParent() or nil
    local runtimeNamespace = parentPopover and parentPopover.runtimeNamespace or nil
    local itemData = parentPopover and parentPopover.activeItemData or nil
    if self.isUpdating or not runtimeNamespace or not itemData or not parentRow.tagLabel then
      return
    end

    runtimeNamespace.SetItemTagFromItemData(itemData, parentRow.tagLabel, self:GetChecked())
  end)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.label:SetPoint("LEFT", row.checkbox, "RIGHT", TAG_LABEL_GAP, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  do
    local font, size, flags = row.label:GetFont()
    if font and size then
      row.label:SetFont(font, size + TAG_LABEL_FONT_DELTA, flags)
    end
  end

  row.deleteButton = CreateFrame("Button", nil, row)
  row.deleteButton:SetSize(TAG_DELETE_BUTTON_SIZE, TAG_DELETE_BUTTON_SIZE)
  row.deleteButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  row.deleteButton:SetNormalAtlas(DELETE_NORMAL_ATLAS, false)
  row.deleteButton:SetPushedAtlas(DELETE_PRESSED_ATLAS, false)
  row.deleteButton:SetDisabledAtlas(DELETE_DISABLED_ATLAS)
  row.deleteButton:SetHighlightAtlas(DELETE_HIGHLIGHT_ATLAS)
  row.deleteButton:SetScript("OnClick", function(self)
    local parentRow = self:GetParent()
    local parentPopover = parentRow and parentRow:GetParent() or nil
    local runtimeNamespace = parentPopover and parentPopover.runtimeNamespace or nil
    if not runtimeNamespace or not parentRow.tagLabel or not self:IsEnabled() then
      return
    end

    requestDeleteTag(runtimeNamespace, parentRow.tagLabel)
  end)

  popover.rows[index] = row
  return row
end

local function refreshTagPopover(runtimeNamespace)
  local popover = ensureTagPopover(runtimeNamespace)
  if not popover or not popover.activeItemData then
    return
  end

  popover.runtimeNamespace = runtimeNamespace
  if popover.title then
    popover.title:SetText(runtimeNamespace.GetText("WISHLIST_TAGS"))
  end
  popover.addButton:SetText(runtimeNamespace.GetText("CREATE"))

  local allTags = runtimeNamespace.GetWishlistTags()
  local assignedLookup = buildAssignedLookup(runtimeNamespace.GetOrderedAssignedTags(popover.activeItemData.itemID))
  local longestTextWidth = popover.title and popover.title:GetStringWidth() or 0
  local rowTop = -POPOVER_HEADER_HEIGHT

  for index, tagLabel in ipairs(allTags) do
    local row = ensureTagRow(popover, index)
    row.tagLabel = tagLabel
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", popover, "TOPLEFT", POPOVER_PADDING, rowTop)
    row:SetPoint("TOPRIGHT", popover, "TOPRIGHT", -POPOVER_PADDING, rowTop)

    row.checkbox.isUpdating = true
    row.checkbox:SetChecked(assignedLookup[namespace.WishlistStore.normalizeTagLabel(tagLabel)] == true)
    row.checkbox.isUpdating = false

    row.label:SetText(tagLabel)
    row.deleteButton:SetEnabled(#allTags > 1)
    row:Show()

    longestTextWidth = math.max(longestTextWidth, row.label:GetStringWidth())
    rowTop = rowTop - (TAG_ROW_HEIGHT + POPOVER_ROW_GAP)
  end

  for index = #allTags + 1, #popover.rows do
    popover.rows[index]:Hide()
    popover.rows[index].tagLabel = nil
  end

  local addRowTop = rowTop - 6
  local contentWidth = math.max(POPOVER_MIN_WIDTH, math.ceil(longestTextWidth + 84))
  local addButtonWidth = popover.addButton:GetWidth()
  local targetWidth = math.max(POPOVER_MIN_WIDTH + (POPOVER_PADDING * 2), contentWidth + (POPOVER_PADDING * 2) - POPOVER_WIDTH_REDUCTION)
  local innerWidth = targetWidth - (POPOVER_PADDING * 2)

  if popover.inputLabel then
    popover.inputLabel:SetText(runtimeNamespace.GetText("CREATE_NEW_TAG"))
    popover.inputLabel:ClearAllPoints()
    popover.inputLabel:SetPoint("TOPLEFT", popover, "TOPLEFT", POPOVER_PADDING + POPOVER_ADD_INPUT_OFFSET_X, rowTop - 10)
    popover.inputLabel:Show()
  end

  local inputBoxTop = rowTop - 28
  local inputWidth = math.max(60, innerWidth - addButtonWidth - POPOVER_BUTTON_GAP - POPOVER_ADD_INPUT_OFFSET_X)

  popover.inputBox:ClearAllPoints()
  popover.inputBox:SetPoint("TOPLEFT", popover, "TOPLEFT", POPOVER_PADDING + POPOVER_ADD_INPUT_OFFSET_X, inputBoxTop)
  popover.inputBox:SetWidth(inputWidth)

  popover.addButton:ClearAllPoints()
  popover.addButton:SetPoint("LEFT", popover.inputBox, "RIGHT", POPOVER_BUTTON_GAP, 0)
  popover.addButton:SetPoint("RIGHT", popover, "RIGHT", -POPOVER_PADDING, 0)
  popover.addButton:SetWidth(addButtonWidth)

  popover:SetWidth(targetWidth)
  popover:SetHeight(math.abs(inputBoxTop - 6) + POPOVER_BOTTOM_PADDING)
end

function WishlistTagPopover.Hide()
  hideTagPopover()
end

function WishlistTagPopover.HideForOwner(ownerButton)
  if tagPopover and tagPopover.activeOwner == ownerButton then
    hideTagPopover()
  end
end

function WishlistTagPopover.IsOwnerShown(ownerButton)
  return tagPopover and tagPopover:IsShown() and tagPopover.activeOwner == ownerButton
end

function WishlistTagPopover.RefreshOwner(runtimeNamespace, ownerButton, itemData)
  if tagPopover and tagPopover:IsShown() and tagPopover.activeOwner == ownerButton then
    tagPopover.activeItemData = itemData
    refreshTagPopover(runtimeNamespace)
  end
end

function WishlistTagPopover.Toggle(runtimeNamespace, ownerButton, itemData)
  local popover = ensureTagPopover(runtimeNamespace)
  if not popover or not ownerButton or not itemData then
    return
  end

  if popover:IsShown() and popover.activeOwner == ownerButton then
    hideTagPopover()
    return
  end

  if tagDeleteDialog and tagDeleteDialog:IsShown() then
    hideTagDeleteDialog()
  end

  if popover:IsShown() then
    popover:Hide()
  end

  popover.activeOwner = ownerButton
  popover.activeItemData = itemData
  popover.runtimeNamespace = runtimeNamespace
  popover.mouseWasDown = false
  popover.pendingOutsideDismiss = false
  refreshTagPopover(runtimeNamespace)

  local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  local popoverX = (cursorX / scale) + 34

  if EncounterJournal and EncounterJournal.IsShown and EncounterJournal:IsShown() and EncounterJournal.GetRight then
    local journalRight = EncounterJournal:GetRight()
    if journalRight then
      popoverX = journalRight - 10
    end
  end

  popover:ClearAllPoints()
  popover:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", popoverX, (cursorY / scale) + 30)
  popover:Show()
end

if type(namespace) == "table" then
  namespace.WishlistTagPopover = WishlistTagPopover
end

return WishlistTagPopover
