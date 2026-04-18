local _, namespace = ...

local Tracker = {}

local trackerFrame = nil
local currentGroups = {}
local knownRowKeys = {}
local knownItemStates = {}
local ns = nil
local syncTrackerFrame = nil

local HEADER_HEIGHT = 26
local ROW_HEIGHT = 16
local GROUP_SPACING = 5
local WISHLIST_HEADER_TOP_PADDING = 10
local CONTENT_TOP_GAP = 4
local DETACHED_CONTENT_TOP_MARGIN = 4
local STANDALONE_HEADER_OFFSET_Y = -3
local FRAME_LEFT_PADDING = 10
local STANDALONE_HEADER_BOTTOM_MARGIN = 10
local POST_TRANSITION_RESYNC_DELAY = 0.15

local postTransitionSyncTimer = nil

local function isTrackerDetached()
  return ns and type(ns.GetTrackerAttachmentMode) == "function" and ns.GetTrackerAttachmentMode() == "detached"
end

local function playAddAnimation(frame)
  if frame and frame.headerFrame and frame.headerFrame.AddAnim and frame.headerFrame.AddAnim.Restart then
    frame.headerFrame.AddAnim:Restart()
  elseif type(ObjectiveTracker_PlayBlockAddedAnimation) == "function" then
    ObjectiveTracker_PlayBlockAddedAnimation(frame.headerFrame or frame)
  elseif type(UIFrameFlash) == "function" then
    UIFrameFlash(frame, 0.2, 0.3, 0.8, false, 0, 0)
  end
end

local function hideTrackerTooltip()
  ns.TrackerTooltip.Hide(ns)
end

local function clearHoveredTrackerRow()
  ns.TrackerTooltip.ClearHoveredRow()
end

local function showTrackerTooltip(row)
  ns.TrackerTooltip.Show(ns, row)
end

local function showTrackerContextMenu(row)
  ns.TrackerContextMenu.Show(ns, row, hideTrackerTooltip, clearHoveredTrackerRow)
end

local function renderGroupHeader(row, group, itemCount, collapsed)
  ns.TrackerRows.RenderGroupHeader(ns, trackerFrame, row, group, itemCount, collapsed, function()
    local charKey = ns.GetCharacterKey()
    local previousState = ns.WishlistStore.isGroupCollapsed(LootWishListDB, charKey, group.mode, group.key)
    ns.WishlistStore.toggleGroupCollapse(LootWishListDB, charKey, group.mode, group.key)
    local currentState = ns.WishlistStore.isGroupCollapsed(LootWishListDB, charKey, group.mode, group.key)
    if previousState ~= currentState then
      ns.TrackerHeaders.PlayMenuCheckboxSound()
    end
    Tracker.Refresh(ns, currentGroups)
  end)
end

local function renderItemRow(row, item)
  ns.TrackerRows.RenderItemRow(ns, trackerFrame, row, item, {
    onEnter = function(self)
      ns.TrackerTooltip.SetHoveredRow(self)
      showTrackerTooltip(self)
    end,
    onLeave = function()
      clearHoveredTrackerRow()
      hideTrackerTooltip()
    end,
    onClick = function(self, button)
      if button == "LeftButton" and IsShiftKeyDown() and self.itemID then
        ns.RemoveTrackedItem(self.itemID)
      end
    end,
    onMouseUp = function(self, button)
      if button == "RightButton" then
        showTrackerContextMenu(self)
      end
    end,
  })
end

