local _, namespace = ...

local TrackerFrame = {}

local DEFAULT_WIDTH = 260
local HEADER_HEIGHT = 26
local HEADER_CONTROL_GAP = 6
local STANDALONE_HEADER_OFFSET_Y = -3

function TrackerFrame.Create(runtimeNamespace, callbacks)
  local trackerFrame = CreateFrame("Frame", "LootWishListTrackerFrame", UIParent)
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
  trackerFrame.groupingButton.Text:SetText(runtimeNamespace.TrackerHeaders.GetGroupingButtonText(runtimeNamespace))
  trackerFrame.groupingButton:SetScript("OnClick", callbacks.onToggleGrouping)
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
      runtimeNamespace.TrackerHeaders.ApplyStandaloneHeaderButtonState(trackerFrame)
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
  trackerFrame.topHeaderButton:SetScript("OnClick", callbacks.onToggleStandalone)

  if trackerFrame.topHeaderMinimizeButton then
    trackerFrame.topHeaderMinimizeButton:SetScript("OnClick", callbacks.onToggleStandalone)
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
  trackerFrame.headerButton:SetScript("OnClick", callbacks.onToggleWishlist)

  if trackerFrame.headerMinimizeButton then
    trackerFrame.headerMinimizeButton:SetScript("OnClick", callbacks.onToggleWishlist)
    runtimeNamespace.TrackerHeaders.ApplyCollapseButtonState(trackerFrame.headerMinimizeButton, false)
  end

  return trackerFrame
end

if type(namespace) == "table" then
  namespace.TrackerFrame = TrackerFrame
end

return TrackerFrame
