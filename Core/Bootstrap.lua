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

local TRACK_INFO_REFRESH_MAX_ATTEMPTS = 3

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

namespace.GetCurrentDb = getCurrentDb
namespace.GetCharacterKey = getCharacterKey

function namespace.MarkRecentSelfLoot(itemID)
  return namespace.RecentSelfLoot.Mark(namespace, itemID)
end

function namespace.WasRecentSelfLoot(itemID)
  return namespace.RecentSelfLoot.WasRecent(namespace, itemID)
end

local function getTrackerGroupingMode()
  return namespace.WishlistStore.getGroupingMode(getCurrentDb(), getCharacterKey())
end

local function getItemInfoName(itemRefOrItemID)
  if type(GetItemInfo) ~= "function" then
    return nil
  end

  local itemName = GetItemInfo(itemRefOrItemID)
  if type(itemName) == "string" and itemName ~= "" then
    return itemName
  end

  return nil
end

namespace.GetItemInfoName = getItemInfoName

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

function namespace.GetTrackerAttachmentMode()
  return namespace.WishlistStore.getTrackerAttachmentMode(getCurrentDb(), getCharacterKey())
end

function namespace.SetTrackerAttachmentMode(mode)
  local attachmentMode = namespace.WishlistStore.setTrackerAttachmentMode(getCurrentDb(), getCharacterKey(), mode)
  namespace.RefreshTracker()
  return attachmentMode
end

function namespace.GetTrackerDetachedPosition()
  return namespace.WishlistStore.getTrackerDetachedPosition(getCurrentDb(), getCharacterKey())
end

function namespace.SetTrackerDetachedPosition(position)
  return namespace.WishlistStore.setTrackerDetachedPosition(getCurrentDb(), getCharacterKey(), position)
end

function namespace.IsTrackerDetachedLocked()
  return namespace.WishlistStore.isTrackerDetachedLocked(getCurrentDb(), getCharacterKey())
end

function namespace.SetTrackerDetachedLocked(locked)
  local isLocked = namespace.WishlistStore.setTrackerDetachedLocked(getCurrentDb(), getCharacterKey(), locked)
  namespace.RefreshTracker()
  return isLocked
end

function namespace.ToggleTrackerDetachedLocked()
  local isLocked = namespace.WishlistStore.toggleTrackerDetachedLocked(getCurrentDb(), getCharacterKey())
  namespace.RefreshTracker()
  return isLocked
end

function namespace.RemoveTrackedItem(itemID)
  namespace.WishlistStore.removeItem(getCurrentDb(), getCharacterKey(), itemID)
  namespace.RefreshAllImmediate()
  namespace.AdventureGuide.Refresh(namespace)
end

local function extractTooltipLineText(lineData)
  if type(lineData) ~= "table" then
    return nil
  end

  local candidates = {
    lineData.leftText,
    lineData.text,
    lineData.rightText,
  }

  for _, value in ipairs(candidates) do
    if type(value) == "string" and value ~= "" then
      return value
    end
  end

  return nil
end

local function getItemTrackCache()
  namespace.state.itemTrackCache = namespace.state.itemTrackCache or {}
  return namespace.state.itemTrackCache
end

local function getPendingItemTrackRefreshes()
  namespace.state.pendingItemTrackRefreshes = namespace.state.pendingItemTrackRefreshes or {}
  return namespace.state.pendingItemTrackRefreshes
end

local function schedulePendingTrackRefresh(itemRef)
  if type(itemRef) ~= "string" or itemRef == "" then
    return
  end

  local pending = getPendingItemTrackRefreshes()
  local current = pending[itemRef] or { attempts = 0 }
  if current.attempts >= TRACK_INFO_REFRESH_MAX_ATTEMPTS then
    return
  end

  current.attempts = current.attempts + 1
  pending[itemRef] = current
  namespace.state.hasPendingItemTrackRefresh = true
end

local function extractItemTrackFromTooltipData(tooltipData)
  if type(tooltipData) ~= "table" then
    return nil
  end

  local targetLineType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemUpgradeLevel or nil
  local lines = tooltipData.lines or tooltipData.tooltipDataLines
  if type(lines) ~= "table" then
    return nil
  end

  for _, lineData in ipairs(lines) do
    local lineType = type(lineData) == "table" and (lineData.type or lineData.lineType) or nil
    if targetLineType == nil or lineType == targetLineType then
      local lineText = extractTooltipLineText(lineData)
      if lineText then
        return lineText
      end
    end
  end

  return nil
