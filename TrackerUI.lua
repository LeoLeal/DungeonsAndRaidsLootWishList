local TrackerUI = {}

local trackerFrame = nil
local trackerTooltip = CreateFrame("GameTooltip", "LootWishListTrackerTooltip", UIParent, "GameTooltipTemplate")
local trackerContextMenu = nil
local currentGroups = {}
local knownRowKeys = {}
local knownItemStates = {}
local ns = nil
local syncTrackerFrame = nil
local hoveredTrackerRow = nil

local COLLAPSE_ATLAS = "ui-questtrackerbutton-secondary-collapse"
local EXPAND_ATLAS = "ui-questtrackerbutton-secondary-expand"
local HEADER_HEIGHT = 26
local ROW_HEIGHT = 16
local GROUP_SPACING = 5
local DEFAULT_WIDTH = 260
local TRACKER_SECTION_GAP = -10
local WISHLIST_HEADER_TOP_PADDING = 10
local CONTENT_TOP_GAP = 4
local ITEM_TEXT_PADDING = 12
local HEADER_CONTROL_GAP = 6
local STANDALONE_HEADER_OFFSET_Y = -3
local FRAME_LEFT_PADDING = 10
local STANDALONE_HEADER_BOTTOM_MARGIN = 10
local CONTEXT_MENU_WIDTH = 120
local CONTEXT_MENU_ROW_HEIGHT = 20
local CONTEXT_MENU_PADDING_X = 8
local CONTEXT_MENU_PADDING_Y = 4

local function playAddAnimation(frame)
  if frame and frame.headerFrame and frame.headerFrame.AddAnim and frame.headerFrame.AddAnim.Restart then
    frame.headerFrame.AddAnim:Restart()
  elseif type(ObjectiveTracker_PlayBlockAddedAnimation) == "function" then
    ObjectiveTracker_PlayBlockAddedAnimation(frame.headerFrame or frame)
  elseif type(UIFrameFlash) == "function" then
    UIFrameFlash(frame, 0.2, 0.3, 0.8, false, 0, 0)
  end
end

local function ensureHeaderAnimation(row)
  if not row or row.headerGlow then
    return row
  end

  row.headerGlow = row:CreateTexture(nil, "OVERLAY")
  row.headerGlow:SetAtlas("ui-questtracker-objfx-barglow")
  row.headerGlow:SetAlpha(0)
  row.headerGlow:SetSize(240, ROW_HEIGHT)
  row.headerGlow:SetPoint("TOPLEFT", row.text, "TOPLEFT", 0, 3)
  row.headerGlow:SetPoint("BOTTOMLEFT", row.text, "BOTTOMLEFT", 0, -4)

  row.headerGlow:SetTexCoord(0, 1, 0, 1)

  row.headerAddAnim = row:CreateAnimationGroup()

  local addShow = row.headerAddAnim:CreateAnimation("Alpha")
  addShow:SetChildKey("headerGlow")
  addShow:SetOrder(1)
  addShow:SetDuration(0)
  addShow:SetFromAlpha(0)
  addShow:SetToAlpha(1)

  local addFade = row.headerAddAnim:CreateAnimation("Alpha")
  addFade:SetChildKey("headerGlow")
  addFade:SetOrder(1)
  addFade:SetDuration(0.41)
  addFade:SetStartDelay(0.33)
  addFade:SetFromAlpha(1)
  addFade:SetToAlpha(0)

  local textFade = row.headerAddAnim:CreateAnimation("Alpha")
  textFade:SetChildKey("text")
  textFade:SetOrder(1)
  textFade:SetDuration(0.03)
  textFade:SetFromAlpha(0)
  textFade:SetToAlpha(1)

  row.headerCompleteAnim = row:CreateAnimationGroup()
  local completeShow = row.headerCompleteAnim:CreateAnimation("Alpha")
  completeShow:SetChildKey("headerGlow")
  completeShow:SetOrder(1)
  completeShow:SetDuration(0)
  completeShow:SetFromAlpha(0)
  completeShow:SetToAlpha(1)

  local completeFade = row.headerCompleteAnim:CreateAnimation("Alpha")
  completeFade:SetChildKey("headerGlow")
  completeFade:SetOrder(1)
  completeFade:SetDuration(0.33)
  completeFade:SetStartDelay(0.33)
  completeFade:SetFromAlpha(1)
  completeFade:SetToAlpha(0)

  local function onAnimStop()
    row.headerGlow:SetAlpha(0)
    row.text:SetAlpha(1)
  end

  row.headerAddAnim:SetScript("OnFinished", onAnimStop)
  row.headerAddAnim:SetScript("OnStop", onAnimStop)
  row.headerCompleteAnim:SetScript("OnFinished", onAnimStop)
  row.headerCompleteAnim:SetScript("OnStop", onAnimStop)

  return row
end

local function playHeaderAnimation(row, animationType)
  ensureHeaderAnimation(row)
  if not row or not row.headerGlow then
    return
  end

  row.headerAddAnim:Stop()
  row.headerCompleteAnim:Stop()
  row.headerGlow:SetAlpha(0)
  row.text:SetAlpha(1)

  if animationType == "complete" then
    row.headerCompleteAnim:Play()
  else
    row.headerAddAnim:Play()
  end
