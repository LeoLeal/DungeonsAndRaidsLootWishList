local AdventureGuideUI = {}

local function isEncounterJournalDescendant(frame)
  while frame do
    if frame == EncounterJournal then
      return true
    end

    frame = frame:GetParent()
  end

  return false
end

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
  local checkbox = lootButton.LootWishListCheckbox
  if checkbox then
    return checkbox
  end

  checkbox = CreateFrame("CheckButton", nil, lootButton, "UICheckButtonTemplate")
  checkbox:SetSize(24, 24)
  checkbox:SetScript("OnClick", function(self)
    if self.isUpdating or not self.itemData then
      return
    end

    namespace.SetTrackedFromItemData(self.itemData, self:GetChecked())
  end)

  lootButton.LootWishListCheckbox = checkbox
  return checkbox
end

local function positionCheckbox(lootButton, checkbox)
  checkbox:ClearAllPoints()

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

  local frame = nil
  while true do
    frame = EnumerateFrames(frame)
    if not frame then
      break
    end

    if frame:IsShown() and frame:GetObjectType() == "Button" and isEncounterJournalDescendant(frame) then
      -- Hide our checkboxes if not on dungeon/raid tabs
      local checkbox = frame.LootWishListCheckbox
      if checkbox and not shouldShowCheckboxes then
        checkbox:Hide()
      end

      if shouldShowCheckboxes and isLikelyLootButton(frame) then
        local itemData = buildItemData(namespace, frame)
        if itemData then
          checkbox = ensureCheckbox(namespace, frame)
          positionCheckbox(frame, checkbox)
          checkbox.itemData = itemData
          checkbox.isUpdating = true
          checkbox:SetChecked(namespace.IsTrackedItem(itemData.itemID))
          checkbox.isUpdating = false
          checkbox:Show()
        end
      end
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
