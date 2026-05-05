local _, namespace = ...

local ChatLootParser = {}

local EVENT_PATTERNS = nil
local BONUS_LOOT_PATTERNS = nil

local ALERTABLE_LOOT_GLOBAL_NAMES = {
  "LOOT_ITEM",
  "LOOT_ITEM_MULTIPLE",
  "LOOT_ITEM_PUSHED",
  "LOOT_ITEM_PUSHED_MULTIPLE",
  "LOOT_ROLL_WON",
}

local BONUS_LOOT_GLOBAL_NAMES = {
  "LOOT_ITEM_BONUS_ROLL",
  "LOOT_ITEM_BONUS_ROLL_MULTIPLE",
  "LOOT_ITEM_BONUS_ROLL_SELF",
  "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE",
}

local function buildPatternFromGlobalString(globalString)
  local pattern = string.gsub(globalString, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
  return "^" .. string.gsub(pattern, "%%%d?%$?[sd]", "(.-)") .. "$"
end

local function findItemLinkFromPattern(message, pattern)
  local matches = { string.match(message, pattern) }
  for _, match in ipairs(matches) do
    if type(match) == "string" and string.find(match, "|Hitem:", 1, true) then
      return match
    end
  end

  return nil
end

local function getPatterns(globalNames, fallbackPatterns)
  local patterns = {}
  for _, globalName in ipairs(globalNames) do
    local globalString = _G[globalName]
    if type(globalString) == "string" then
      table.insert(patterns, buildPatternFromGlobalString(globalString))
    end
  end

  if type(fallbackPatterns) == "table" then
    for _, fallbackPattern in ipairs(fallbackPatterns) do
      table.insert(patterns, fallbackPattern)
    end
  end

  return patterns
end

local function getLootPatterns()
  if not EVENT_PATTERNS then
    EVENT_PATTERNS = getPatterns(ALERTABLE_LOOT_GLOBAL_NAMES)
  end

  return EVENT_PATTERNS
end

local function getBonusLootPatterns()
  if not BONUS_LOOT_PATTERNS then
    BONUS_LOOT_PATTERNS = getPatterns(BONUS_LOOT_GLOBAL_NAMES, {
      "^.- receives [Bb]onus loot: (.-)%.$",
      "^.- receives [Bb]onus loot: (.-)$",
    })
  end

  return BONUS_LOOT_PATTERNS
end

function ChatLootParser.isReadableLootValue(value)
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

function ChatLootParser.extractItemLinkFromLootMessage(message)
  local lootMessage = ChatLootParser.parseLootMessage(message)
  if lootMessage and lootMessage.alertable ~= false then
    return lootMessage.itemLink
  end

  return nil
end

function ChatLootParser.parseLootMessage(message)
  if not ChatLootParser.isReadableLootValue(message) or message == "" then
    return nil
  end

  for _, pattern in ipairs(getBonusLootPatterns()) do
    local itemLink = findItemLinkFromPattern(message, pattern)
    if itemLink then
      return {
        itemLink = itemLink,
        alertable = false,
        isBonusLoot = true,
      }
    end
  end

  for _, pattern in ipairs(getLootPatterns()) do
    local itemLink = findItemLinkFromPattern(message, pattern)
    if itemLink then
      return {
        itemLink = itemLink,
        alertable = true,
        isBonusLoot = false,
      }
    end
  end

  return nil
end

if type(namespace) == "table" then
  namespace.ChatLootParser = ChatLootParser
end

return ChatLootParser