end

local function getCharacterKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Unknown"
  return string.format("%s-%s", name, realm)
end

local function getTrackerReferenceFrame()
  if ObjectiveTrackerFrame then
    if ObjectiveTrackerFrame.BlocksFrame then
      return ObjectiveTrackerFrame.BlocksFrame
    end

    if ObjectiveTrackerFrame.ContentsFrame then
      return ObjectiveTrackerFrame.ContentsFrame
    end
  end

  return ObjectiveTrackerFrame
end

local function isTrackerExplicitlyCollapsed()
  if not ObjectiveTrackerFrame then
    return false
  end

  if ObjectiveTrackerFrame.isCollapsed or ObjectiveTrackerFrame.collapsed then
    return true
  end

  if type(ObjectiveTrackerFrame.IsCollapsed) == "function" then
    return ObjectiveTrackerFrame:IsCollapsed()
  end

  return false
end

local function isNativeTrackerShown()
  if not ObjectiveTrackerFrame or not ObjectiveTrackerFrame:IsShown() or isTrackerExplicitlyCollapsed() then
    return false
  end

  local parent = getTrackerReferenceFrame()
  if parent and type(parent.IsShown) == "function" then
    return parent:IsShown()
  end

  return true
end

local function applyCollapseButtonState(button, collapsed)
  if not button then
    return
  end

  button:SetNormalAtlas(collapsed and EXPAND_ATLAS or COLLAPSE_ATLAS)
  button:SetPushedAtlas((collapsed and EXPAND_ATLAS or COLLAPSE_ATLAS) .. "-pressed")
end

local function applyStandaloneHeaderButtonState(frame)
  local button = frame and frame.topHeaderMinimizeButton or nil
  local atlases = frame and frame.topHeaderButtonAtlases or nil
  if not button or not atlases then
    return
  end

  local state = frame.lootWishlistStandaloneHidden and "collapsed" or "expanded"
  local normalAtlas = atlases[state] and atlases[state].normal or nil
  local pushedAtlas = atlases[state] and atlases[state].pushed or nil

  if normalAtlas then
    button:SetNormalAtlas(normalAtlas)
  end

  if pushedAtlas then
    button:SetPushedAtlas(pushedAtlas)
  end
end

local function playMenuCheckboxSound()
  if type(PlaySound) ~= "function" or type(SOUNDKIT) ~= "table" then
    return
  end

  if SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

local function isDescendantOf(frame, ancestor)
  while frame do
    if frame == ancestor then
      return true
    end

    if type(frame.GetParent) ~= "function" then
      break
    end

    frame = frame:GetParent()
  end

  return false
end

local function getBottommostVisibleChild(parent)
  if not parent or not parent.GetChildren then
    return nil, nil, nil
  end

  local anchorTarget = nil
  local anchorBottom = nil
  local anchorLeft = nil

  for _, child in ipairs({ parent:GetChildren() }) do
    if child and child:IsShown() and child.GetBottom then
      local bottom = child:GetBottom()
      if bottom and (anchorBottom == nil or bottom < anchorBottom) then
        anchorBottom = bottom
        anchorLeft = child.GetLeft and child:GetLeft() or nil
        anchorTarget = child
      end
    end
  end

  return anchorTarget, anchorBottom, anchorLeft
end

local function hasVisibleNativeTrackerSections()
  local parent = getTrackerReferenceFrame()
  local anchorTarget = select(1, getBottommostVisibleChild(parent))
  return anchorTarget ~= nil
end

local function anchorTrackerFrame(frame)
  local parent = getTrackerReferenceFrame()
  if not frame or not parent then
    return
  end

  local width = parent.GetWidth and parent:GetWidth() or DEFAULT_WIDTH
  if width and width > 0 then
    frame:SetWidth(width)
    if frame.headerFrame then
      frame.headerFrame:SetWidth(width)
    end
  end

  frame:ClearAllPoints()

  if isNativeTrackerShown() then
    local anchorTarget, _, anchorLeft = getBottommostVisibleChild(parent)
    if anchorTarget then
      local parentLeft = parent.GetLeft and parent:GetLeft() or nil
      local offsetX = 0
      if parentLeft and anchorLeft then
        offsetX = parentLeft - anchorLeft
      end

      frame:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", offsetX, -TRACKER_SECTION_GAP)
      return
    end
  end

  frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
end

local function ensureRow(frame, index)
  frame.rows = frame.rows or {}
  local row = frame.rows[index]
  if row then
    return row
  end

  local parent = frame.contentFrame or frame
  row = CreateFrame("Button", nil, parent)
  row:SetHeight(ROW_HEIGHT)
  row:EnableMouse(true)
  row:RegisterForClicks("LeftButtonUp")

  row.tick = row:CreateTexture(nil, "ARTWORK")
  row.tick:SetSize(ns.TrackerRowStyle.CHECK_SIZE, ns.TrackerRowStyle.CHECK_SIZE)
  row.tick:SetAtlas(ns.TrackerRowStyle.CHECK_ATLAS, false)

  row.dash = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.dash:SetText("-")
  row.dash:SetJustifyH("CENTER")
  row.dash:SetWidth(12)
  row.dash:SetTextColor(0.7, 0.7, 0.7)

  row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  row.text:SetJustifyH("LEFT")
  row.text:SetWordWrap(false)

  row.collapseButton = CreateFrame("Button", nil, row)
  row.collapseButton:SetSize(16, 16)
  row.collapseButton:SetHighlightAtlas("ui-questtrackerbutton-yellow-highlight", "ADD")
  row.collapseButton:Hide()

  frame.rows[index] = row
  return row