syncTrackerFrame = function()
  local frame = trackerFrame
  if not frame then
    return
  end

  ns.TrackerContextMenu.Close()

  if not currentGroups or #currentGroups == 0 then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame:Hide()
    return
  end

  local detached = isTrackerDetached()
  if not detached and ns.TrackerAnchoring.IsTrackerExplicitlyCollapsed() then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame:Hide()
    return
  end

  local showStandaloneHeader = not detached and ns.TrackerAnchoring.GetAnchorMode(ns) == "standalone"

  ns.TrackerAnchoring.AnchorTrackerFrame(frame, ns)
  frame:Show()
  frame.useTopHeaderTextInset = detached == true

  if frame.topHeader then
    frame.topHeader:SetShown(showStandaloneHeader or detached)
  end
  if frame.topHeaderButton then
    frame.topHeaderButton:SetShown(showStandaloneHeader or detached)
  end

  local headerText = frame.headerText or frame.headerFrame.Text or frame.headerFrame.HeaderText
  if headerText then
    headerText:SetText(ns.GetText("LOOT_WISHLIST"))
  end

  if frame.topHeaderText then
    if detached then
      frame.topHeaderText:SetText(ns.GetText("LOOT_WISHLIST"))
    else
      frame.topHeaderText:SetText(_G.TRACKER_ALL_OBJECTIVES or "All Objectives")
    end
  end

  ns.TrackerHeaders.SetWishlistCollapse(frame, frame.lootWishlistCollapsed)

  local contentTopOffset = 0
  if detached then
    if frame.headerFrame then
      frame.headerFrame:Hide()
    end
    if frame.headerButton then
      frame.headerButton:Hide()
    end
    ns.TrackerHeaders.ApplyTopHeaderButtonState(frame, frame.lootWishlistCollapsed)
    ns.TrackerHeaders.LayoutHeaderControls(frame, ns, {
      header = frame.topHeader,
      headerText = frame.topHeaderText,
      collapseButton = frame.topHeaderMinimizeButton,
      clickButton = frame.topHeaderButton,
      showAttachButton = true,
      showGroupingButton = true,
      showLockButton = true,
      detached = true,
    })
    contentTopOffset = math.abs(STANDALONE_HEADER_OFFSET_Y) + HEADER_HEIGHT + CONTENT_TOP_GAP + DETACHED_CONTENT_TOP_MARGIN
  else
    if frame.topHeader then
      frame.topHeader:SetShown(showStandaloneHeader)
    end
    if frame.topHeaderButton then
      frame.topHeaderButton:SetShown(showStandaloneHeader)
    end
    if showStandaloneHeader then
      ns.TrackerHeaders.ApplyStandaloneHeaderButtonState(frame)
      ns.TrackerHeaders.LayoutHeaderControls(frame, ns, {
        header = frame.topHeader,
        headerText = frame.topHeaderText,
        collapseButton = frame.topHeaderMinimizeButton,
        clickButton = frame.topHeaderButton,
        showAttachButton = false,
        showGroupingButton = false,
        showLockButton = false,
        detached = false,
      })
    end

    frame.headerFrame:ClearAllPoints()
    if showStandaloneHeader then
      frame.headerFrame:SetPoint("TOPLEFT", frame.topHeader, "BOTTOMLEFT", 0, -STANDALONE_HEADER_BOTTOM_MARGIN)
      frame.headerFrame:SetPoint("TOPRIGHT", frame.topHeader, "BOTTOMRIGHT", 0, -STANDALONE_HEADER_BOTTOM_MARGIN)
      contentTopOffset = math.abs(STANDALONE_HEADER_OFFSET_Y) + HEADER_HEIGHT + STANDALONE_HEADER_BOTTOM_MARGIN + HEADER_HEIGHT + CONTENT_TOP_GAP
    else
      frame.headerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -WISHLIST_HEADER_TOP_PADDING)
      frame.headerFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -WISHLIST_HEADER_TOP_PADDING)
      contentTopOffset = WISHLIST_HEADER_TOP_PADDING + HEADER_HEIGHT + CONTENT_TOP_GAP
    end

    ns.TrackerHeaders.LayoutHeaderControls(frame, ns, {
      header = frame.headerFrame,
      headerText = headerText,
      collapseButton = frame.headerMinimizeButton,
      clickButton = frame.headerButton,
      showAttachButton = true,
      showGroupingButton = true,
      showLockButton = false,
      detached = false,
    })
  end

  if showStandaloneHeader and not detached and frame.lootWishlistStandaloneHidden then
    clearHoveredTrackerRow()
    hideTrackerTooltip()
    frame.headerFrame:Hide()
    if frame.headerButton then
      frame.headerButton:Hide()
    end
    if frame.attachDetachButton then
      frame.attachDetachButton:Hide()
    end
    if frame.groupingButton then
      frame.groupingButton:Hide()
    end
    if frame.lockButton then
      frame.lockButton:Hide()
    end
    if frame.contentFrame then
      frame.contentFrame:Hide()
      frame.contentFrame:SetHeight(0)
    end
    ns.TrackerRows.HideUnused(frame, 1)
    frame:SetHeight(math.abs(STANDALONE_HEADER_OFFSET_Y) + HEADER_HEIGHT)
    return
  end

  if detached then
    frame.headerFrame:Hide()
    if frame.headerButton then
      frame.headerButton:Hide()
    end
  else
    frame.headerFrame:Show()
    if frame.headerButton then
      frame.headerButton:Show()
    end
  end
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
    ns.TrackerRows.HideUnused(frame, 1)
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
  local charKey = ns.GetCharacterKey()

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

        knownItemStates[uniqueKey] = { showTick = item.showTick == true }
      end
    end

    local collapsed = ns.WishlistStore.isGroupCollapsed(db, charKey, group.mode, group.key)
    local headerRow = ns.TrackerRows.Ensure(frame, rowIndex, ns)
    headerRow:ClearAllPoints()
    headerRow:SetPoint("TOPLEFT", frame.contentFrame or frame, "TOPLEFT", 0, yOffset)
    headerRow:SetPoint("TOPRIGHT", frame.contentFrame or frame, "TOPRIGHT", 0, yOffset)
    renderGroupHeader(headerRow, group, itemCount, collapsed)
    if groupAnimations[group.key] then
      ns.TrackerRows.PlayHeaderAnimation(headerRow, groupAnimations[group.key])
    end
    yOffset = yOffset - ROW_HEIGHT
    rowIndex = rowIndex + 1

    if not collapsed then
      for _, item in ipairs(group.items) do
        local itemRow = ns.TrackerRows.Ensure(frame, rowIndex, ns)
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

  ns.TrackerRows.HideUnused(frame, rowIndex)
  local contentHeight = math.max(0, -yOffset)
  if frame.contentFrame then
    frame.contentFrame:SetHeight(contentHeight)
  end

  frame:SetHeight(contentTopOffset + contentHeight + CONTENT_TOP_GAP)

  if addedNewItem then
    playAddAnimation(frame)
  end

  ns.TrackerTooltip.Reconcile(ns, trackerFrame)
