local ADDON_NAME, namespace = ...

namespace.db = namespace.db or {}
namespace.state = namespace.state or {
  possessed = {},
  bankKnown = false,
  pendingLootAlerts = {},
  recentSelfLootByKey = {},
}

local eventFrame = CreateFrame("Frame")
namespace.eventFrame = eventFrame

local RECENT_SELF_LOOT_TTL_SECONDS = 3

local function getCharacterKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Unknown"
  return string.format("%s-%s", name, realm)
end

local function getLocaleId()
  if type(GetLocale) == "function" then
    return GetLocale()
  end

  return "enUS"
end

-- Queue a callback to execute after combat ends.
-- If not in combat, executes immediately.
-- If in combat, waits and re-checks until combat ends.
local function QueueAfterCombat(callback)
  if InCombatLockdown() then
    C_Timer.After(1, function()
      QueueAfterCombat(callback)
    end)
  else
    callback()
  end
end
namespace.QueueAfterCombat = QueueAfterCombat

-- Debounce utility: coalesces rapid calls into a single execution after delay
local function createDebouncedRefresh(delay)
  local timer = nil
  local fn = nil

  local function execute()
    timer = nil
    if fn then
      fn()
    end
  end

  return function(callback)
    fn = callback
    if timer then
      timer:Cancel()
    end
    timer = C_Timer.After(delay, execute)
  end
end

-- Create the debounced refresh with 250ms delay
local debouncedRefresh = createDebouncedRefresh(0.25)

local function getCurrentDb()
  LootWishListDB = LootWishListDB or { characters = {} }
  return LootWishListDB
end

local function getNow()
  if type(GetTime) == "function" then
    return GetTime()
  end

  return 0
end

local function pruneRecentSelfLoot(now)
  local recentSelfLootByKey = namespace.state.recentSelfLootByKey or {}
  namespace.state.recentSelfLootByKey = recentSelfLootByKey

  for key, timestamp in pairs(recentSelfLootByKey) do
    if type(timestamp) ~= "number" or (now - timestamp) > RECENT_SELF_LOOT_TTL_SECONDS then
      recentSelfLootByKey[key] = nil
    end
  end
end

function namespace.MarkRecentSelfLoot(itemID)
  if type(itemID) ~= "number" then
    return
  end

  local now = getNow()
  pruneRecentSelfLoot(now)
  local key = namespace.ItemResolver.getWishlistKey({ itemID = itemID })
  if key then
    namespace.state.recentSelfLootByKey[key] = now
  end
end

function namespace.WasRecentSelfLoot(itemID)
  if type(itemID) ~= "number" then
    return false
  end

  local now = getNow()
  pruneRecentSelfLoot(now)
  local key = namespace.ItemResolver.getWishlistKey({ itemID = itemID })
  if not key then
    return false
  end

  return namespace.state.recentSelfLootByKey[key] ~= nil
end

local function getTrackedItemEntry(itemID)
  return namespace.WishlistStore.getExistingItemEntry(getCurrentDb(), getCharacterKey(), itemID)
end

local function getTrackerGroupingMode()
  return namespace.WishlistStore.getGroupingMode(getCurrentDb(), getCharacterKey())
end

local isRaidInstance

local function getItemLevel(itemLink)
  if type(GetDetailedItemLevelInfo) == "function" and itemLink then
    return GetDetailedItemLevelInfo(itemLink)
  end

  return nil
end

local function markPossessedFromLink(lookup, highestLevels, bestOwnedLinks, itemLink)
  local itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID then
    return
  end

  local key = namespace.ItemResolver.getWishlistKey({ itemID = itemID })
  lookup[key] = true

  local itemLevel = getItemLevel(itemLink)
  if itemLevel and (not highestLevels[key] or itemLevel > highestLevels[key]) then
    highestLevels[key] = itemLevel
    bestOwnedLinks[key] = itemLink
  elseif not highestLevels[key] then
    bestOwnedLinks[key] = bestOwnedLinks[key] or itemLink
  end
end

function namespace.GetText(key, ...)
  return namespace.Locales.getString(getLocaleId(), key, ...)
end