end

local function hideUnusedRows(frame, firstUnusedIndex)
  if not frame or not frame.rows then
    return
  end

  for index = firstUnusedIndex, #frame.rows do
    local row = frame.rows[index]
    if row.headerAddAnim then
      row.headerAddAnim:Stop()
    end
    if row.headerCompleteAnim then
      row.headerCompleteAnim:Stop()
    end
    row:Hide()
    row:SetScript("OnClick", nil)
    row:SetScript("OnMouseUp", nil)
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)
    row.collapseButton:SetScript("OnClick", nil)
    row.tooltipRef = nil
    row.itemID = nil
    row.groupKey = nil
    row.groupMode = nil
    row.instanceID = nil
    row.isBossHeader = nil
    row.tooltipFooter = nil
  end
end

local function getGroupingButtonText()
  if not ns or type(ns.GetTrackerGroupingMode) ~= "function" then
    return ""
  end

  if ns.GetTrackerGroupingMode() == "slot" then
    return ns.GetText("EQUIPMENT_SLOT")
  end

  return ns.GetText("LOOT_SOURCE")
end

local function showTrackerTooltip(row)
  if not row or row.isBossHeader or (type(row.IsShown) == "function" and not row:IsShown()) then
    return
  end

  local ref = row.tooltipRef
  local id = row.itemID
  if type(ref) ~= "string" and type(id) ~= "number" then
    return
  end

  if ns and ns.TooltipCompare and ns.TooltipCompare.hide then
    ns.TooltipCompare.hide(trackerTooltip)
  else
    trackerTooltip:Hide()
  end
  trackerTooltip:SetOwner(UIParent, "ANCHOR_NONE")
  trackerTooltip:ClearAllPoints()
  trackerTooltip:SetPoint("TOPRIGHT", row, "TOPLEFT", -4, 0)

  if type(ref) == "string" and ref:find("item:") then
    trackerTooltip:SetHyperlink(ref)
  elseif id and trackerTooltip.SetItemByID then
    trackerTooltip:SetItemByID(id)
  end

  if type(row.tooltipFooter) == "string" and row.tooltipFooter ~= "" then
    trackerTooltip:AddLine(" ")
    trackerTooltip:AddLine(row.tooltipFooter, 0.75, 0.75, 0.75, true)
  end

  trackerTooltip:Show()

  if ns and ns.TooltipCompare and ns.TooltipCompare.showComparison then
    ns.TooltipCompare.showComparison(trackerTooltip, row)
  end
end

local function hideTrackerTooltip()
  if ns and ns.TooltipCompare and ns.TooltipCompare.hide then
    ns.TooltipCompare.hide(trackerTooltip)
  else
    trackerTooltip:Hide()
  end
end

local function clearHoveredTrackerRow()
  hoveredTrackerRow = nil
end

local function setHoveredTrackerRow(row)
  hoveredTrackerRow = row
end

local function isValidHoveredItemRow(row)
  if not row or row.isBossHeader then
    return false
  end

  if type(row.IsShown) == "function" and not row:IsShown() then
    return false
  end

  return type(row.tooltipRef) == "string" or type(row.itemID) == "number"
end

local function isCursorOverFrame(frame)
  if not frame or type(frame.IsShown) ~= "function" or not frame:IsShown() then
    return false
  end

  if type(GetCursorPosition) ~= "function" then
    return false
  end

  local left = frame.GetLeft and frame:GetLeft() or nil
  local right = frame.GetRight and frame:GetRight() or nil
  local top = frame.GetTop and frame:GetTop() or nil
  local bottom = frame.GetBottom and frame:GetBottom() or nil
  if not left or not right or not top or not bottom then
    return false
  end

  local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  return cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

local function getLiveHoveredTrackerRow()
  if type(GetMouseFocus) ~= "function" or not trackerFrame or not trackerFrame.rows then
    if not trackerFrame or not trackerFrame.rows then
      return nil
    end
  end

  local focus = type(GetMouseFocus) == "function" and GetMouseFocus() or nil

  if hoveredTrackerRow and isValidHoveredItemRow(hoveredTrackerRow) then
    if focus and isDescendantOf(focus, hoveredTrackerRow) then
      return hoveredTrackerRow
    end

    if isCursorOverFrame(hoveredTrackerRow) then
      return hoveredTrackerRow
    end
  end

  for _, row in ipairs(trackerFrame.rows) do
    if isValidHoveredItemRow(row) then
      if focus and isDescendantOf(focus, row) then
        return row
      end

      if isCursorOverFrame(row) then
        return row
      end
    end
  end

  return nil
end

