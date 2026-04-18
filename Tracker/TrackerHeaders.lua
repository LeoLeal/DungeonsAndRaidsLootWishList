local _, namespace = ...

local TrackerHeaders = {}

local COLLAPSE_ATLAS = "ui-questtrackerbutton-secondary-collapse"
local EXPAND_ATLAS = "ui-questtrackerbutton-secondary-expand"
local ATTACH_BUTTON_SIZE = 18
local FILTER_BUTTON_SIZE = 18
local LOCK_BUTTON_SIZE = 18
local HEADER_TITLE_INSET = 10
local DETACHED_HEADER_TITLE_OFFSET = -3
local HEADER_RIGHT_PADDING = 0
local HEADER_CONTROL_GAP = 6

local ATTACHMENT_BUTTON_ATLASES = {
  attached = {
    normal = "RedButton-Expand",
    pushed = "RedButton-Expand-Pressed",
  },
  detached = {
    normal = "RedButton-Condense",
    pushed = "RedButton-Condense-Pressed",
  },
}

local LOCK_BUTTON_ATLAS = "AdventureMapIcon-Lock"
local LOCKED_VERTEX_COLOR = { 1, 1, 1 }
local UNLOCKED_VERTEX_COLOR = { 0.45, 0.45, 0.45 }

local function getVisibleWidth(region, fallback)
  if region and region.GetWidth then
    local width = region:GetWidth()
    if width and width > 0 then
      return width
    end
  end

  return fallback or 0
end

local function setTextButtonState(button, text)
  if not button or not button.Text then
    return
  end

  button.Text:SetText(text or "")
  button:SetWidth(button.Text:GetStringWidth() + 12)
end

function TrackerHeaders.PlayMenuCheckboxSound()
  if type(PlaySound) ~= "function" or type(SOUNDKIT) ~= "table" then
    return
  end

  if SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

function TrackerHeaders.ApplyCollapseButtonState(button, collapsed)
  if not button then
    return
  end

  button:SetNormalAtlas(collapsed and EXPAND_ATLAS or COLLAPSE_ATLAS)
  button:SetPushedAtlas((collapsed and EXPAND_ATLAS or COLLAPSE_ATLAS) .. "-pressed")
end

function TrackerHeaders.ApplyStandaloneHeaderButtonState(frame)
  TrackerHeaders.ApplyTopHeaderButtonState(frame, frame and frame.lootWishlistStandaloneHidden == true)
end

function TrackerHeaders.ApplyTopHeaderButtonState(frame, collapsed)
  local button = frame and frame.topHeaderMinimizeButton or nil
  local atlases = frame and frame.topHeaderButtonAtlases or nil
  if not button then
    return
  end

  if not atlases then
    TrackerHeaders.ApplyCollapseButtonState(button, collapsed)
    return
  end

  local state = collapsed and "collapsed" or "expanded"
  local normalAtlas = atlases[state] and atlases[state].normal or nil
  local pushedAtlas = atlases[state] and atlases[state].pushed or nil

  if normalAtlas then
    button:SetNormalAtlas(normalAtlas)
  end

  if pushedAtlas then
    button:SetPushedAtlas(pushedAtlas)
  end
end

function TrackerHeaders.GetGroupingButtonText(runtimeNamespace)
  if not runtimeNamespace or type(runtimeNamespace.GetTrackerGroupingMode) ~= "function" then
    return ""
  end

  if runtimeNamespace.GetTrackerGroupingMode() == "slot" then
    return runtimeNamespace.GetText("EQUIPMENT_SLOT")
  end

  return runtimeNamespace.GetText("LOOT_SOURCE")
end

function TrackerHeaders.ApplyAttachmentButtonState(button, detached)
  if not button then
    return
  end

  local atlasSet = ATTACHMENT_BUTTON_ATLASES[detached and "detached" or "attached"]
  button:SetSize(ATTACH_BUTTON_SIZE, ATTACH_BUTTON_SIZE)
  button:SetNormalAtlas(atlasSet.normal)
  button:SetPushedAtlas(atlasSet.pushed)
end

function TrackerHeaders.ApplyFilterButtonState(runtimeNamespace, button)
  if not button then
    return
  end

  button:SetSize(FILTER_BUTTON_SIZE, FILTER_BUTTON_SIZE)
  if runtimeNamespace and runtimeNamespace.TrackerFilterMenu then
    runtimeNamespace.TrackerFilterMenu.ApplyButtonState(runtimeNamespace, button)
  end
end

function TrackerHeaders.ApplyLockButtonState(button, locked)
  if not button then
    return
  end

  button:SetSize(LOCK_BUTTON_SIZE, LOCK_BUTTON_SIZE)
  button:SetNormalAtlas(LOCK_BUTTON_ATLAS)
  button:SetPushedAtlas(LOCK_BUTTON_ATLAS)

  local normalTexture = button.GetNormalTexture and button:GetNormalTexture() or nil
  local pushedTexture = button.GetPushedTexture and button:GetPushedTexture() or nil
  local color = locked and LOCKED_VERTEX_COLOR or UNLOCKED_VERTEX_COLOR
  if normalTexture and normalTexture.SetVertexColor then
    normalTexture:SetVertexColor(color[1], color[2], color[3])
  end
  if pushedTexture and pushedTexture.SetVertexColor then
    pushedTexture:SetVertexColor(color[1], color[2], color[3])
  end
end

