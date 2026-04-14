local TooltipCompare = {}

local compareTooltips = nil
local COMPARE_GAP = 3
local COMPARE_HEADER_TEXT = EQUIPPED or "Equipped"
local COMPARE_HEADER_HEIGHT = 22
local COMPARE_HEADER_PADDING = 30

local function ensureCompareHeader(tooltip)
  if tooltip.compareHeader then
    return tooltip.compareHeader
  end

  local header = CreateFrame("Frame", nil, tooltip)
  header:SetFrameLevel(tooltip:GetFrameLevel() + 1)
  header:SetPoint("BOTTOMLEFT", tooltip, "TOPLEFT", 0, -1)
  header:SetSize(100, COMPARE_HEADER_HEIGHT)

  header.background = header:CreateTexture(nil, "BACKGROUND")
  header.background:SetAllPoints(true)
  header.background:SetAtlas("tooltip-compare-label")

  header.text = header:CreateFontString(nil, "ARTWORK", "GameTooltipText")
  header.text:SetPoint("CENTER", header, "CENTER", 0, 0)
  header.text:SetText(COMPARE_HEADER_TEXT)

  tooltip.compareHeader = header
  return header
end

local function updateCompareHeader(tooltip)
  local header = ensureCompareHeader(tooltip)
  header.text:SetText(COMPARE_HEADER_TEXT)
  if NORMAL_FONT_COLOR and header.text.SetTextColor then
    header.text:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
  end
  header:SetWidth(math.max(100, header.text:GetStringWidth() + COMPARE_HEADER_PADDING))
  header:Show()
end

local function getCompareTooltips()
  if compareTooltips then
    return compareTooltips
  end

  compareTooltips = {
    CreateFrame("GameTooltip", "LootWishListCompareTooltip1", UIParent, "GameTooltipTemplate"),
    CreateFrame("GameTooltip", "LootWishListCompareTooltip2", UIParent, "GameTooltipTemplate"),
  }

  for _, tooltip in ipairs(compareTooltips) do
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:SetClampedToScreen(true)
  end

  return compareTooltips
end

local function hideCompareTooltips()
  for _, tooltip in ipairs(getCompareTooltips()) do
    if tooltip.compareHeader then
      tooltip.compareHeader:Hide()
    end
    tooltip:Hide()
  end
end

local function buildComparisonItem(tooltip)
  if not tooltip or not tooltip.GetPrimaryTooltipData then
    return nil
  end

  local tooltipData = tooltip:GetPrimaryTooltipData()
  if type(tooltipData) ~= "table" then
    return nil
  end

  if tooltipData.guid then
    return {
      guid = tooltipData.guid,
      overrideItemLevel = tooltipData.overrideItemLevel,
    }
  end

  if type(tooltipData.hyperlink) == "string" and tooltipData.hyperlink ~= "" then
    return {
      hyperlink = tooltipData.hyperlink,
      overrideItemLevel = tooltipData.overrideItemLevel,
    }
  end

  return nil
end

local function setTooltipFromDisplayedItem(tooltip, displayedItem)
  if not tooltip or type(displayedItem) ~= "table" then
    return false
  end

  tooltip:Hide()
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:ClearAllPoints()

  if displayedItem.guid and type(C_TooltipInfo) == "table" and type(C_TooltipInfo.GetItemByGUID) == "function" and tooltip.ProcessInfo then
    local tooltipData = C_TooltipInfo.GetItemByGUID(displayedItem.guid)
    if type(tooltipData) == "table" then
      tooltip:ProcessInfo({ tooltipData = tooltipData })
      updateCompareHeader(tooltip)
      tooltip:Show()
      return true
    end
  end

  if type(displayedItem.hyperlink) == "string" and displayedItem.hyperlink ~= "" then
    tooltip:SetHyperlink(displayedItem.hyperlink)
    updateCompareHeader(tooltip)
    tooltip:Show()
    return true
  end

  return false
end

local function getTooltipTotalWidth(tooltip)
  local width = tooltip and tooltip.GetWidth and tooltip:GetWidth() or 0
  if tooltip and tooltip.compareHeader and tooltip.compareHeader:IsShown() then
    width = math.max(width, tooltip.compareHeader:GetWidth())
  end
  return width
end

