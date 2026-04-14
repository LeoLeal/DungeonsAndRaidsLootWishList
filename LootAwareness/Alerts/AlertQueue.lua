local _, namespace = ...

local AlertQueue = {}

function AlertQueue.Flush(runtimeNamespace)
  local dialog = runtimeNamespace.LootAlertDialog
  if dialog and dialog.IsShown and dialog.IsShown() then
    runtimeNamespace.state.lootAlertFlushQueued = false
    return
  end

  local pendingLootAlerts = runtimeNamespace.state.pendingLootAlerts or {}
  runtimeNamespace.state.lootAlertFlushQueued = false

  if #pendingLootAlerts == 0 then
    return
  end

  local alertRecord = table.remove(pendingLootAlerts, 1)
  runtimeNamespace.state.pendingLootAlerts = pendingLootAlerts
  runtimeNamespace.AlertPresenter.ShowFromRecord(runtimeNamespace, alertRecord)
end

function AlertQueue.Enqueue(runtimeNamespace, alertRecord)
  if type(alertRecord) ~= "table" then
    return
  end

  local pendingLootAlerts = runtimeNamespace.state.pendingLootAlerts or {}
  runtimeNamespace.state.pendingLootAlerts = pendingLootAlerts
  table.insert(pendingLootAlerts, alertRecord)

  if runtimeNamespace.state.lootAlertFlushQueued then
    return
  end

  runtimeNamespace.state.lootAlertFlushQueued = true
  runtimeNamespace.QueueAfterCombat(function()
    AlertQueue.Flush(runtimeNamespace)
  end)
end

if type(namespace) == "table" then
  namespace.AlertQueue = AlertQueue
end

return AlertQueue
