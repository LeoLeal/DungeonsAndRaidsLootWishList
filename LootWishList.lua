local ADDON_NAME, namespace = ...

namespace.db = namespace.db or {}
namespace.state = namespace.state or {
  possessed = {},
  bankKnown = false,
}

local eventFrame = CreateFrame("Frame")
namespace.eventFrame = eventFrame

StaticPopupDialogs["LOOT_WISHLIST_ALERT"] = {
  text = "%s",
  button1 = OKAY or "OK",
  hasItemFrame = 1,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

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

local function getCurrentDb()
  LootWishListDB = LootWishListDB or { characters = {} }
  return LootWishListDB
end

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

function namespace.RemoveTrackedItem(itemID)
  namespace.WishlistStore.removeItem(getCurrentDb(), getCharacterKey(), itemID)
  namespace.RefreshAll()
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
    namespace.WishlistStore.setTracked(db, characterKey, normalized.itemID, true)
    namespace.WishlistStore.setItemMetadata(db, characterKey, normalized.itemID, {
      itemName = normalized.itemName,
      itemLink = normalized.itemLink,
      sourceLabel = normalized.instanceName,
      encounterID = normalized.encounterID,
      instanceID = normalized.instanceID,
    })
  else
    namespace.WishlistStore.removeItem(db, characterKey, normalized.itemID)
  end

  namespace.RefreshAll()
end

function namespace.RefreshPossessionState()
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
    if highestLevels[key] then
      namespace.WishlistStore.updateBestLootedItemLevel(getCurrentDb(), getCharacterKey(), item.itemID,
        highestLevels[key])
    end
  end
end

local raidInstances = {}
local function isRaidInstance(instanceID)
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
local function getEncounterRank(encounterID, instanceID)
  if not encounterID or not instanceID then return 999 end
  if not instanceEncounterRanks[instanceID] then
    instanceEncounterRanks[instanceID] = {}
    if type(EJ_SelectInstance) == "function" and type(EJ_GetEncounterInfoByIndex) == "function" then
      EJ_SelectInstance(instanceID)
      local e = 1
      while true do
        local _, _, eid = EJ_GetEncounterInfoByIndex(e)
        if not eid then break end
        instanceEncounterRanks[instanceID][eid] = e
        e = e + 1
      end
    end
  end
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

function namespace.BuildTrackerGroups()
  local trackedItems = namespace.WishlistStore.getTrackedItems(getCurrentDb(), getCharacterKey())
  local renderItems = {}
  local bestOwnedLinks = namespace.state.bestOwnedLinks or {}

  for _, item in ipairs(trackedItems) do
    local key = namespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
    local itemName = item.itemName or GetItemInfo(item.itemID) or item.itemLink or ("Item " .. tostring(item.itemID))
    local groupLabel = namespace.SourceResolver.getGroupLabel({
      instanceName = item.sourceLabel,
      currentInstanceName = namespace.GetCurrentSourceLabel(nil),
    })
    local bestOwnedLink = bestOwnedLinks[key]
    local tooltipRef = namespace.ItemResolver.getTooltipRef({
      itemLink = item.itemLink,
      itemID = item.itemID,
    })
    local displayLink = bestOwnedLink or item.itemLink

    local bossName = resolveBossName(item.encounterID, item.instanceID)
    local bossRank = bossName and getEncounterRank(item.encounterID, item.instanceID) or nil

    table.insert(renderItems, {
      itemID = item.itemID,
      itemName = itemName,
      groupLabel = groupLabel,
      isPossessed = namespace.state.possessed[key] == true,
      bestLootedItemLevel = item.bestLootedItemLevel,
      bossName = bossName,
      bossRank = bossRank,
      tooltipRef = tooltipRef,
      displayLink = displayLink,
    })
  end

  return namespace.TrackerModel.buildGroups(renderItems, namespace.GetText("OTHER"))
end

function namespace.ShowLootDialog(playerName, itemLink)
  if type(StaticPopup_Show) == "function" then
    -- Format message text: white body, orange player name with padding newlines
    -- \194\160 is the UTF-8 non-breaking space, which prevents WoW from trimming/collapsing the spaces
    local message = string.format(
      "|n\194\160\194\160" ..
      (namespace.GetText("PLAYER_LOOTED_WISHLIST_ITEM") or "|cFFFFFFFF%s|r looted an item on your Loot Wishlist!") ..
      "\194\160\194\160|n|n",
      "|cffffcc00" .. playerName .. "|cFFFFFFFF"
    )

    local data = {
      link = itemLink,
      useLinkForItemInfo = true
    }

    StaticPopup_Show("LOOT_WISHLIST_ALERT", message, nil, data)
  end
end

function namespace.RefreshTracker()
  namespace.TrackerUI.Refresh(namespace, namespace.BuildTrackerGroups())
end

function namespace.RefreshAll()
  namespace.RefreshPossessionState()
  namespace.RefreshTracker()
  if namespace.AdventureGuideUI then
    namespace.AdventureGuideUI.Refresh(namespace)
  end
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
    namespace.TrackerUI.Initialize(namespace)
    namespace.AdventureGuideUI.Initialize(namespace)
    registerEvents()
    namespace.RefreshAll()
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
    namespace.RefreshAll()
    return
  end

  if event == "BANKFRAME_CLOSED" then
    namespace.RefreshAll()
    return
  end

  if event == "PLAYER_REGEN_ENABLED" then
    -- Player left combat - refresh to catch any deferred updates
    namespace.RefreshAll()
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
SlashCmdList["LWTESTROLL"] = function()
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

    local quality = select(3, GetItemInfo(itemLink)) or 4
    local r, g, b = GetItemQualityColor(quality)
    frame.Name:SetVertexColor(r, g, b)
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

  print("LootWishList: Created and showed a template GroupLootFrame for " .. (testItem.itemName or "Test Item") .. "!")
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
--@end-do-not-package@
