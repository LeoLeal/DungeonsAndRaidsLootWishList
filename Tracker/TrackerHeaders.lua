local _, namespace = ...

local TrackerHeaders = {}

local COLLAPSE_ATLAS = "ui-questtrackerbutton-secondary-collapse"
local EXPAND_ATLAS = "ui-questtrackerbutton-secondary-expand"

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

function TrackerHeaders.GetGroupingButtonText(runtimeNamespace)
  if not runtimeNamespace or type(runtimeNamespace.GetTrackerGroupingMode) ~= "function" then
    return ""
  end

  if runtimeNamespace.GetTrackerGroupingMode() == "slot" then
    return runtimeNamespace.GetText("EQUIPMENT_SLOT")
  end

  return runtimeNamespace.GetText("LOOT_SOURCE")
end

function TrackerHeaders.GetHeaderTextAnchor(frame)
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

if type(namespace) == "table" then
  namespace.TrackerHeaders = TrackerHeaders
end

return TrackerHeaders
