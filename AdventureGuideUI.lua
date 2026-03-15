local AdventureGuideUI = {}

local checkboxByButton = setmetatable({}, { __mode = "k" })
local buttonByCheckbox = setmetatable({}, { __mode = "k" })
local itemDataByButton = setmetatable({}, { __mode = "k" })
local checkboxOverlay = nil
local getLootScrollBox

local function frameOrAncestorNameMatches(frame, patterns)
  while frame do
    local name = frame.GetName and frame:GetName() or nil
    if type(name) == "string" then
      local lowered = name:lower()
      for _, pattern in ipairs(patterns) do
        if lowered:find(pattern, 1, true) then
          return true
        end
      end
    end

    frame = frame:GetParent()
  end

  return false
end

local function extractTextFromFrame(frame)
  local namedRegions = { "name", "text", "label", "itemName", "Name" }
  for _, key in ipairs(namedRegions) do
    local region = frame[key]
    if region and region.GetText then
      local text = region:GetText()
      if text and text ~= "" then
        return text
      end
    end
  end

  local regions = { frame:GetRegions() }
  for _, region in ipairs(regions) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local text = region:GetText()
      if text and text ~= "" then
        return text
      end
    end
  end

  return nil
end

local function getPrimaryTextRegion(frame)
  local namedRegions = { "name", "text", "label", "itemName", "Name" }
  for _, key in ipairs(namedRegions) do
    local region = frame[key]
    if region and region.GetText then
      local text = region:GetText()
      if text and text ~= "" then
        return region
      end
    end
  end

  local bestRegion = nil
  local bestTop = nil
  local regions = { frame:GetRegions() }
  for _, region in ipairs(regions) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local text = region:GetText()
      if text and text ~= "" then
        local top = region.GetTop and region:GetTop() or 0
        if bestRegion == nil or top > bestTop then
          bestRegion = region
          bestTop = top
        end
      end
    end
  end

  return bestRegion
end

local function buildItemData(namespace, frame)
  local data = frame.data or frame.info or frame.itemInfo
  local itemID = frame.itemID or frame.itemId or (data and (data.itemID or data.itemId or data.id))
  local itemLink = frame.link or frame.itemLink or (data and (data.link or data.itemLink))

  if not itemID and itemLink then
    itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  end

  if not itemID then
    return nil
  end

  local encounterID = frame.encounterID or frame.bossID or (data and (data.encounterID or data.bossID))
  if not encounterID and EncounterJournal then
    encounterID = EncounterJournal.encounterID
  end

  local instanceID = frame.instanceID or (data and data.instanceID)
  if not instanceID and EncounterJournal then
    instanceID = EncounterJournal.instanceID
  end

  return {
    itemID = itemID,
    itemLink = itemLink,
    itemName = extractTextFromFrame(frame),
    encounterID = encounterID,
    instanceID = instanceID,
    instanceName = namespace.GetCurrentSourceLabel({
      itemData = data,
      frame = frame,
      currentTitle = EncounterJournal and EncounterJournal.instanceSelect and EncounterJournal.instanceSelect.title and
          EncounterJournal.instanceSelect.title.GetText and EncounterJournal.instanceSelect.title:GetText() or nil,
    }),
  }
end

local function isLikelyLootButton(frame)
  local data = frame.data or frame.info or frame.itemInfo
  local hasItemIdentity = frame.itemID or frame.itemId or frame.itemLink or frame.link or
      (data and (data.itemID or data.itemId or data.link or data.itemLink))
  if not hasItemIdentity then
    return false
  end

  if frameOrAncestorNameMatches(frame, { "instanceselect", "dropdown", "filter", "nav" }) then
    return false
  end

  if frameOrAncestorNameMatches(frame, { "loot" }) then
    return true
  end

  if data and (data.slot or data.encounterID or data.bossID) then
    return true
  end

  if frame.icon or frame.Icon then
    return true
  end

  return false
end

local function ensureCheckbox(namespace, lootButton)
  local checkbox = checkboxByButton[lootButton]
  if checkbox then
    return checkbox
  end

  local checkboxParent = checkboxOverlay or getLootScrollBox() or EncounterJournal or UIParent
  checkbox = CreateFrame("CheckButton", nil, checkboxParent, "UICheckButtonTemplate")
  checkbox:SetSize(24, 24)
  checkbox:SetFrameStrata("DIALOG")
  checkbox:HookScript("OnClick", function(self)
    local ownerButton = buttonByCheckbox[self]
    local itemData = ownerButton and itemDataByButton[ownerButton] or nil
    if self.isUpdating or not itemData then
      return
    end

    namespace.SetTrackedFromItemData(itemData, self:GetChecked())
  end)

  checkboxByButton[lootButton] = checkbox
  buttonByCheckbox[checkbox] = lootButton
  return checkbox
end

function getLootScrollBox()
  return EncounterJournal and EncounterJournal.encounter and EncounterJournal.encounter.info and
      EncounterJournal.encounter.info.LootContainer and EncounterJournal.encounter.info.LootContainer.ScrollBox or nil
end

local function ensureCheckboxOverlay()
  local scrollBox = getLootScrollBox()
  if not scrollBox then
    return nil
  end

  if checkboxOverlay and checkboxOverlay:GetParent() ~= scrollBox then
    checkboxOverlay:Hide()
    checkboxOverlay:SetParent(scrollBox)
    checkboxOverlay:ClearAllPoints()
    checkboxOverlay:SetAllPoints(scrollBox)
  end

  if not checkboxOverlay then
    checkboxOverlay = CreateFrame("Frame", nil, scrollBox)
    checkboxOverlay:SetAllPoints(scrollBox)
    checkboxOverlay:EnableMouse(false)
  end

  checkboxOverlay:SetFrameStrata(scrollBox:GetFrameStrata())
  checkboxOverlay:SetFrameLevel((scrollBox:GetFrameLevel() or 0) + 20)
  checkboxOverlay:Show()
  return checkboxOverlay
