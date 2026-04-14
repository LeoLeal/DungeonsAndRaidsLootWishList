local _, namespace = ...

local ChatLootParser = {}

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
        local pattern = string.gsub(globalString, "([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1")
        pattern = string.gsub(pattern, "%%%d?%$?[sd]", "(.-)")
        table.insert(EVENT_PATTERNS, "^" .. pattern .. "$")
      end
    end
  end

  return EVENT_PATTERNS
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
  if not ChatLootParser.isReadableLootValue(message) or message == "" then
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

if type(namespace) == "table" then
  namespace.ChatLootParser = ChatLootParser
end

return ChatLootParser