end

local function trimItemTrackLabel(itemTrack)
  if type(itemTrack) ~= "string" then
    return nil
  end

  local trimmed = itemTrack:match("^%s*(.-)%s*$")
  if trimmed == "" then
    return nil
  end

  trimmed = trimmed:gsub("^.-:%s*", "")
  trimmed = trimmed:gsub("%s+%d+/%d+%s*$", "")
  trimmed = trimmed:match("^%s*(.-)%s*$")

  if trimmed == "" then
    return nil
  end

  return trimmed
end

local function getLocalizedItemTrack(itemRef)
  local normalizedRef = namespace.ItemResolver.getTooltipRef({ selectedVariantRef = itemRef })
  if type(normalizedRef) ~= "string" then
    return nil
  end

  local cache = getItemTrackCache()
  local cached = cache[normalizedRef]
  if cached ~= nil then
    return cached ~= false and cached or nil
  end

  if type(C_TooltipInfo) ~= "table" or type(C_TooltipInfo.GetHyperlink) ~= "function" then
    return nil
  end

  local tooltipData = C_TooltipInfo.GetHyperlink(normalizedRef)
  local itemTrack = trimItemTrackLabel(extractItemTrackFromTooltipData(tooltipData))
  if itemTrack then
    cache[normalizedRef] = itemTrack
    return itemTrack
  end

  cache[normalizedRef] = false
  schedulePendingTrackRefresh(normalizedRef)
  return nil
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
      encounterID = normalized.encounterID,
      instanceID = normalized.instanceID,
      inventoryType = normalized.inventoryType,
      selectedVariantRef = normalized.selectedVariantRef,
    })
    if normalized.instanceID then
      namespace.Tracker.PrimeEncounterDataForInstance(namespace, normalized.instanceID)
    end
  else
    namespace.WishlistStore.removeItem(db, characterKey, normalized.itemID)
  end

  namespace.RefreshAllImmediate()
  namespace.AdventureGuide.Refresh(namespace)
end

function namespace.RefreshTracker()
  return namespace.Tracker.RefreshState(namespace)
end

-- Internal function that does the actual refresh work
local function doRefreshAll()
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

local Bootstrap = {}

function Bootstrap.RegisterEvents(runtimeNamespace)
  local trackedEventFrame = runtimeNamespace.eventFrame
  if not trackedEventFrame then
    return
  end

  trackedEventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
  trackedEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  trackedEventFrame:RegisterEvent("CHAT_MSG_LOOT")
  trackedEventFrame:RegisterEvent("START_LOOT_ROLL")
  trackedEventFrame:RegisterEvent("BANKFRAME_OPENED")
  trackedEventFrame:RegisterEvent("BANKFRAME_CLOSED")
  trackedEventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
  trackedEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
  trackedEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  trackedEventFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
  trackedEventFrame:RegisterEvent("TOOLTIP_DATA_UPDATE")
end

