local _, namespace = ...

local TrackerAnchoring = {}

local DEFAULT_WIDTH = 260
local TRACKER_SECTION_GAP = -10

local function isTrackerInDefaultPosition()
  return ObjectiveTrackerFrame and type(ObjectiveTrackerFrame.IsInDefaultPosition) == "function" and
      ObjectiveTrackerFrame:IsInDefaultPosition()
end

local function getNativeTrackerReferenceFrame()
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

local function getStandaloneTrackerReferenceFrame()
  if isTrackerInDefaultPosition() and UIParentRightManagedFrameContainer then
    return UIParentRightManagedFrameContainer
  end

  return ObjectiveTrackerFrame
end

local function getReferenceWidth(...)
  for index = 1, select("#", ...) do
    local frame = select(index, ...)
    local width = frame and frame.GetWidth and frame:GetWidth() or nil
    if width and width > 0 then
      return width
    end
  end

  return DEFAULT_WIDTH
end

local function getStandaloneReferenceWidth(standaloneParent, nativeParent)
  if ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header and ObjectiveTrackerFrame.Header.GetWidth then
    local headerWidth = ObjectiveTrackerFrame.Header:GetWidth()
    if headerWidth and headerWidth > 0 then
      return headerWidth
    end
  end

  return getReferenceWidth(ObjectiveTrackerFrame, standaloneParent, nativeParent)
end

local function getRelativeTopRightOffset(frame, relativeTo)
  if not frame or not relativeTo then
    return 0, 0
  end

  local frameRight = frame.GetRight and frame:GetRight() or nil
  local frameTop = frame.GetTop and frame:GetTop() or nil
  local relativeRight = relativeTo.GetRight and relativeTo:GetRight() or nil
  local relativeTop = relativeTo.GetTop and relativeTo:GetTop() or nil

  if not frameRight or not frameTop or not relativeRight or not relativeTop then
    return 0, 0
  end

  return frameRight - relativeRight, frameTop - relativeTop
end

function TrackerAnchoring.IsTrackerExplicitlyCollapsed()
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

function TrackerAnchoring.IsNativeTrackerShown()
  if not ObjectiveTrackerFrame or not ObjectiveTrackerFrame:IsShown() or TrackerAnchoring.IsTrackerExplicitlyCollapsed() then
    return false
  end

  local parent = getNativeTrackerReferenceFrame()
  if parent and type(parent.IsShown) == "function" then
    return parent:IsShown()
  end

  return true
end

function TrackerAnchoring.GetBottommostVisibleChild(parent)
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

function TrackerAnchoring.HasVisibleNativeTrackerSections()
  local parent = getNativeTrackerReferenceFrame()
  local anchorTarget = select(1, TrackerAnchoring.GetBottommostVisibleChild(parent))
  return anchorTarget ~= nil
end

function TrackerAnchoring.GetAnchorMode()
  if TrackerAnchoring.IsNativeTrackerShown() and TrackerAnchoring.HasVisibleNativeTrackerSections() then
    return "append"
  end

  return "standalone"
end

function TrackerAnchoring.AnchorTrackerFrame(frame)
  local nativeParent = getNativeTrackerReferenceFrame()
  local standaloneParent = getStandaloneTrackerReferenceFrame()
  if not frame or (not nativeParent and not standaloneParent) then
    return
  end

  local anchorMode = TrackerAnchoring.GetAnchorMode()
  local width = nil
  if anchorMode == "standalone" then
    width = getStandaloneReferenceWidth(standaloneParent, nativeParent)
  else
    width = getReferenceWidth(nativeParent, standaloneParent)
  end

  if width and width > 0 then
    frame:SetWidth(width)
    if frame.headerFrame then
      frame.headerFrame:SetWidth(width)
    end
  end

  frame:ClearAllPoints()

  if anchorMode == "append" and nativeParent then
    local anchorTarget, _, anchorLeft = TrackerAnchoring.GetBottommostVisibleChild(nativeParent)
    if anchorTarget then
      local parentLeft = nativeParent.GetLeft and nativeParent:GetLeft() or nil
      local offsetX = 0
      if parentLeft and anchorLeft then
        offsetX = parentLeft - anchorLeft
      end

      frame:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", offsetX, -TRACKER_SECTION_GAP)
      return
    end
  end

  if standaloneParent then
    if isTrackerInDefaultPosition() and standaloneParent == UIParentRightManagedFrameContainer then
      local offsetX, offsetY = getRelativeTopRightOffset(ObjectiveTrackerFrame, standaloneParent)
      frame:SetPoint("TOPRIGHT", standaloneParent, "TOPRIGHT", offsetX, offsetY)
    else
      frame:SetPoint("TOPLEFT", standaloneParent, "TOPLEFT", 0, 0)
      if ObjectiveTrackerFrame then
        frame:SetPoint("TOPRIGHT", ObjectiveTrackerFrame, "TOPRIGHT", 0, 0)
      end
    end
    return
  end

  frame:SetPoint("TOPLEFT", nativeParent, "TOPLEFT", 0, 0)
end

function TrackerAnchoring.HookTrackerState(trackerFrame, syncTrackerFrame)
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

  if type(UIParent_ManageFramePositions) == "function" then
    hooksecurefunc("UIParent_ManageFramePositions", function()
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

if type(namespace) == "table" then
  namespace.TrackerAnchoring = TrackerAnchoring
end

return TrackerAnchoring