local function reconcileTrackerTooltip()
  local liveRow = getLiveHoveredTrackerRow()
  if not isValidHoveredItemRow(liveRow) then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    return
  end

  setHoveredTrackerRow(liveRow)
  showTrackerTooltip(liveRow)
end

local function ensureTrackerContextMenu()
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
  trackerContextMenu.actionButton.text:SetText(ns.GetText("REMOVE"))

  trackerContextMenu.actionButton:SetScript("OnEnter", function(self)
    self.highlight:Show()
  end)
  trackerContextMenu.actionButton:SetScript("OnLeave", function(self)
    self.highlight:Hide()
  end)
  trackerContextMenu.actionButton:SetScript("OnClick", function()
    local itemID = trackerContextMenu and trackerContextMenu.activeItemID or nil
    playMenuCheckboxSound()
    if trackerContextMenu then
      trackerContextMenu:Hide()
    end
    if itemID then
      ns.RemoveTrackedItem(itemID)
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
      self.pendingOutsideDismiss = not isDescendantOf(focus, self)
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

local function closeTrackerContextMenu()
  if trackerContextMenu then
    trackerContextMenu:Hide()
  end
end

local function showTrackerContextMenu(row)
  if not row or row.isBossHeader or not row.itemID then
    return
  end

  local itemID = row.itemID

  local menu = ensureTrackerContextMenu()
  if not menu then
    return
  end

  hideTrackerTooltip()
  clearHoveredTrackerRow()
  closeTrackerContextMenu()
  menu.activeOwner = row
  menu.activeItemID = itemID
  menu.actionButton.text:SetText(ns.GetText("REMOVE"))
  menu:SetWidth(math.max(CONTEXT_MENU_WIDTH, menu.actionButton.text:GetStringWidth() + (CONTEXT_MENU_PADDING_X * 2) + 24))
  menu:SetHeight(CONTEXT_MENU_ROW_HEIGHT + (CONTEXT_MENU_PADDING_Y * 2))

  local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  menu:ClearAllPoints()
  menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (cursorX / scale) + 2, (cursorY / scale) - 2)
  menu:Show()
  playMenuCheckboxSound()
end

local function getHeaderTextAnchor(frame)
  return frame and (frame.headerText or (frame.headerFrame and (frame.headerFrame.Text or frame.headerFrame.HeaderText))) or
      nil
end

local function getHeaderTextInset(frame)
  local defaultInset = 15
  if not frame then
    return defaultInset
  end

  local headerText = getHeaderTextAnchor(frame)
  if not headerText or not headerText.GetLeft or not frame.GetLeft then
    return defaultInset
  end

  local headerLeft = headerText:GetLeft()
  local frameLeft = frame:GetLeft()
  if not headerLeft or not frameLeft then
    return defaultInset
  end

  local inset = headerLeft - frameLeft
  if inset < 0 then
    return defaultInset
  end

  return inset
end

local function setWishlistCollapse(frame, collapsed)
  frame.lootWishlistCollapsed = collapsed and true or false
  if frame.headerMinimizeButton then
    applyCollapseButtonState(frame.headerMinimizeButton, frame.lootWishlistCollapsed)
  end
end

local function setStandaloneCollapse(frame, collapsed)
  collapsed = collapsed and true or false
  if frame.lootWishlistStandaloneHidden == collapsed then
    return
  end

  frame.lootWishlistStandaloneHidden = collapsed
  applyStandaloneHeaderButtonState(frame)
end

local function toggleWishlistCollapse(frame)
  if not frame then
    return
  end

  local previousState = frame.lootWishlistCollapsed == true
  setWishlistCollapse(frame, not previousState)
  if previousState ~= frame.lootWishlistCollapsed then
    playMenuCheckboxSound()
  end
  syncTrackerFrame()
end

local function toggleStandaloneCollapse(frame)
  if not frame then
    return
  end

  local previousState = frame.lootWishlistStandaloneHidden == true
  setStandaloneCollapse(frame, not previousState)
  if previousState ~= frame.lootWishlistStandaloneHidden then
    playMenuCheckboxSound()
  end
  syncTrackerFrame()
end

local function renderGroupHeader(row, group, itemCount, collapsed)
  local headerInset = getHeaderTextInset(trackerFrame)
  row:RegisterForClicks("LeftButtonUp")
  row.tick:Hide()
  row.dash:Hide()
  row.collapseButton:Show()
  row.collapseButton:ClearAllPoints()
  row.collapseButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  applyCollapseButtonState(row.collapseButton, collapsed)

  row.text:ClearAllPoints()
  row.text:SetPoint("LEFT", row, "LEFT", headerInset, 0)
  row.text:SetPoint("RIGHT", row.collapseButton, "LEFT", -4, 0)
  row.text:SetFontObject(GameFontNormal)
  local r, g, b = GameFontNormal:GetTextColor()
  row.text:SetTextColor(r, g, b)

  if collapsed and itemCount > 0 then
    row.text:SetText(string.format("%s (%d)", group.label, itemCount))
  else
    row.text:SetText(group.label)
  end

  row.groupKey = group.key
  row.groupMode = group.mode
  row.instanceID = group.instanceID
  row.isBossHeader = false
  row.tooltipRef = nil
  row.itemID = nil
  row.tooltipFooter = nil

  row:SetScript("OnClick", nil)
  row:SetScript("OnMouseUp", nil)
  row:SetScript("OnEnter", nil)
  row:SetScript("OnLeave", nil)
  row.collapseButton:SetScript("OnClick", function()
    local charKey = getCharacterKey()
    local previousState = ns.WishlistStore.isGroupCollapsed(LootWishListDB, charKey, group.mode, group.key)
    ns.WishlistStore.toggleGroupCollapse(LootWishListDB, getCharacterKey(), group.mode, group.key)
    local currentState = ns.WishlistStore.isGroupCollapsed(LootWishListDB, charKey, group.mode, group.key)
    if previousState ~= currentState then
      playMenuCheckboxSound()
    end
    TrackerUI.Refresh(ns, currentGroups)
  end)

  row:Show()