function namespace.IsTrackedItem(itemID)
  return namespace.WishlistStore.isTracked(getCurrentDb(), getCharacterKey(), itemID)
end

function namespace.GetTrackerGroupingMode()
  return getTrackerGroupingMode()
end

function namespace.SetTrackerGroupingMode(groupBy)
  namespace.WishlistStore.setGroupingMode(getCurrentDb(), getCharacterKey(), groupBy)
  namespace.RefreshTracker()
  return getTrackerGroupingMode()
end

function namespace.RemoveTrackedItem(itemID)
  namespace.WishlistStore.removeItem(getCurrentDb(), getCharacterKey(), itemID)
  namespace.RefreshAllImmediate()
  if namespace.AdventureGuideUI and namespace.AdventureGuideUI.Refresh then
    namespace.AdventureGuideUI.Refresh(namespace)
  end
end

function namespace.GetCurrentSourceLabel(itemData)
  local rawItemData = itemData and (itemData.itemData or itemData) or nil

  if rawItemData and rawItemData.instanceName then
    return rawItemData.instanceName
  end

  if rawItemData and rawItemData.currentInstanceName and rawItemData.currentInstanceName ~= "" then
    return rawItemData.currentInstanceName
  end

  if itemData and itemData.currentTitle and itemData.currentTitle ~= "" then
    return itemData.currentTitle
  end

  if EncounterJournal and EncounterJournal.instanceID and type(EJ_GetInstanceInfo) == "function" then
    local instanceName = EJ_GetInstanceInfo(EncounterJournal.instanceID)
    if instanceName and instanceName ~= "" then
      return instanceName
    end
  end

  if EncounterJournal and EncounterJournal.selectedInstanceID and type(EJ_GetInstanceInfo) == "function" then
    local selectedInstanceName = EJ_GetInstanceInfo(EncounterJournal.selectedInstanceID)
    if selectedInstanceName and selectedInstanceName ~= "" then
      return selectedInstanceName
    end
  end

  if type(EJ_GetCurrentInstance) == "function" and type(EJ_GetInstanceInfo) == "function" then
    local currentInstanceID = EJ_GetCurrentInstance()
    if currentInstanceID then
      local currentInstanceName = EJ_GetInstanceInfo(currentInstanceID)
      if currentInstanceName and currentInstanceName ~= "" then
        return currentInstanceName
      end
    end
  end

  if type(EJ_GetInstanceInfo) == "function" then
    local instanceID = rawItemData and (rawItemData.instanceID or rawItemData.journalInstanceID)
    if instanceID then
      local instanceName = EJ_GetInstanceInfo(instanceID)
      if instanceName and instanceName ~= "" then
        return instanceName
      end
    end
  end

  if EncounterJournal and EncounterJournal.TitleText and EncounterJournal.TitleText.GetText then
    local currentTitle = EncounterJournal.TitleText:GetText()
    if currentTitle and currentTitle ~= "" then
      return currentTitle
    end
  end

  return namespace.GetText("OTHER")
end

function namespace.SetTrackedFromItemData(itemData, tracked)
  local normalized = namespace.ItemResolver.normalizeItemData(itemData)
  if not normalized then
    return
  end

  local db = getCurrentDb()
  local characterKey = getCharacterKey()

  if tracked then
    local bossName = nil
    if normalized.encounterID and normalized.instanceID and isRaidInstance(normalized.instanceID) and type(EJ_GetEncounterInfo) == "function" then
      bossName = EJ_GetEncounterInfo(normalized.encounterID)
    end

    namespace.WishlistStore.setTracked(db, characterKey, normalized.itemID, true)
    namespace.WishlistStore.setItemMetadata(db, characterKey, normalized.itemID, {
      itemName = normalized.itemName,
      itemLink = normalized.itemLink,
      sourceLabel = normalized.instanceName,
      encounterID = normalized.encounterID,
      instanceID = normalized.instanceID,
      bossName = bossName,
      inventoryType = normalized.inventoryType,
    })
    if normalized.instanceID then
      namespace.PrimeEncounterDataForInstance(normalized.instanceID)
    end
  else
    namespace.WishlistStore.removeItem(db, characterKey, normalized.itemID)
  end

  namespace.RefreshAllImmediate()
  if namespace.AdventureGuideUI and namespace.AdventureGuideUI.Refresh then
    namespace.AdventureGuideUI.Refresh(namespace)
  end
