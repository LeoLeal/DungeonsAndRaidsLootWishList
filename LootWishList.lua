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

    table.insert(renderItems, {
      itemID = item.itemID,
      itemName = itemName,
      groupLabel = groupLabel,
      isPossessed = namespace.state.possessed[key] == true,
      bestLootedItemLevel = item.bestLootedItemLevel,
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
      "|cFFFF8000" .. playerName .. "|cFFFFFFFF"
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
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    namespace.db = getCurrentDb()
    namespace.TrackerUI.Initialize(namespace)
    namespace.AdventureGuideUI.Initialize(namespace)
    registerEvents()
    namespace.RefreshAll()
    return
  end

  if event == "CHAT_MSG_LOOT" then
    namespace.LootEvents.HandleChatLoot(namespace, ...)
    namespace.RefreshAll()
    return
  end

  if event == "START_LOOT_ROLL" then
    namespace.LootEvents.HandleStartLootRoll(namespace, ...)
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

  namespace.RefreshAll()
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