end

local function renderItemRow(row, item)
  local headerInset = getHeaderTextInset(trackerFrame)

  row.collapseButton:Hide()
  row.collapseButton:SetScript("OnClick", nil)
  row:SetScript("OnClick", nil)
  row:SetScript("OnMouseUp", nil)

  row.text:ClearAllPoints()
  row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)

  if item.isBossHeader then
    row:RegisterForClicks("LeftButtonUp")
    row.tick:Hide()
    row.dash:Hide()
    row.text:SetPoint("LEFT", row, "LEFT", headerInset, 0)
    row.text:SetFontObject(GameFontNormal)
    row.text:SetTextColor(0.65, 0.65, 0.65)
    row.text:SetText(item.displayText)
    row.isBossHeader = true
    row.tooltipRef = nil
    row.itemID = nil
    row:SetScript("OnEnter", nil)
    row:SetScript("OnLeave", nil)
    row:SetScript("OnMouseUp", nil)
  else
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if item.showTick then
      row.tick:Show()
      row.tick:ClearAllPoints()
      row.tick:SetPoint("LEFT", row, "LEFT", headerInset - 5, 0)
      row.dash:Hide()
    else
      row.tick:Hide()
      row.dash:Show()
      row.dash:ClearAllPoints()
      row.dash:SetPoint("LEFT", row, "LEFT", headerInset + 1, 0)
    end

    row.text:SetPoint("LEFT", row, "LEFT", headerInset + ITEM_TEXT_PADDING, 0)
    row.text:SetFontObject(GameFontHighlight)
    row.text:SetText(item.displayText)

    if item.displayLink and type(GetItemInfo) == "function" then
      local _, _, itemQuality = GetItemInfo(item.displayLink)
      if itemQuality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality] then
        local qc = ITEM_QUALITY_COLORS[itemQuality]
        row.text:SetTextColor(qc.r, qc.g, qc.b)
      else
        local r, g, b = GameFontHighlight:GetTextColor()
        row.text:SetTextColor(r, g, b)
      end
    else
      local r, g, b = GameFontHighlight:GetTextColor()
      row.text:SetTextColor(r, g, b)
    end

    row.isBossHeader = false
    row.itemID = item.itemID
    row.tooltipRef = item.displayLink or item.tooltipRef
    row.tooltipFooter = item.tooltipFooter
    row:SetScript("OnEnter", function(self)
      setHoveredTrackerRow(self)
      showTrackerTooltip(self)
    end)
    row:SetScript("OnLeave", function()
      clearHoveredTrackerRow()
      hideTrackerTooltip()
    end)
    row:SetScript("OnClick", function(self, button)
      if button == "LeftButton" and IsShiftKeyDown() and self.itemID then
        ns.RemoveTrackedItem(self.itemID)
      end
    end)
    row:SetScript("OnMouseUp", function(self, button)
      if button == "RightButton" then
        showTrackerContextMenu(self)
      end
    end)
  end

  row.groupKey = nil
  row.groupMode = nil
  row.instanceID = nil
  row:Show()
end