end

function namespace.RefreshPossessionState()
  local previousPossessed = namespace.state.possessed or {}
  local hasInitializedPossession = namespace.state.hasInitializedPossession == true
  local possessed = {}
  local highestLevels = {}
  local bestOwnedLinks = {}

  for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
    markPossessedFromLink(possessed, highestLevels, bestOwnedLinks, GetInventoryItemLink("player", slot))
  end

  if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink then
    for bag = BACKPACK_CONTAINER or 0, NUM_BAG_SLOTS or 4 do
      local numSlots = C_Container.GetContainerNumSlots(bag)
      for slot = 1, numSlots do
        markPossessedFromLink(possessed, highestLevels, bestOwnedLinks, C_Container.GetContainerItemLink(bag, slot))
      end
    end

    if namespace.state.bankKnown then
      if BANK_CONTAINER then
        local numBankSlots = C_Container.GetContainerNumSlots(BANK_CONTAINER) or 0
        for slot = 1, numBankSlots do
          markPossessedFromLink(possessed, highestLevels, bestOwnedLinks,
            C_Container.GetContainerItemLink(BANK_CONTAINER, slot))
        end
      end

      local firstBankBag = (NUM_BAG_SLOTS or 4) + 1
      local lastBankBag = (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7)
      for bag = firstBankBag, lastBankBag do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
          markPossessedFromLink(possessed, highestLevels, bestOwnedLinks, C_Container.GetContainerItemLink(bag, slot))
        end
      end
    end
  end

  namespace.state.possessed = possessed
  namespace.state.bestOwnedLinks = bestOwnedLinks

  local trackedItems = namespace.WishlistStore.getTrackedItems(getCurrentDb(), getCharacterKey())
  for _, item in ipairs(trackedItems) do
    local key = namespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
    if hasInitializedPossession and possessed[key] and not previousPossessed[key] then
      namespace.MarkRecentSelfLoot(item.itemID)
    end

    if highestLevels[key] then
      namespace.WishlistStore.updateBestLootedItemLevel(getCurrentDb(), getCharacterKey(), item.itemID,
        highestLevels[key])
    end
  end

  namespace.state.hasInitializedPossession = true
end

local raidInstances = {}
isRaidInstance = function(instanceID)
  if not instanceID then return false end
  if raidInstances[instanceID] ~= nil then
    return raidInstances[instanceID]
  end

  if type(EJ_GetInstanceByIndex) ~= "function" then
    return false
  end

  local i = 1
  while true do
    local id = EJ_GetInstanceByIndex(i, true)
    if not id then break end
    raidInstances[id] = true
    if id == instanceID then
      return true
    end
    i = i + 1
  end

  raidInstances[instanceID] = false
  return false
end

local instanceEncounterRanks = {}
local function primeEncounterDataForInstance(instanceID)
  if not instanceID or instanceEncounterRanks[instanceID] then
    return
  end

  instanceEncounterRanks[instanceID] = {}

  if type(EJ_SelectInstance) ~= "function" or type(EJ_GetEncounterInfoByIndex) ~= "function" then
    return
  end

  EJ_SelectInstance(instanceID)
  local e = 1
  while true do
    local _, _, encounterID = EJ_GetEncounterInfoByIndex(e)
    if not encounterID then
      break
    end

    instanceEncounterRanks[instanceID][encounterID] = e
    e = e + 1
  end
end

function namespace.PrimeEncounterDataForInstance(instanceID)
  primeEncounterDataForInstance(instanceID)
end

function namespace.IsRaidInstance(instanceID)
  return isRaidInstance(instanceID)
end

local function primeTrackedEncounterData()
  local trackedItems = namespace.WishlistStore.getTrackedItems(getCurrentDb(), getCharacterKey())
  local primed = {}

  for _, item in ipairs(trackedItems) do
    local instanceID = item.instanceID
    if isRaidInstance(instanceID) and not primed[instanceID] then
      primed[instanceID] = true
      primeEncounterDataForInstance(instanceID)
    end
  end
