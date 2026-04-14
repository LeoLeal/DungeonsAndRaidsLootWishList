local _, namespace = ...

local LootEventHandlers = {}

function LootEventHandlers.HandleStartLootRoll(runtimeNamespace, rollID)
  runtimeNamespace.RollBadgeView.ShowForRoll(runtimeNamespace, rollID)
end

function LootEventHandlers.HandleChatLoot(runtimeNamespace, message, playerNameEvent)
  if not runtimeNamespace.ChatLootParser.isReadableLootValue(playerNameEvent) then
    return
  end

  if not runtimeNamespace.ChatLootParser.isReadableLootValue(message) then
    return
  end

  local itemLink = runtimeNamespace.ChatLootParser.extractItemLinkFromLootMessage(message)
  local itemID = runtimeNamespace.LootMatcher.matchTrackedItem(runtimeNamespace, itemLink)
  if not itemID then
    return
  end

  if type(runtimeNamespace.WasRecentSelfLoot) == "function" and runtimeNamespace.WasRecentSelfLoot(itemID) then
    return
  end

  local alertRecord = runtimeNamespace.LootAwareness.BuildAlertRecord(runtimeNamespace, itemID, playerNameEvent, itemLink)
  if alertRecord then
    runtimeNamespace.LootAwareness.QueueAlert(runtimeNamespace, alertRecord)
  end
end

if type(namespace) == "table" then
  namespace.LootEventHandlers = LootEventHandlers
end

return LootEventHandlers