syncTrackerFrame = function()
  local frame = trackerFrame
  if not frame then
    return
  end

  closeTrackerContextMenu()

  if not currentGroups or #currentGroups == 0 then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame:Hide()
    return
  end

  if isTrackerExplicitlyCollapsed() then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame:Hide()
    return
  end

  local showStandaloneHeader = (not ObjectiveTrackerFrame or not ObjectiveTrackerFrame:IsShown()) or
      not hasVisibleNativeTrackerSections()

  anchorTrackerFrame(frame)
  frame:Show()

  if frame.topHeader then
    frame.topHeader:SetShown(showStandaloneHeader)
  end

  local headerText = frame.headerText or frame.headerFrame.Text or frame.headerFrame.HeaderText
  if headerText then
    headerText:SetText(ns.GetText("LOOT_WISHLIST"))
  end

  if frame.groupingButton and frame.groupingButton.Text then
    frame.groupingButton.Text:SetText(getGroupingButtonText())
    frame.groupingButton:SetWidth(frame.groupingButton.Text:GetStringWidth() + 12)
  end

  if frame.topHeaderText then
    frame.topHeaderText:SetText(_G.TRACKER_ALL_OBJECTIVES or "All Objectives")
  end

  frame.headerFrame:ClearAllPoints()
  if showStandaloneHeader then
    frame.headerFrame:SetPoint("TOPLEFT", frame.topHeader, "BOTTOMLEFT", 0, -STANDALONE_HEADER_BOTTOM_MARGIN)
    frame.headerFrame:SetPoint("TOPRIGHT", frame.topHeader, "BOTTOMRIGHT", 0, -STANDALONE_HEADER_BOTTOM_MARGIN)
  else
    frame.headerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -WISHLIST_HEADER_TOP_PADDING)
    frame.headerFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -WISHLIST_HEADER_TOP_PADDING)
  end

  local contentTopOffset = showStandaloneHeader and
      (math.abs(STANDALONE_HEADER_OFFSET_Y) + HEADER_HEIGHT + STANDALONE_HEADER_BOTTOM_MARGIN + HEADER_HEIGHT + CONTENT_TOP_GAP) or
      (WISHLIST_HEADER_TOP_PADDING + HEADER_HEIGHT + CONTENT_TOP_GAP)

  applyStandaloneHeaderButtonState(frame)

  if showStandaloneHeader and frame.lootWishlistStandaloneHidden then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame.headerFrame:Hide()
    if frame.contentFrame then
      frame.contentFrame:Hide()
      frame.contentFrame:SetHeight(0)
    end
    hideUnusedRows(frame, 1)
    frame:SetHeight(math.abs(STANDALONE_HEADER_OFFSET_Y) + HEADER_HEIGHT)
    return
  end

  frame.headerFrame:Show()
  if frame.contentFrame then
    frame.contentFrame:ClearAllPoints()
    frame.contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", FRAME_LEFT_PADDING, -contentTopOffset)
    frame.contentFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -contentTopOffset)
  end

  if frame.lootWishlistCollapsed then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    if frame.contentFrame then
      frame.contentFrame:Hide()
      frame.contentFrame:SetHeight(0)
    end
    hideUnusedRows(frame, 1)
    frame:SetHeight(contentTopOffset)
    return
  end

  if frame.contentFrame then
    frame.contentFrame:Show()
  end

  local rowIndex = 1
  local yOffset = 0
  local allKeys = {}
  local addedNewItem = false
  local groupAnimations = {}
  local db = LootWishListDB
  local charKey = getCharacterKey()

  for groupIndex, group in ipairs(currentGroups) do
    local itemCount = 0
    for _, item in ipairs(group.items) do
      if not item.isBossHeader then
        itemCount = itemCount + 1
        local uniqueKey = tostring(group.key) .. ":" .. tostring(item.itemID)
        allKeys[uniqueKey] = true
        if not knownRowKeys[uniqueKey] then
          knownRowKeys[uniqueKey] = true
          addedNewItem = true
          groupAnimations[group.key] = groupAnimations[group.key] or "add"
        end

        local previousState = knownItemStates[uniqueKey]
        if previousState and not previousState.showTick and item.showTick then
          if groupAnimations[group.key] ~= "add" then
            groupAnimations[group.key] = "complete"
          end
        end

        knownItemStates[uniqueKey] = {
          showTick = item.showTick == true,
        }
      end
    end

    local collapsed = ns.WishlistStore.isGroupCollapsed(db, charKey, group.mode, group.key)
    local headerRow = ensureRow(frame, rowIndex)
    headerRow:ClearAllPoints()
    headerRow:SetPoint("TOPLEFT", frame.contentFrame or frame, "TOPLEFT", 0, yOffset)
    headerRow:SetPoint("TOPRIGHT", frame.contentFrame or frame, "TOPRIGHT", 0, yOffset)
    renderGroupHeader(headerRow, group, itemCount, collapsed)
    if groupAnimations[group.key] then
      playHeaderAnimation(headerRow, groupAnimations[group.key])
    end
    yOffset = yOffset - ROW_HEIGHT
    rowIndex = rowIndex + 1

    if not collapsed then
      for _, item in ipairs(group.items) do
        local itemRow = ensureRow(frame, rowIndex)
        itemRow:ClearAllPoints()
        itemRow:SetPoint("TOPLEFT", frame.contentFrame or frame, "TOPLEFT", 0, yOffset)
        itemRow:SetPoint("TOPRIGHT", frame.contentFrame or frame, "TOPRIGHT", 0, yOffset)
        renderItemRow(itemRow, item)

        yOffset = yOffset - ROW_HEIGHT
        rowIndex = rowIndex + 1
      end
    end

    if groupIndex < #currentGroups then
      yOffset = yOffset - GROUP_SPACING
    end
  end

  for knownKey in pairs(knownRowKeys) do
    if not allKeys[knownKey] then
      knownRowKeys[knownKey] = nil
      knownItemStates[knownKey] = nil
    end
  end

  hideUnusedRows(frame, rowIndex)
  local contentHeight = math.max(0, -yOffset)
  if frame.contentFrame then
    frame.contentFrame:SetHeight(contentHeight)
  end

  frame:SetHeight(contentTopOffset + contentHeight + CONTENT_TOP_GAP)

  if addedNewItem then
    playAddAnimation(frame)
  end

  reconcileTrackerTooltip()