end

local function getEncounterRank(encounterID, instanceID)
  if not encounterID or not instanceID then return 999 end
  if not instanceEncounterRanks[instanceID] then return 999 end
  return instanceEncounterRanks[instanceID][encounterID] or 999
end

local function resolveBossName(encounterID, instanceID)
  if not encounterID or not instanceID then return nil end
  if not isRaidInstance(instanceID) then return nil end

  if type(EJ_GetEncounterInfo) == "function" then
    local name = EJ_GetEncounterInfo(encounterID)
    return name
  end

  return nil
end

local function getInventoryTypeLabel(inventoryType)
  if type(inventoryType) ~= "string" or inventoryType == "" then
    return namespace.GetText("OTHER")
  end

  if inventoryType == "INVTYPE_NON_EQUIP_IGNORE" then
    return namespace.GetText("OTHER")
  end

  local globalLabel = _G[inventoryType]
  if type(globalLabel) == "string" and globalLabel ~= "" then
    return globalLabel
  end

  return inventoryType
end

local function buildTooltipFooter(groupingMode, item)
  if groupingMode ~= "slot" then
    return nil
  end

  if type(item.sourceLabel) ~= "string" or item.sourceLabel == "" then
    return nil
  end

  if item.bossName and item.bossName ~= "" and isRaidInstance(item.instanceID) then
    return namespace.GetText("DROPS_FROM_RAID", item.sourceLabel, item.bossName)
  end

  return namespace.GetText("DROPS_FROM", item.sourceLabel)
end

function namespace.BuildTrackerGroups()
  local trackedItems = namespace.WishlistStore.getTrackedItems(getCurrentDb(), getCharacterKey())
  local renderItems = {}
  local bestOwnedLinks = namespace.state.bestOwnedLinks or {}
  local groupingMode = getTrackerGroupingMode()

  for _, item in ipairs(trackedItems) do
    local key = namespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
    local itemName = item.itemName or GetItemInfo(item.itemID) or item.itemLink or ("Item " .. tostring(item.itemID))
    local group = namespace.SourceResolver.resolveGroup(groupingMode, {
      instanceID = item.instanceID,
      instanceName = item.sourceLabel,
      sourceLabel = item.sourceLabel,
      inventoryType = item.inventoryType,
      slotLabel = getInventoryTypeLabel(item.inventoryType),
    }, namespace.GetText("OTHER"))
    local sourceLabel = item.sourceLabel
    local raidSource = isRaidInstance(item.instanceID)
    local bossName = raidSource and (item.bossName or resolveBossName(item.encounterID, item.instanceID)) or nil
    local tooltipFooter = buildTooltipFooter(groupingMode, {
      sourceLabel = sourceLabel,
      bossName = bossName,
      instanceID = item.instanceID,
    })
    local bestOwnedLink = bestOwnedLinks[key]
    local tooltipRef = namespace.ItemResolver.getTooltipRef({
      itemLink = item.itemLink,
      itemID = item.itemID,
    })
    local displayLink = bestOwnedLink or item.itemLink
    local bossRank = bossName and getEncounterRank(item.encounterID, item.instanceID) or nil

    table.insert(renderItems, {
      itemID = item.itemID,
      itemName = itemName,
      groupKey = group.key,
      groupLabel = group.label,
      groupSortIndex = group.sortIndex,
      instanceID = item.instanceID,
      isPossessed = namespace.state.possessed[key] == true,
      bestLootedItemLevel = item.bestLootedItemLevel,
      bossName = bossName,
      bossRank = bossRank,
      tooltipRef = tooltipRef,
      displayLink = displayLink,
      sourceLabel = sourceLabel,
      inventoryType = item.inventoryType,
      tooltipFooter = tooltipFooter,
      isRaidSource = raidSource,
    })
  end

  return namespace.TrackerModel.buildGroups(renderItems, {
    groupBy = groupingMode,
    otherLabel = namespace.GetText("OTHER"),
  })
