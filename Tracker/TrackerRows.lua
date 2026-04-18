local _, namespace = ...

local TrackerRows = {}

local ROW_HEIGHT = 16

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

function TrackerRows.PlayHeaderAnimation(row, animationType)
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

function TrackerRows.Ensure(frame, index, runtimeNamespace)
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
  row.tick:SetSize(runtimeNamespace.TrackerRowStyle.CHECK_SIZE, runtimeNamespace.TrackerRowStyle.CHECK_SIZE)
  row.tick:SetAtlas(runtimeNamespace.TrackerRowStyle.CHECK_ATLAS, false)

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

function TrackerRows.HideUnused(frame, firstUnusedIndex)
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
    row.isPossessed = nil
    row.tooltipFooter = nil
  end
end

function TrackerRows.RenderGroupHeader(runtimeNamespace, frame, row, group, itemCount, collapsed, onToggle)
  local headerInset = runtimeNamespace.TrackerHeaders.GetHeaderTextInset(frame)
  row:RegisterForClicks("LeftButtonUp")
  row.tick:Hide()
  row.dash:Hide()
  row.collapseButton:Show()
  row.collapseButton:ClearAllPoints()
  row.collapseButton:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  runtimeNamespace.TrackerHeaders.ApplyCollapseButtonState(row.collapseButton, collapsed)

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
  row.isPossessed = nil
  row.tooltipRef = nil
  row.itemID = nil
  row.tooltipFooter = nil
  row:SetScript("OnClick", function(self, button)
    if button ~= "LeftButton" then
      return
    end

    if self.collapseButton and self.collapseButton.IsMouseOver and self.collapseButton:IsMouseOver() then
      return
    end

    onToggle()
  end)
  row:SetScript("OnMouseUp", nil)
  row:SetScript("OnEnter", nil)
  row:SetScript("OnLeave", nil)
  row.collapseButton:SetScript("OnClick", onToggle)
  row:Show()
end

function TrackerRows.RenderItemRow(runtimeNamespace, frame, row, item, callbacks)
  local headerInset = runtimeNamespace.TrackerHeaders.GetHeaderTextInset(frame)
  local rowLayout = runtimeNamespace.TrackerRowStyle.getRowLayout(item.showTick == true)
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
    row.isPossessed = nil
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
      row.tick:SetPoint("LEFT", row, "LEFT", headerInset + rowLayout.checkLeftOffset, 0)
      row.dash:Hide()
    else
      row.tick:Hide()
      row.dash:Show()
      row.dash:ClearAllPoints()
      row.dash:SetPoint("LEFT", row, "LEFT", headerInset + rowLayout.checkLeftOffset, 0)
    end

    row.text:SetPoint("LEFT", row, "LEFT", headerInset + rowLayout.textLeftOffset, 0)
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
    row.isPossessed = item.showTick == true
    row.itemID = item.itemID
    row.tooltipRef = item.displayLink or item.tooltipRef
    row.tooltipFooter = item.tooltipFooter
    row:SetScript("OnEnter", callbacks.onEnter)
    row:SetScript("OnLeave", callbacks.onLeave)
    row:SetScript("OnClick", callbacks.onClick)
    row:SetScript("OnMouseUp", callbacks.onMouseUp)
  end

  row.groupKey = nil
  row.groupMode = nil
  row.instanceID = nil
  row:Show()
end

if type(namespace) == "table" then
  namespace.TrackerRows = TrackerRows
end

return TrackerRows