function Bootstrap.HandleEvent(runtimeNamespace, event, ...)
  if event == "PLAYER_LOGIN" then
    runtimeNamespace.db = runtimeNamespace.GetCurrentDb()
    runtimeNamespace.WishlistStore.runMigration(runtimeNamespace.db, runtimeNamespace)
    runtimeNamespace.WishlistStore.repairTrackedMetadata(runtimeNamespace.db, runtimeNamespace.GetCharacterKey(), runtimeNamespace)
    runtimeNamespace.Tracker.PrimeTrackedEncounterData(runtimeNamespace)
    runtimeNamespace.Tracker.Initialize(runtimeNamespace)
    runtimeNamespace.AdventureGuide.Initialize(runtimeNamespace)
    Bootstrap.RegisterEvents(runtimeNamespace)
    runtimeNamespace.RefreshAllImmediate()
    return true
  end

  if event == "CHAT_MSG_LOOT" then
    runtimeNamespace.LootAwareness.HandleChatLoot(runtimeNamespace, ...)
    if not InCombatLockdown() then
      runtimeNamespace.RefreshAll()
    else
      runtimeNamespace.QueueAfterCombat(function()
        runtimeNamespace.RefreshAll()
      end)
    end
    return true
  end

  if event == "START_LOOT_ROLL" then
    local rollID = ...
    if not InCombatLockdown() then
      runtimeNamespace.LootAwareness.HandleStartLootRoll(runtimeNamespace, rollID)
    else
      runtimeNamespace.QueueAfterCombat(function()
        runtimeNamespace.LootAwareness.HandleStartLootRoll(runtimeNamespace, rollID)
      end)
    end
    return true
  end

  if event == "BANKFRAME_OPENED" then
    runtimeNamespace.state.bankKnown = true
    runtimeNamespace.RefreshAllImmediate()
    return true
  end

  if event == "BANKFRAME_CLOSED" then
    runtimeNamespace.RefreshAll()
    return true
  end

  if event == "PLAYER_REGEN_ENABLED" then
    runtimeNamespace.RefreshAllImmediate()
    return true
  end

  if event == "TOOLTIP_DATA_UPDATE" then
    if not runtimeNamespace.state.hasPendingItemTrackRefresh then
      return true
    end

    local pending = getPendingItemTrackRefreshes()
    local cache = getItemTrackCache()
    local hasRemaining = false

    for itemRef, pendingState in pairs(pending) do
      cache[itemRef] = nil
      local itemTrack = getLocalizedItemTrack(itemRef)
      if itemTrack then
        pending[itemRef] = nil
      elseif pendingState and pendingState.attempts < TRACK_INFO_REFRESH_MAX_ATTEMPTS then
        hasRemaining = true
      else
        pending[itemRef] = nil
      end
    end

    runtimeNamespace.state.hasPendingItemTrackRefresh = hasRemaining and next(pending) ~= nil or false
    runtimeNamespace.RefreshAll()
    return true
  end

  if event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
    runtimeNamespace.Tracker.RequestPostTransitionResync(runtimeNamespace)
  end

  if not InCombatLockdown() then
    runtimeNamespace.RefreshAll()
  end

  return true
end

function Bootstrap.Install(runtimeNamespace)
  local trackedEventFrame = runtimeNamespace.eventFrame
  if not trackedEventFrame then
    return
  end

  trackedEventFrame:SetScript("OnEvent", function(_, event, ...)
    Bootstrap.HandleEvent(runtimeNamespace, event, ...)
  end)
  trackedEventFrame:RegisterEvent("PLAYER_LOGIN")
end

Bootstrap.Install(namespace)


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

  -- 4. Temporary hook into roll frame lookup so our module finds our custom frame
  -- and pretend `NUM_GROUP_LOOT_FRAMES` is 5, appending our test frame to `_G`
  local original_NUM_GROUP_LOOT_FRAMES = NUM_GROUP_LOOT_FRAMES
  NUM_GROUP_LOOT_FRAMES = 5
  _G["GroupLootFrame5"] = frame

  -- 5. Invoke the event handler to test the visual rendering
  namespace.LootAwareness.HandleStartLootRoll(namespace, rollID)

  -- 6. Restore Original Functions
  GetLootRollItemLink = original_GetLootRollItemLink
  namespace.IsTrackedItem = original_IsTrackedItem
  NUM_GROUP_LOOT_FRAMES = original_NUM_GROUP_LOOT_FRAMES
  _G["GroupLootFrame5"] = nil -- Clean up the global taint

  local displayedQuality = forcedQuality or select(3, GetItemInfo(itemLink)) or 4
  print("LootWishList: Created and showed a template GroupLootFrame for " ..
    (testItem.itemName or "Test Item") .. " at rarity " .. tostring(displayedQuality) .. "!")
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
  local itemLink = namespace.Tracker.ResolveEffectiveDisplayLink(namespace, testItem)
  if type(GetItemInfo) == "function" then
    itemLink = select(2, GetItemInfo(itemLink)) or select(2, GetItemInfo(itemID)) or itemLink
  end

  local alertRecord = namespace.LootAwareness.BuildAlertRecord(namespace, itemID, randomName, itemLink)
  if not alertRecord then
    print("LootWishList: Unable to build a valid test alert record for item " .. tostring(itemID))
    return
  end

  namespace.LootAwareness.ShowAlertFromRecord(namespace, alertRecord)
  print("LootWishList: Triggered test alert for " .. randomName .. " looting " .. itemLink)
end

SLASH_LWTESTREFRESH1 = "/testrefresh"
SlashCmdList["LWTESTREFRESH"] = function()
  namespace.RefreshAll()
  print("LootWishList: Triggered RefreshAll()")
end
--@end-do-not-package@