end

local function visitLootDescendants(frame, callback, visited)
  if not frame or visited[frame] then
    return
  end

  visited[frame] = true

  if frame ~= getLootScrollBox() and frame.GetObjectType and frame:GetObjectType() == "Button" and frame:IsShown() and isLikelyLootButton(frame) then
    callback(frame)
  end

  if frame.GetChildren then
    for _, child in ipairs({ frame:GetChildren() }) do
      visitLootDescendants(child, callback, visited)
    end
  end
end

local function forEachVisibleLootButton(callback)
  local scrollBox = getLootScrollBox()
  if not scrollBox or not scrollBox:IsShown() then
    return
  end

  if type(scrollBox.ForEachFrame) == "function" then
    scrollBox:ForEachFrame(function(frame)
      if frame and frame:IsShown() and frame.GetObjectType and frame:GetObjectType() == "Button" and isLikelyLootButton(frame) then
        callback(frame)
      end
    end)
    return
  end

  visitLootDescendants(scrollBox, callback, {})
end

local function positionCheckbox(lootButton, checkbox)
  local overlayParent = ensureCheckboxOverlay()
  checkbox:ClearAllPoints()
  checkbox:SetParent(overlayParent or EncounterJournal or UIParent)
  if lootButton and lootButton.GetFrameLevel then
    checkbox:SetFrameLevel((lootButton:GetFrameLevel() or 0) + 30)
  end

  local textRegion = getPrimaryTextRegion(lootButton)
  if textRegion then
    checkbox:SetPoint("LEFT", textRegion, "RIGHT", 0, 0)
  else
    checkbox:SetPoint("RIGHT", lootButton, "RIGHT", 0, 0)
  end
end

function AdventureGuideUI.Refresh(namespace)
  if not EncounterJournal or not EncounterJournal:IsShown() then
    return
  end

  -- Only show checkboxes on Dungeons and Raids tabs, not on Item Sets/Journeys
  local isDungeonTab = type(EncounterJournal_IsDungeonTabSelected) == "function" and
      EncounterJournal_IsDungeonTabSelected(EncounterJournal)
  local isRaidTab = type(EncounterJournal_IsRaidTabSelected) == "function" and
      EncounterJournal_IsRaidTabSelected(EncounterJournal)
  local shouldShowCheckboxes = isDungeonTab or isRaidTab

  local seenButtons = {}

  forEachVisibleLootButton(function(frame)
    seenButtons[frame] = true

    local checkbox = checkboxByButton[frame]
    if checkbox and not shouldShowCheckboxes then
      checkbox:Hide()
      itemDataByButton[frame] = nil
      return
    end

    if shouldShowCheckboxes then
      local itemData = buildItemData(namespace, frame)
      if itemData then
        checkbox = ensureCheckbox(namespace, frame)
        positionCheckbox(frame, checkbox)
        itemDataByButton[frame] = itemData
        checkbox.isUpdating = true
        checkbox:SetChecked(namespace.IsTrackedItem(itemData.itemID))
        checkbox.isUpdating = false
        checkbox:Show()
      elseif checkbox then
        checkbox:Hide()
        itemDataByButton[frame] = nil
      end
    end
  end)

  for button, checkbox in pairs(checkboxByButton) do
    if checkbox and (not shouldShowCheckboxes or not seenButtons[button]) then
      checkbox:Hide()
      itemDataByButton[button] = nil
    end
  end
end

function AdventureGuideUI.Initialize(namespace)
  local updater = CreateFrame("Frame")
  namespace.journalUpdater = updater

  local function startUpdater()
    updater:SetScript("OnUpdate", function(_, elapsed)
      namespace.journalElapsed = (namespace.journalElapsed or 0) + elapsed
      if namespace.journalElapsed < 0.1 then
        return
      end

      namespace.journalElapsed = 0
      AdventureGuideUI.Refresh(namespace)
    end)
  end

  local function stopUpdater()
    updater:SetScript("OnUpdate", nil)
    namespace.journalElapsed = 0
  end

  local function hookEncounterJournal()
    if not EncounterJournal then
      return
    end

    EncounterJournal:HookScript("OnShow", startUpdater)
    EncounterJournal:HookScript("OnHide", stopUpdater)

    -- If it is already open right now (e.g. after /reload), start immediately.
    if EncounterJournal:IsShown() then
      startUpdater()
    end
  end

  -- Blizzard_EncounterJournal is load-on-demand; it may not exist yet.
  if EncounterJournal then
    hookEncounterJournal()
  else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, addonName)
      if addonName == "Blizzard_EncounterJournal" then
        self:UnregisterAllEvents()
        hookEncounterJournal()
      end
    end)
  end

  local hookTargets = {
    "EncounterJournal_LootUpdate",
    "EncounterJournal_UpdateLootInfo",
    "EncounterJournal_UpdateFilterString",
  }

  for _, hookName in ipairs(hookTargets) do
    if type(_G[hookName]) == "function" then
      hooksecurefunc(hookName, function()
        AdventureGuideUI.Refresh(namespace)
      end)
    end
  end
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.AdventureGuideUI = AdventureGuideUI
end

return AdventureGuideUI
