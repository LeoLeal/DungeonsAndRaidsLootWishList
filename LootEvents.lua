local LootEvents = {}

local function findRollFrameById(rollID)
  local maxFrames = NUM_GROUP_LOOT_FRAMES or 4
  for index = 1, maxFrames do
    local frame = _G["GroupLootFrame" .. index]
    if frame and frame.rollID == rollID then
      return frame
    end
  end

  return nil
end

function LootEvents.HandleStartLootRoll(namespace, rollID)
  if type(GetLootRollItemLink) ~= "function" then
    return
  end

  local itemLink = GetLootRollItemLink(rollID)
  local itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID or not namespace.IsTrackedItem(itemID) then
    return
  end

  local frame = findRollFrameById(rollID)
  if not frame then
    return
  end

  if not frame.LootWishListTag then
    frame.LootWishListTag = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    local font, size, flags = frame.LootWishListTag:GetFont()
    if font and size then
      frame.LootWishListTag:SetFont(font, size - 1, flags)
    end
  end
  frame.LootWishListTag:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -84, -12)
  frame.LootWishListTag:SetText(string.upper(namespace.GetText("WISHLIST")))
  frame.LootWishListTag:Show()
end

local EVENT_PATTERNS = nil
local function getLootPatterns()
  if not EVENT_PATTERNS then
    EVENT_PATTERNS = {}
    local globalStringsToTry = {
      "LOOT_ITEM",
      "LOOT_ITEM_MULTIPLE",
      "LOOT_ITEM_PUSHED",
      "LOOT_ITEM_PUSHED_MULTIPLE",
      "LOOT_ROLL_WON",
    }
    for _, globalName in ipairs(globalStringsToTry) do
      local globalString = _G[globalName]
      if type(globalString) == "string" then
        local p = globalString:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        p = p:gsub("%%%d?%$?[sd]", "(.-)")
        table.insert(EVENT_PATTERNS, "^" .. p .. "$")
      end
    end
  end
  return EVENT_PATTERNS
end

function LootEvents.HandleChatLoot(namespace, message, playerNameEvent)
  if type(message) ~= "string" then
    return
  end

  local playerMatch, itemLink
  for _, pattern in ipairs(getLootPatterns()) do
    local match1, match2 = message:match(pattern)
    if match1 then
      if match1:find("|Hitem:") then
        itemLink = match1
        playerMatch = match2
      elseif match2 and match2:find("|Hitem:") then
        itemLink = match2
        playerMatch = match1
      end
      if itemLink then
        break
      end
    end
  end

  if not itemLink then
    return
  end

  local itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID or not namespace.IsTrackedItem(itemID) then
    return
  end

  local player = (playerMatch and playerMatch ~= "") and playerMatch or playerNameEvent
  player = player and Ambiguate(player, "short") or nil

  local selfName = UnitName("player")
  if player and selfName and player == selfName then
    return
  end

  if player and itemLink then
    namespace.ShowAlert(namespace.GetText("OTHER_PLAYER_LOOTED", player, itemLink))
  else
    namespace.ShowAlert(message)
  end
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.LootEvents = LootEvents
end

return LootEvents