function TrackerHeaders.GetHeaderTextAnchor(frame)
  if frame and frame.useTopHeaderTextInset and frame.topHeaderText then
    return frame.topHeaderText
  end

  return frame and (frame.headerText or (frame.headerFrame and (frame.headerFrame.Text or frame.headerFrame.HeaderText))) or nil
end

function TrackerHeaders.GetHeaderTextInset(frame)
  local defaultInset = 15
  if not frame then
    return defaultInset
  end

  local headerText = TrackerHeaders.GetHeaderTextAnchor(frame)
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

function TrackerHeaders.SetWishlistCollapse(frame, collapsed)
  frame.lootWishlistCollapsed = collapsed and true or false
  if frame.headerMinimizeButton then
    TrackerHeaders.ApplyCollapseButtonState(frame.headerMinimizeButton, frame.lootWishlistCollapsed)
  end
end

function TrackerHeaders.SetStandaloneCollapse(frame, collapsed)
  collapsed = collapsed and true or false
  if frame.lootWishlistStandaloneHidden == collapsed then
    return
  end

  frame.lootWishlistStandaloneHidden = collapsed
  TrackerHeaders.ApplyStandaloneHeaderButtonState(frame)
end

function TrackerHeaders.ToggleWishlistCollapse(frame, onAfterToggle)
  if not frame then
    return
  end

  local previousState = frame.lootWishlistCollapsed == true
  TrackerHeaders.SetWishlistCollapse(frame, not previousState)
  if previousState ~= frame.lootWishlistCollapsed then
    TrackerHeaders.PlayMenuCheckboxSound()
  end
  onAfterToggle()
end

function TrackerHeaders.ToggleStandaloneCollapse(frame, onAfterToggle)
  if not frame then
    return
  end

  local previousState = frame.lootWishlistStandaloneHidden == true
  TrackerHeaders.SetStandaloneCollapse(frame, not previousState)
  if previousState ~= frame.lootWishlistStandaloneHidden then
    TrackerHeaders.PlayMenuCheckboxSound()
  end
  onAfterToggle()
end

function TrackerHeaders.LayoutHeaderControls(frame, runtimeNamespace, options)
  if not frame or not options then
    return
  end

  local header = options.header
  local headerText = options.headerText
  local collapseButton = options.collapseButton
  local clickButton = options.clickButton
  local showAttachButton = options.showAttachButton == true
  local showFilterButton = options.showFilterButton == true
  local showGroupingButton = options.showGroupingButton == true
  local showLockButton = options.showLockButton == true
  local detached = options.detached == true
  local titleInset = HEADER_TITLE_INSET + (detached and DETACHED_HEADER_TITLE_OFFSET or 0)
  if not header or not headerText or not collapseButton then
    return
  end

  local attachButton = frame.attachDetachButton
  local filterButton = frame.filterButton
  local groupingButton = frame.groupingButton
  local lockButton = frame.lockButton

  TrackerHeaders.ApplyAttachmentButtonState(attachButton, detached)
  attachButton:SetShown(showAttachButton)

  TrackerHeaders.ApplyFilterButtonState(runtimeNamespace, filterButton)
  filterButton:SetShown(showFilterButton)

  setTextButtonState(groupingButton, TrackerHeaders.GetGroupingButtonText(runtimeNamespace))
  groupingButton:SetShown(showGroupingButton)

  local detachedLocked = runtimeNamespace and type(runtimeNamespace.IsTrackerDetachedLocked) == "function" and
      runtimeNamespace.IsTrackerDetachedLocked() or false
  TrackerHeaders.ApplyLockButtonState(lockButton, detachedLocked)
  lockButton:SetShown(showLockButton)

  collapseButton:ClearAllPoints()
  collapseButton:SetPoint("RIGHT", header, "RIGHT", -HEADER_RIGHT_PADDING, 0)

  local leftmostControl = collapseButton
  local rightTarget = collapseButton

  if showAttachButton then
    attachButton:ClearAllPoints()
    attachButton:SetPoint("RIGHT", rightTarget, "LEFT", -HEADER_CONTROL_GAP, 0)
    rightTarget = attachButton
    leftmostControl = attachButton
  end

  if showFilterButton then
    filterButton:ClearAllPoints()
    filterButton:SetPoint("RIGHT", rightTarget, "LEFT", -HEADER_CONTROL_GAP, 0)
    rightTarget = filterButton
    leftmostControl = filterButton
  end

  if showGroupingButton then
    groupingButton:ClearAllPoints()
    groupingButton:SetPoint("RIGHT", rightTarget, "LEFT", -HEADER_CONTROL_GAP, 0)
    rightTarget = groupingButton
    leftmostControl = groupingButton
  end

  if showLockButton then
    lockButton:ClearAllPoints()
    lockButton:SetPoint("RIGHT", rightTarget, "LEFT", -HEADER_CONTROL_GAP, 0)
    rightTarget = lockButton
    leftmostControl = lockButton
  end

  headerText:ClearAllPoints()
  headerText:SetPoint("LEFT", header, "LEFT", titleInset, 0)
  if leftmostControl then
    headerText:SetPoint("RIGHT", leftmostControl, "LEFT", -4, 0)
  else
    headerText:SetPoint("RIGHT", header, "RIGHT", -HEADER_RIGHT_PADDING, 0)
  end

  if clickButton then
    clickButton:ClearAllPoints()
    clickButton:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    clickButton:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    local clickRightTarget = leftmostControl or collapseButton
    clickButton:SetPoint("RIGHT", clickRightTarget, "LEFT", -4, 0)
  end
end

if type(namespace) == "table" then
  namespace.TrackerHeaders = TrackerHeaders
end

return TrackerHeaders