end

function namespace.BuildLootAlertRecord(itemID, playerName, itemLink)
  if type(itemID) ~= "number" or type(playerName) ~= "string" or type(itemLink) ~= "string" or itemLink == "" then
    return nil
  end

  local entry = getTrackedItemEntry(itemID)
  if not entry or entry.tracked ~= true then
    return nil
  end

  return {
    itemID = itemID,
    itemName = entry.itemName,
    itemLink = itemLink,
    playerName = playerName,
  }
end

function namespace.ShowLootDialogFromRecord(record)
  if namespace.WishListAlert and namespace.WishListAlert.ShowFromRecord then
    namespace.WishListAlert.ShowFromRecord(namespace, record)
  end
end

function namespace.ShowLootDialog(playerName, itemLink)
  local itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  namespace.ShowLootDialogFromRecord({
    itemID = itemID,
    itemLink = itemLink,
    playerName = playerName,
  })
end

function namespace.FlushLootAlerts()
  if namespace.WishListAlert and namespace.WishListAlert.IsShown and namespace.WishListAlert.IsShown() then
    namespace.state.lootAlertFlushQueued = false
    return
  end

  local pendingLootAlerts = namespace.state.pendingLootAlerts or {}
  namespace.state.lootAlertFlushQueued = false

  if #pendingLootAlerts == 0 then
    return
  end

  local alertRecord = table.remove(pendingLootAlerts, 1)
  namespace.state.pendingLootAlerts = pendingLootAlerts
  namespace.ShowLootDialogFromRecord(alertRecord)
end

function namespace.QueueLootAlert(alertRecord)
  if type(alertRecord) ~= "table" then
    return
  end

  local pendingLootAlerts = namespace.state.pendingLootAlerts or {}
  namespace.state.pendingLootAlerts = pendingLootAlerts
  table.insert(pendingLootAlerts, alertRecord)

  if namespace.state.lootAlertFlushQueued then
    return
  end

  namespace.state.lootAlertFlushQueued = true
  QueueAfterCombat(function()
    namespace.FlushLootAlerts()
  end)
end

function namespace.RefreshTracker()
  namespace.TrackerUI.Refresh(namespace, namespace.BuildTrackerGroups())
end

-- Internal function that does the actual refresh work
local function doRefreshAll()
  namespace.RefreshPossessionState()
  namespace.RefreshTracker()
end

-- Public function: debounced refresh for non-critical events
function namespace.RefreshAll()
  debouncedRefresh(doRefreshAll)
end

-- Immediate refresh without debouncing - for critical events (login, user actions)
function namespace.RefreshAllImmediate()
  doRefreshAll()
end

local function registerEvents()
  eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
  eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  eventFrame:RegisterEvent("CHAT_MSG_LOOT")
  eventFrame:RegisterEvent("START_LOOT_ROLL")
  eventFrame:RegisterEvent("BANKFRAME_OPENED")
  eventFrame:RegisterEvent("BANKFRAME_CLOSED")
  eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
  eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    namespace.db = getCurrentDb()
    namespace.WishlistStore.runMigration(namespace.db, namespace)
    namespace.WishlistStore.repairTrackedMetadata(namespace.db, getCharacterKey(), namespace)
    primeTrackedEncounterData()
    namespace.TrackerUI.Initialize(namespace)
    namespace.AdventureGuideUI.Initialize(namespace)
    registerEvents()
    namespace.RefreshAllImmediate()
    return
  end

  if event == "CHAT_MSG_LOOT" then
    namespace.LootEvents.HandleChatLoot(namespace, ...)
    -- Defer refresh during combat - non-critical update
    if not InCombatLockdown() then
      namespace.RefreshAll()
    else
      QueueAfterCombat(function() namespace.RefreshAll() end)
    end
    return
  end

  if event == "START_LOOT_ROLL" then
    -- Capture the rollID argument
    local rollID = ...
    -- Defer loot roll UI updates during combat
    if not InCombatLockdown() then
      namespace.LootEvents.HandleStartLootRoll(namespace, rollID)
    else
      QueueAfterCombat(function() namespace.LootEvents.HandleStartLootRoll(namespace, rollID) end)
    end
    return
  end

  if event == "BANKFRAME_OPENED" then
    namespace.state.bankKnown = true
    namespace.RefreshAllImmediate()
    return
  end

  if event == "BANKFRAME_CLOSED" then
    namespace.RefreshAll()
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    -- Player left combat - immediate refresh to show updates right away
    namespace.RefreshAllImmediate()
    return
  end

  -- For BAG_UPDATE_DELAYED, PLAYER_EQUIPMENT_CHANGED, and other inventory events:
  -- Skip non-critical refreshes during combat
  if not InCombatLockdown() then
    namespace.RefreshAll()
  end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")