end

function Tracker.RequestPostTransitionResync(runtimeNamespace)
  ns = ns or runtimeNamespace

  if postTransitionSyncTimer and postTransitionSyncTimer.Cancel then
    postTransitionSyncTimer:Cancel()
    postTransitionSyncTimer = nil
  end

  if type(C_Timer) ~= "table" or type(C_Timer.NewTimer) ~= "function" then
    runtimeNamespace.RefreshTracker()
    return
  end

  -- Coalesce loading-screen and teleport relayout into one post-transition sync.
  postTransitionSyncTimer = C_Timer.NewTimer(POST_TRANSITION_RESYNC_DELAY, function()
    postTransitionSyncTimer = nil
    runtimeNamespace.RefreshTracker()
  end)
end

function Tracker.Initialize(runtimeNamespace)
  if trackerFrame then
    return
  end

  ns = runtimeNamespace
  trackerFrame = ns.TrackerFrame.Create(ns, {
    onToggleGrouping = function()
      local nextMode = ns.GetTrackerGroupingMode() == "slot" and "source" or "slot"
      ns.SetTrackerGroupingMode(nextMode)
    end,
    onToggleTopHeader = function()
      if isTrackerDetached() then
        ns.TrackerHeaders.ToggleWishlistCollapse(trackerFrame, syncTrackerFrame)
      else
        ns.TrackerHeaders.ToggleStandaloneCollapse(trackerFrame, syncTrackerFrame)
      end
    end,
    onToggleWishlist = function()
      ns.TrackerHeaders.ToggleWishlistCollapse(trackerFrame, syncTrackerFrame)
    end,
    onToggleAttachment = function()
      if isTrackerDetached() then
        ns.SetTrackerAttachmentMode("attached")
      else
        if not ns.GetTrackerDetachedPosition() then
          ns.TrackerAnchoring.SaveDetachedPosition(ns, trackerFrame)
        end
        ns.SetTrackerAttachmentMode("detached")
      end
    end,
    onToggleDetachedLock = function()
      if isTrackerDetached() then
        if not ns.IsTrackerDetachedLocked() then
          ns.TrackerAnchoring.SaveDetachedPosition(ns, trackerFrame)
        end
        ns.ToggleTrackerDetachedLocked()
      end
    end,
  })

  runtimeNamespace.trackerFrame = trackerFrame
  ns.TrackerAnchoring.HookTrackerState(trackerFrame, syncTrackerFrame)
  syncTrackerFrame()
end

function Tracker.ResolveEffectiveDisplayLink(runtimeNamespace, item, bestOwnedLinks)
  return runtimeNamespace.TrackerRenderData.resolveEffectiveDisplayLink(runtimeNamespace, item, bestOwnedLinks)
end

function Tracker.PrimeEncounterDataForInstance(runtimeNamespace, instanceID)
  return runtimeNamespace.RaidBossOrdering.PrimeEncounterDataForInstance(instanceID)
end

function Tracker.PrimeTrackedEncounterData(runtimeNamespace)
  return runtimeNamespace.RaidBossOrdering.PrimeTrackedEncounterData(runtimeNamespace)
end

function Tracker.RefreshState(runtimeNamespace)
  ns = ns or runtimeNamespace
  runtimeNamespace.PossessionScanner.Refresh(runtimeNamespace)
  Tracker.Refresh(runtimeNamespace, runtimeNamespace.TrackerRenderData.buildTrackedGroups(runtimeNamespace))
end

function Tracker.Refresh(runtimeNamespace, groups)
  if not trackerFrame then
    Tracker.Initialize(runtimeNamespace)
  end

  if not trackerFrame then
    return
  end

  currentGroups = groups or {}
  syncTrackerFrame()
end

if type(namespace) == "table" then
  namespace.Tracker = Tracker
end

return Tracker
