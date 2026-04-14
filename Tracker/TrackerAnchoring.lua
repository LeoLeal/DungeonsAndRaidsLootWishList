local _, namespace = ...

local TrackerAnchoring = {}

local DEFAULT_WIDTH = 260
local TRACKER_SECTION_GAP = -10

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

  local parent = getTrackerReferenceFrame()
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
  local parent = getTrackerReferenceFrame()
  local anchorTarget = select(1, TrackerAnchoring.GetBottommostVisibleChild(parent))
  return anchorTarget ~= nil
end

function TrackerAnchoring.AnchorTrackerFrame(frame)
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

  if TrackerAnchoring.IsNativeTrackerShown() then
    local anchorTarget, _, anchorLeft = TrackerAnchoring.GetBottommostVisibleChild(parent)
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