--@do-not-package@
-- === TEMPORARY TEST COMMAND ===
-- Type /testroll in-game to see the "WISHLIST" tag rendered over a template GroupLootFrame
SLASH_LWTESTROLL1 = "/testroll"
SlashCmdList["LWTESTROLL"] = function(msg)
  local rarityAliases = {
    poor = 0,
    common = 1,
    white = 1,
    uncommon = 2,
    green = 2,
    rare = 3,
    blue = 3,
    epic = 4,
    purple = 4,
    legendary = 5,
    orange = 5,
    artifact = 6,
    heirloom = 7,
  }
  local rarityBorderAtlases = {
    [0] = "loottoast-itemborder-grey",
    [1] = "loottoast-itemborder-white",
    [2] = "loottoast-itemborder-green",
    [3] = "loottoast-itemborder-blue",
    [4] = "loottoast-itemborder-purple",
    [5] = "loottoast-itemborder-orange",
    [6] = "loottoast-itemborder-artifact",
    [7] = "loottoast-itemborder-account",
  }

  local rarityInput = type(msg) == "string" and msg:match("^%s*(.-)%s*$") or ""
  local forcedQuality = nil
  if rarityInput ~= "" then
    forcedQuality = tonumber(rarityInput)
    if forcedQuality == nil then
      forcedQuality = rarityAliases[string.lower(rarityInput)]
    end

    if forcedQuality == nil or forcedQuality < 0 or forcedQuality > 7 then
      print("LootWishList: Invalid rarity. Use 0-7 or poor/common/uncommon/rare/epic/legendary/artifact/heirloom.")
      return
    end
  end

  -- Fetch a random tracked item
  local db = LootWishListDB or { characters = {} }
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Unknown"
  local charKey = string.format("%s-%s", name, realm)
  local trackedItems = namespace.WishlistStore.getTrackedItems(db, charKey)

  if not trackedItems or #trackedItems == 0 then
    print("LootWishList: You have no items in your wishlist to test with! Add one from the Adventure Guide first.")
    return
  end

  local randomIndex = math.random(1, #trackedItems)
  local testItem = trackedItems[randomIndex]
  local itemID = testItem.itemID
  local itemLink = testItem.itemLink or
      ("|Hitem:" .. itemID .. "::::::::70:::::|h[" .. (testItem.itemName or "Test Item") .. "]|h")

  local rollID = 999

  -- 1. Create a fresh test frame based on the group loot template
  -- We name it "GroupLootFrame5" because findRollFrameById checks GroupLootFrame 1 through 4 (NUM_GROUP_LOOT_FRAMES)
  local frame = _G["TestLootWishListRollFrame"]
  if not frame then
    frame = CreateFrame("Frame", "TestLootWishListRollFrame", UIParent, "GroupLootFrameTemplate")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

    -- Strip some Native blizzard scripts that might cause errors if triggered with fake data
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnShow", nil)
    frame:SetScript("OnHide", nil)
  end

  -- Force some display properties to ensure it's visible
  frame:SetAlpha(1)
  frame.rollID = rollID

  if frame.IconFrame and frame.IconFrame.Icon then
    local itemIcon = GetItemIcon(itemID) or 134430
    frame.IconFrame.Icon:SetTexture(itemIcon)
  end
  if frame.Name then
    frame.Name:SetText(testItem.itemName or "Test Item")

    local quality = forcedQuality or select(3, GetItemInfo(itemLink)) or 4
    local r, g, b = GetItemQualityColor(quality)
    frame.Name:SetVertexColor(r, g, b)

    if frame.Border then
      frame.Border:SetVertexColor(r, g, b)
    end

    if frame.Background then
      frame.Background:SetVertexColor(r * 0.7, g * 0.7, b * 0.7)
    end

    if frame.IconFrame and frame.IconFrame.Border then
      local atlas = rarityBorderAtlases[quality] or rarityBorderAtlases[2]
      if frame.IconFrame.Border.SetAtlas and atlas then
        frame.IconFrame.Border:SetAtlas(atlas)
      end
      frame.IconFrame.Border:SetVertexColor(1, 1, 1)
    end
  end
  if frame.Timer then
    frame.Timer:SetValue(50) -- Half full timer
  end

  -- Force Greed button instead of Transmog
  if frame.TransmogButton then frame.TransmogButton:Hide() end
  if frame.GreedButton then frame.GreedButton:Show() end

  frame:Show()

  -- 2. Mock WoW API temporarily inside this execution scope
  local original_GetLootRollItemLink = GetLootRollItemLink
  GetLootRollItemLink = function(id)
    if id == rollID then
      return itemLink
    end
    return original_GetLootRollItemLink and original_GetLootRollItemLink(id) or nil
  end

  -- 3. Mock IsTrackedItem temporarily
  local original_IsTrackedItem = namespace.IsTrackedItem
  namespace.IsTrackedItem = function(id) return id == itemID end

  -- 4. Temporary hook into findRollFrameById so our module finds our custom frame
  -- We don't want to modify LootEvents.lua directly just for the test, so we inject the frame globally
  -- and pretend `NUM_GROUP_LOOT_FRAMES` is 5, appending our test frame to `_G`
  local original_NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES
  NUM_GROUP_LOOT_FRAMES = 5
  _G["GroupLootFrame5"] = frame

  -- 5. Invoke the event handler to test the visual rendering
  namespace.LootEvents.HandleStartLootRoll(namespace, rollID)

  -- 6. Restore Original Functions
  GetLootRollItemLink = original_GetLootRollItemLink
  namespace.IsTrackedItem = original_IsTrackedItem
  NUM_GROUP_LOOT_FRAMES = original_NUM_GROUP_LOOT_FRAMES
  _G["GroupLootFrame5"] = nil -- Clean up the global taint

  local displayedQuality = forcedQuality or select(3, GetItemInfo(itemLink)) or 4
  print("LootWishList: Created and showed a template GroupLootFrame for " .. (testItem.itemName or "Test Item") .. " at rarity " .. tostring(displayedQuality) .. "!")
end

SLASH_LWTESTALERT1 = "/testalert"
SlashCmdList["LWTESTALERT"] = function()
  local db = LootWishListDB or { characters = {} }
  local name = UnitName("player") or "Unknown"
  local realm = GetRealmName() or "Unknown"
  local charKey = string.format("%s-%s", name, realm)
  local trackedItems = namespace.WishlistStore.getTrackedItems(db, charKey)

  if not trackedItems or #trackedItems == 0 then
    print("LootWishList: You have no items in your wishlist to test with! Add one from the Adventure Guide first.")
    return
  end

  local randomNames = { "Leo", "Alex", "Jordan", "Sam", "Chris", "Mika", "Robin" }
  local randomName = randomNames[math.random(1, #randomNames)]

  local randomIndex = math.random(1, #trackedItems)
  local testItem = trackedItems[randomIndex]
  local itemID = testItem.itemID
  local itemLink = testItem.itemLink or
      ("|Hitem:" .. itemID .. "::::::::70:::::|h[" .. (testItem.itemName or "Test Item") .. "]|h")

  namespace.ShowLootDialog(randomName, itemLink)
  print("LootWishList: Triggered test alert for " .. randomName .. " looting " .. itemLink)
end

SLASH_LWTESTREFRESH1 = "/testrefresh"
SlashCmdList["LWTESTREFRESH"] = function()
  namespace.RefreshAll()
  print("LootWishList: Triggered RefreshAll()")
end
--@end-do-not-package@
