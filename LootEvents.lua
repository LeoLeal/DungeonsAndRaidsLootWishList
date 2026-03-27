local LootEvents = {}

local LOOT_ROLL_BADGE_ICON_ATLAS = "Banker"
local LOOT_ROLL_BADGE_ICON_SIZE = 18
local LOOT_ROLL_BADGE_GAP = 2
local LOOT_ROLL_BADGE_SIDE_PADDING = 40
local LOOT_ROLL_BADGE_GLOW_PAD_X = 120
local LOOT_ROLL_BADGE_GLOW_PAD_Y = 16

local function hideRollBadge(frame)
  if frame and frame.LootWishListBadge then
    frame.LootWishListBadge:Hide()
  end
end

local function ensureRollBadge(frame)
  if not frame then
    return nil
  end

  if frame.LootWishListBadge then
    return frame.LootWishListBadge
  end

  local badge = CreateFrame("Frame", nil, frame)
  badge:SetHeight(LOOT_ROLL_BADGE_ICON_SIZE)

  badge.glow = badge:CreateTexture(nil, "BACKGROUND")
  badge.glow:SetAtlas("pvpscoreboard-header-glow", false)
  badge.glow:SetBlendMode("ADD")
  badge.glow:SetVertexColor(1, 1, 1, 1)
  badge.glow:SetPoint("TOPLEFT", badge, "TOPLEFT", -LOOT_ROLL_BADGE_GLOW_PAD_X, LOOT_ROLL_BADGE_GLOW_PAD_Y + 14)
  badge.glow:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", LOOT_ROLL_BADGE_GLOW_PAD_X, -LOOT_ROLL_BADGE_GLOW_PAD_Y)

  badge.icon = badge:CreateTexture(nil, "OVERLAY")
  badge.icon:SetSize(LOOT_ROLL_BADGE_ICON_SIZE, LOOT_ROLL_BADGE_ICON_SIZE)
  badge.icon:SetAtlas(LOOT_ROLL_BADGE_ICON_ATLAS, false)
  badge.icon:SetPoint("LEFT", badge, "LEFT", LOOT_ROLL_BADGE_SIDE_PADDING, 0)

  badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local font, size = badge.text:GetFont()
  if font and size then
    badge.text:SetFont(font, size, "OUTLINE")
  end
  badge.text:SetShadowColor(0, 0, 0, 1)
  badge.text:SetShadowOffset(1, -1)
  badge.text:SetTextColor(1, 0.82, 0)
  badge.text:SetPoint("LEFT", badge.icon, "RIGHT", LOOT_ROLL_BADGE_GAP, 0)

  frame.LootWishListBadge = badge
  frame.LootWishListTag = badge.text
  return badge
end

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
  local frame = findRollFrameById(rollID)
  if not frame then
    return
  end

  if type(GetLootRollItemLink) ~= "function" then
    hideRollBadge(frame)
    return
  end

  local itemLink = GetLootRollItemLink(rollID)
  local itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID or not namespace.IsTrackedItem(itemID) then
    hideRollBadge(frame)
    return
  end

  local badge = ensureRollBadge(frame)
  if not badge then
    return
  end

  badge.text:SetText(namespace.GetText("WISHLIST"))
  badge:SetWidth((LOOT_ROLL_BADGE_SIDE_PADDING * 2) + LOOT_ROLL_BADGE_ICON_SIZE + LOOT_ROLL_BADGE_GAP +
    badge.text:GetStringWidth())
  badge:ClearAllPoints()
  badge:SetPoint("TOP", frame, "TOP", 0, 12)
  badge:Show()
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
        local p = string.gsub(globalString, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        p = string.gsub(p, "%%%d?%$?[sd]", "(.-)")
        table.insert(EVENT_PATTERNS, "^" .. p .. "$")
      end
    end
  end
  return EVENT_PATTERNS
end

local function isReadableLootValue(value)
  if value == nil then
    return false
  end

  if type(canaccessvalue) == "function" and canaccessvalue(value) ~= true then
    return false
  end

  if type(issecretvalue) == "function" and issecretvalue(value) == true then
    return false
  end

  return type(value) == "string"
end

local function extractItemLinkFromLootMessage(message)
  if not isReadableLootValue(message) then
    return nil
  end

  if message == "" then
    return nil
  end

  for _, pattern in ipairs(getLootPatterns()) do
    local match1, match2 = string.match(message, pattern)
    if type(match1) == "string" and string.find(match1, "|Hitem:", 1, true) then
      return match1
    end
    if type(match2) == "string" and string.find(match2, "|Hitem:", 1, true) then
      return match2
    end
  end

  return nil
end

function LootEvents.HandleChatLoot(namespace, message, playerNameEvent)
  if not isReadableLootValue(playerNameEvent) then
    return
  end

  if not isReadableLootValue(message) then
    return
  end

  local itemLink = extractItemLinkFromLootMessage(message)

  local itemID = nil
  if itemLink then
    itemID = namespace.ItemResolver.getItemIdFromLink(itemLink)
  end
  if not itemID or not namespace.IsTrackedItem(itemID) then
    return
  end

  if type(namespace.WasRecentSelfLoot) == "function" and namespace.WasRecentSelfLoot(itemID) then
    return
  end

  local alertRecord = namespace.BuildLootAlertRecord(itemID, playerNameEvent, itemLink)
  if alertRecord then
    namespace.QueueLootAlert(alertRecord)
  end
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.LootEvents = LootEvents
end

return LootEvents
