local _, namespace = ...

local TrackerTooltip = {}

local trackerTooltip = CreateFrame("GameTooltip", "LootWishListTrackerTooltip", UIParent, "GameTooltipTemplate")
local hoveredTrackerRow = nil

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

local function getLiveHoveredTrackerRow(runtimeNamespace, trackerFrame)
  if type(GetMouseFocus) ~= "function" or not trackerFrame or not trackerFrame.rows then
    if not trackerFrame or not trackerFrame.rows then
      return nil
    end
  end

  local focus = type(GetMouseFocus) == "function" and GetMouseFocus() or nil

  if hoveredTrackerRow and isValidHoveredItemRow(hoveredTrackerRow) then
    if focus and runtimeNamespace and runtimeNamespace.TrackerUtils and runtimeNamespace.TrackerUtils.IsDescendantOf and
        runtimeNamespace.TrackerUtils.IsDescendantOf(focus, hoveredTrackerRow) then
      return hoveredTrackerRow
    end

    if isCursorOverFrame(hoveredTrackerRow) then
      return hoveredTrackerRow
    end
  end

  for _, row in ipairs(trackerFrame.rows) do
    if isValidHoveredItemRow(row) then
      if focus and runtimeNamespace and runtimeNamespace.TrackerUtils and runtimeNamespace.TrackerUtils.IsDescendantOf and
          runtimeNamespace.TrackerUtils.IsDescendantOf(focus, row) then
        return row
      end

      if isCursorOverFrame(row) then
        return row
      end
    end
  end

  return nil
end

function TrackerTooltip.Show(runtimeNamespace, row)
  if not row or row.isBossHeader or (type(row.IsShown) == "function" and not row:IsShown()) then
    return
  end

  local ref = row.tooltipRef
  local id = row.itemID
  if type(ref) ~= "string" and type(id) ~= "number" then
    return
  end

  if runtimeNamespace and runtimeNamespace.TooltipCompare and runtimeNamespace.TooltipCompare.hide then
    runtimeNamespace.TooltipCompare.hide(trackerTooltip)
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

  if runtimeNamespace and runtimeNamespace.TooltipCompare and runtimeNamespace.TooltipCompare.showComparison then
    runtimeNamespace.TooltipCompare.showComparison(trackerTooltip, row)
  end
end

function TrackerTooltip.Hide(runtimeNamespace)
  if runtimeNamespace and runtimeNamespace.TooltipCompare and runtimeNamespace.TooltipCompare.hide then
    runtimeNamespace.TooltipCompare.hide(trackerTooltip)
  else
    trackerTooltip:Hide()
  end
end

function TrackerTooltip.ClearHoveredRow()
  hoveredTrackerRow = nil
end

function TrackerTooltip.SetHoveredRow(row)
  hoveredTrackerRow = row
end

function TrackerTooltip.Reconcile(runtimeNamespace, trackerFrame)
  local liveRow = getLiveHoveredTrackerRow(runtimeNamespace, trackerFrame)
  if not isValidHoveredItemRow(liveRow) then
    TrackerTooltip.ClearHoveredRow()
    TrackerTooltip.Hide(runtimeNamespace)
    return
  end

  TrackerTooltip.SetHoveredRow(liveRow)
  TrackerTooltip.Show(runtimeNamespace, liveRow)
end

if type(namespace) == "table" then
  namespace.TrackerTooltip = TrackerTooltip
end

return TrackerTooltip