end

local function hookTrackerState()
  if not ObjectiveTrackerFrame or trackerFrame == nil then
    return
  end

  if trackerFrame.trackerHooksInstalled then
    return
  end

  trackerFrame.trackerHooksInstalled = true

  if type(ObjectiveTrackerFrame.Update) == "function" then
    hooksecurefunc(ObjectiveTrackerFrame, "Update", function()
      syncTrackerFrame()
    end)
  elseif type(ObjectiveTracker_Update) == "function" then
    hooksecurefunc("ObjectiveTracker_Update", function()
      syncTrackerFrame()
    end)
  end

  ObjectiveTrackerFrame:HookScript("OnShow", function()
    syncTrackerFrame()
  end)
  ObjectiveTrackerFrame:HookScript("OnHide", function()
    syncTrackerFrame()
  end)

  if ObjectiveTrackerFrame.BlocksFrame and ObjectiveTrackerFrame.BlocksFrame.HookScript then
    ObjectiveTrackerFrame.BlocksFrame:HookScript("OnShow", function()
      syncTrackerFrame()
    end)
    ObjectiveTrackerFrame.BlocksFrame:HookScript("OnHide", function()
      syncTrackerFrame()
    end)
  end

  if ObjectiveTrackerFrame.ContentsFrame and ObjectiveTrackerFrame.ContentsFrame.HookScript then
    ObjectiveTrackerFrame.ContentsFrame:HookScript("OnShow", function()
      syncTrackerFrame()
    end)
    ObjectiveTrackerFrame.ContentsFrame:HookScript("OnHide", function()
      syncTrackerFrame()
    end)
  end

  if type(ObjectiveTrackerFrame.SetCollapsed) == "function" then
    hooksecurefunc(ObjectiveTrackerFrame, "SetCollapsed", function()
      syncTrackerFrame()
    end)
  end

  local header = ObjectiveTrackerFrame.Header
  if header then
    local minBtn = header.MinimizeButton or header.CollapseButton
    if minBtn and minBtn.HookScript then
      minBtn:HookScript("OnClick", function()
        syncTrackerFrame()
      end)
    end
  end
end

