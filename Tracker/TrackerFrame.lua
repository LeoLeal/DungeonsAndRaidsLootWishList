local _, namespace = ...

local TrackerFrame = {}

local DEFAULT_WIDTH = 260
local HEADER_HEIGHT = 26
local STANDALONE_HEADER_OFFSET_Y = -3
local LOCK_BUTTON_SIZE = 18
local FILTER_BUTTON_SIZE = 18

local function createTextButton(parent, onClick)
  local button = CreateFrame("Button", nil, parent)
  button:SetHeight(16)
  button.Text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  button.Text:SetPoint("CENTER")
  button:SetScript("OnClick", onClick)
  button:SetScript("OnEnter", function(self)
    self.Text:SetFontObject(GameFontNormalSmall)
  end)
  button:SetScript("OnLeave", function(self)
    self.Text:SetFontObject(GameFontHighlightSmall)
  end)
  return button
end

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

  trackerFrame.groupingButton = createTextButton(trackerFrame, callbacks.onToggleGrouping)
  trackerFrame.groupingButton.Text:SetText(runtimeNamespace.TrackerHeaders.GetGroupingButtonText(runtimeNamespace))
  trackerFrame.groupingButton:SetWidth(trackerFrame.groupingButton.Text:GetStringWidth() + 12)

  trackerFrame.lockButton = CreateFrame("Button", nil, trackerFrame)
  trackerFrame.lockButton:SetScript("OnClick", callbacks.onToggleDetachedLock)
  trackerFrame.lockButton:SetSize(LOCK_BUTTON_SIZE, LOCK_BUTTON_SIZE)
  trackerFrame.lockButton:Hide()

  trackerFrame.attachDetachButton = CreateFrame("Button", nil, trackerFrame)
  trackerFrame.attachDetachButton:SetScript("OnClick", callbacks.onToggleAttachment)
  trackerFrame.attachDetachButton:SetHighlightAtlas("RedButton-Highlight", "ADD")

  trackerFrame.filterButton = CreateFrame("Button", nil, trackerFrame)
  trackerFrame.filterButton:SetScript("OnClick", callbacks.onToggleFilter)
  trackerFrame.filterButton:SetSize(FILTER_BUTTON_SIZE, FILTER_BUTTON_SIZE)

  trackerFrame.contentFrame = CreateFrame("Frame", nil, trackerFrame)

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
  trackerFrame.topHeaderButton:SetScript("OnClick", callbacks.onToggleTopHeader)

  if trackerFrame.topHeaderMinimizeButton then
    trackerFrame.topHeaderMinimizeButton:SetScript("OnClick", callbacks.onToggleTopHeader)
  end

  trackerFrame.headerButton = CreateFrame("Button", nil, trackerFrame.headerFrame)
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