local function shiftPrimaryTooltipRight(primaryTooltip, shownTooltips)
  if not primaryTooltip or #shownTooltips == 0 then
    return
  end

  local primaryLeft = primaryTooltip.GetLeft and primaryTooltip:GetLeft() or nil
  if not primaryLeft then
    return
  end

  local requiredWidth = 0
  for index, tooltip in ipairs(shownTooltips) do
    if index > 1 then
      requiredWidth = requiredWidth + COMPARE_GAP
    end
    requiredWidth = requiredWidth + getTooltipTotalWidth(tooltip)
  end

  local overflow = requiredWidth + COMPARE_GAP - primaryLeft
  if overflow <= 0 then
    return
  end

  local point, relativeTo, relativePoint, xOfs, yOfs = primaryTooltip:GetPoint(1)
  if not point then
    return
  end

  primaryTooltip:ClearAllPoints()
  primaryTooltip:SetPoint(point, relativeTo, relativePoint, (xOfs or 0) + overflow, yOfs or 0)
end

local function shouldAnchorRight(primaryTooltip, anchorFrame)
  local screenWidth = type(GetScreenWidth) == "function" and GetScreenWidth() or nil
  if not screenWidth then
    return true
  end

  local decisionX = nil
  if anchorFrame and anchorFrame.GetLeft then
    decisionX = anchorFrame:GetLeft()
  end

  if not decisionX and primaryTooltip and primaryTooltip.GetLeft and primaryTooltip.GetRight then
    local primaryLeft = primaryTooltip:GetLeft()
    local primaryRight = primaryTooltip:GetRight()
    if primaryLeft and primaryRight then
      decisionX = (primaryLeft + primaryRight) / 2
    end
  end

  if not decisionX then
    return true
  end

  local screenCenter = screenWidth / 2
  return decisionX < screenCenter
end

local function anchorCompareTooltips(primaryTooltip, shownTooltips, anchorFrame)
  if #shownTooltips == 0 then
    return
  end

  local anchorRight = shouldAnchorRight(primaryTooltip, anchorFrame)
  if not anchorRight then
    shiftPrimaryTooltipRight(primaryTooltip, shownTooltips)
  end

  local previousTooltip = primaryTooltip
  for index, tooltip in ipairs(shownTooltips) do
    tooltip:ClearAllPoints()
    if anchorRight then
      if index == 1 then
        tooltip:SetPoint("TOPLEFT", primaryTooltip, "TOPRIGHT", COMPARE_GAP, 0)
      else
        tooltip:SetPoint("TOPLEFT", previousTooltip, "TOPRIGHT", COMPARE_GAP, 0)
      end
    else
      if index == 1 then
        tooltip:SetPoint("TOPRIGHT", primaryTooltip, "TOPLEFT", -COMPARE_GAP, 0)
      else
        tooltip:SetPoint("TOPRIGHT", previousTooltip, "TOPLEFT", -COMPARE_GAP, 0)
      end
    end
    previousTooltip = tooltip
  end
end

function TooltipCompare.hide(tooltip)
  hideCompareTooltips()

  if tooltip then
    tooltip:Hide()
  end
end

function TooltipCompare.showComparison(tooltip, anchorFrame)
  if not tooltip then
    return
  end

  if type(C_TooltipComparison) ~= "table" or type(C_TooltipComparison.GetItemComparisonInfo) ~= "function" then
    return
  end

  hideCompareTooltips()

  if anchorFrame and anchorFrame.isPossessed == true then
    return
  end

  local comparisonItem = buildComparisonItem(tooltip)
  if not comparisonItem then
    return
  end

  local compareInfo = C_TooltipComparison.GetItemComparisonInfo(comparisonItem)
  if type(compareInfo) ~= "table" then
    return
  end

  local displayedItems = {}
  if type(compareInfo.item) == "table" then
    table.insert(displayedItems, compareInfo.item)
  end

  if type(compareInfo.additionalItems) == "table" then
    for _, item in ipairs(compareInfo.additionalItems) do
      if type(item) == "table" then
        table.insert(displayedItems, item)
      end
    end
  end

  local shownTooltips = {}
  for index, displayedItem in ipairs(displayedItems) do
    local compareTooltip = getCompareTooltips()[index]
    if not compareTooltip then
      break
    end

    if setTooltipFromDisplayedItem(compareTooltip, displayedItem) then
      table.insert(shownTooltips, compareTooltip)
    end
  end

  if #shownTooltips > 0 then
    anchorCompareTooltips(tooltip, shownTooltips, anchorFrame)
  end
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TooltipCompare = TooltipCompare
end

return TooltipCompare