function TrackerUI.Initialize(namespace)
  if trackerFrame then
    return
  end

  ns = namespace

  trackerFrame = CreateFrame("Frame", "LootWishListTrackerFrame", UIParent)
  trackerFrame:SetWidth(DEFAULT_WIDTH)
  trackerFrame:SetHeight(HEADER_HEIGHT)
  trackerFrame:SetFrameStrata("LOW")
  trackerFrame.lootWishlistCollapsed = false
  trackerFrame.lootWishlistStandaloneHidden = false

  trackerFrame.topHeader = CreateFrame("Frame", nil, trackerFrame, "ObjectiveTrackerContainerHeaderTemplate")
  trackerFrame.topHeader:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 0, STANDALONE_HEADER_OFFSET_Y)
  trackerFrame.topHeader:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", 0, STANDALONE_HEADER_OFFSET_Y)
  trackerFrame.topHeader:SetHeight(HEADER_HEIGHT)
  trackerFrame.topHeaderText = trackerFrame.topHeader.Text or trackerFrame.topHeader.HeaderText
  trackerFrame.topHeaderMinimizeButton = trackerFrame.topHeader.MinimizeButton or trackerFrame.topHeader.CollapseButton
  trackerFrame.topHeaderButtonAtlases = nil

  trackerFrame.headerFrame = CreateFrame("Frame", nil, trackerFrame, "ObjectiveTrackerModuleHeaderTemplate")
  trackerFrame.headerFrame:SetHeight(HEADER_HEIGHT)

  trackerFrame.headerText = trackerFrame.headerFrame.Text or trackerFrame.headerFrame.HeaderText
  trackerFrame.headerMinimizeButton = trackerFrame.headerFrame.MinimizeButton
  trackerFrame.groupingButton = CreateFrame("Button", nil, trackerFrame.headerFrame)
  trackerFrame.groupingButton:SetHeight(16)
  trackerFrame.groupingButton.Text = trackerFrame.groupingButton:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  trackerFrame.groupingButton.Text:SetPoint("CENTER")
  trackerFrame.groupingButton.Text:SetText(getGroupingButtonText())
  trackerFrame.groupingButton:SetScript("OnClick", function()
    local nextMode = ns.GetTrackerGroupingMode() == "slot" and "source" or "slot"
    ns.SetTrackerGroupingMode(nextMode)
  end)
  trackerFrame.groupingButton:SetScript("OnEnter", function(self)
    self.Text:SetFontObject(GameFontNormalSmall)
  end)
  trackerFrame.groupingButton:SetScript("OnLeave", function(self)
    self.Text:SetFontObject(GameFontHighlightSmall)
  end)
  trackerFrame.contentFrame = CreateFrame("Frame", nil, trackerFrame)

  if trackerFrame.groupingButton and trackerFrame.groupingButton.Text then
    trackerFrame.groupingButton:SetWidth(trackerFrame.groupingButton.Text:GetStringWidth() + 12)
    trackerFrame.groupingButton:ClearAllPoints()
    if trackerFrame.headerMinimizeButton then
      trackerFrame.groupingButton:SetPoint("RIGHT", trackerFrame.headerMinimizeButton, "LEFT", -HEADER_CONTROL_GAP, 0)
    else
      trackerFrame.groupingButton:SetPoint("RIGHT", trackerFrame.headerFrame, "RIGHT", -4, 0)
    end
  end

  if trackerFrame.topHeader and trackerFrame.topHeader.SetCollapsed and trackerFrame.topHeaderMinimizeButton and
      trackerFrame.topHeaderMinimizeButton.GetNormalTexture and trackerFrame.topHeaderMinimizeButton.GetPushedTexture then
    local normalTexture = trackerFrame.topHeaderMinimizeButton:GetNormalTexture()
    local pushedTexture = trackerFrame.topHeaderMinimizeButton:GetPushedTexture()
    if normalTexture and pushedTexture and normalTexture.GetAtlas and pushedTexture.GetAtlas then
      trackerFrame.topHeader:SetCollapsed(false)
      trackerFrame.topHeaderButtonAtlases = {
        expanded = {
          normal = normalTexture:GetAtlas(),
          pushed = pushedTexture:GetAtlas(),
        },
        collapsed = {},
      }

      trackerFrame.topHeader:SetCollapsed(true)
      trackerFrame.topHeaderButtonAtlases.collapsed.normal = normalTexture:GetAtlas()
      trackerFrame.topHeaderButtonAtlases.collapsed.pushed = pushedTexture:GetAtlas()

      trackerFrame.topHeader:SetCollapsed(false)
      trackerFrame.lootWishlistStandaloneHidden = false
      applyStandaloneHeaderButtonState(trackerFrame)
    end
  end

  trackerFrame.topHeaderButton = CreateFrame("Button", nil, trackerFrame.topHeader)
  trackerFrame.topHeaderButton:SetPoint("TOPLEFT", trackerFrame.topHeader, "TOPLEFT", 0, 0)
  trackerFrame.topHeaderButton:SetPoint("BOTTOMLEFT", trackerFrame.topHeader, "BOTTOMLEFT", 0, 0)
  if trackerFrame.topHeaderMinimizeButton then
    trackerFrame.topHeaderButton:SetPoint("RIGHT", trackerFrame.topHeaderMinimizeButton, "LEFT", 0, 0)
  else
    trackerFrame.topHeaderButton:SetPoint("TOPRIGHT", trackerFrame.topHeader, "TOPRIGHT", 0, 0)
    trackerFrame.topHeaderButton:SetPoint("BOTTOMRIGHT", trackerFrame.topHeader, "BOTTOMRIGHT", 0, 0)
  end
  trackerFrame.topHeaderButton:RegisterForClicks("LeftButtonUp")
  trackerFrame.topHeaderButton:SetScript("OnClick", function()
    toggleStandaloneCollapse(trackerFrame)
  end)

  if trackerFrame.topHeaderMinimizeButton then
    trackerFrame.topHeaderMinimizeButton:SetScript("OnClick", function()
      toggleStandaloneCollapse(trackerFrame)
    end)
  end

  trackerFrame.headerButton = CreateFrame("Button", nil, trackerFrame.headerFrame)
  trackerFrame.headerButton:SetPoint("TOPLEFT", trackerFrame.headerFrame, "TOPLEFT", 0, 0)
  trackerFrame.headerButton:SetPoint("BOTTOMLEFT", trackerFrame.headerFrame, "BOTTOMLEFT", 0, 0)
  if trackerFrame.groupingButton then
    trackerFrame.headerButton:SetPoint("RIGHT", trackerFrame.groupingButton, "LEFT", -HEADER_CONTROL_GAP, 0)
  elseif trackerFrame.headerMinimizeButton then
    trackerFrame.headerButton:SetPoint("RIGHT", trackerFrame.headerMinimizeButton, "LEFT", 0, 0)
  else
    trackerFrame.headerButton:SetPoint("TOPRIGHT", trackerFrame.headerFrame, "TOPRIGHT", 0, 0)
    trackerFrame.headerButton:SetPoint("BOTTOMRIGHT", trackerFrame.headerFrame, "BOTTOMRIGHT", 0, 0)
  end
  trackerFrame.headerButton:RegisterForClicks("LeftButtonUp")
  trackerFrame.headerButton:SetScript("OnClick", function()
    toggleWishlistCollapse(trackerFrame)
  end)

  if trackerFrame.headerMinimizeButton then
    trackerFrame.headerMinimizeButton:SetScript("OnClick", function()
      toggleWishlistCollapse(trackerFrame)
    end)
    applyCollapseButtonState(trackerFrame.headerMinimizeButton, false)
  end

  namespace.trackerFrame = trackerFrame
  hookTrackerState()
  syncTrackerFrame()
end

function TrackerUI.Refresh(namespace, groups)
  if not trackerFrame then
    TrackerUI.Initialize(namespace)
  end

  if not trackerFrame then
    return
  end

  currentGroups = groups or {}
  syncTrackerFrame()
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TrackerUI = TrackerUI
end

return TrackerUI
