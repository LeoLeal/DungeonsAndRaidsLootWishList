local _, namespace = ...

local LootAwareness = {}

function LootAwareness.Initialize(runtimeNamespace)
  if runtimeNamespace and runtimeNamespace.RollBadgeLifecycle then
    runtimeNamespace.RollBadgeLifecycle.Initialize(runtimeNamespace)
  end
end

function LootAwareness.BuildAlertRecord(runtimeNamespace, ...)
  return runtimeNamespace.AlertPresenter.BuildLootAlertRecord(runtimeNamespace, ...)
end

function LootAwareness.QueueAlert(runtimeNamespace, ...)
  return runtimeNamespace.AlertQueue.Enqueue(runtimeNamespace, ...)
end

function LootAwareness.FlushAlerts(runtimeNamespace, ...)
  return runtimeNamespace.AlertQueue.Flush(runtimeNamespace, ...)
end

function LootAwareness.ShowAlertFromRecord(runtimeNamespace, ...)
  return runtimeNamespace.AlertPresenter.ShowFromRecord(runtimeNamespace, ...)
end

function LootAwareness.HandleChatLoot(runtimeNamespace, ...)
  return runtimeNamespace.LootEventHandlers.HandleChatLoot(runtimeNamespace, ...)
end

function LootAwareness.HandleStartLootRoll(runtimeNamespace, ...)
  return runtimeNamespace.LootEventHandlers.HandleStartLootRoll(runtimeNamespace, ...)
end

if type(namespace) == "table" then
  namespace.LootAwareness = LootAwareness
end

return LootAwareness
