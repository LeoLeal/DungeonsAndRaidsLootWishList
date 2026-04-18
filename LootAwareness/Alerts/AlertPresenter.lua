local _, namespace = ...

local AlertPresenter = {}

function AlertPresenter.BuildLootAlertRecord(runtimeNamespace, itemID, playerName, itemLink)
  if type(itemID) ~= "number" or type(playerName) ~= "string" or type(itemLink) ~= "string" or itemLink == "" then
    return nil
  end

  local entry = runtimeNamespace.WishlistStore.getExistingItemEntry(runtimeNamespace.GetCurrentDb(), runtimeNamespace.GetCharacterKey(), itemID)
  if not entry then
    return nil
  end

  return {
    itemID = itemID,
    itemName = runtimeNamespace.GetItemInfoName(itemID),
    itemLink = itemLink,
    playerName = playerName,
    tags = runtimeNamespace.GetOrderedAssignedTags(itemID),
  }
end

function AlertPresenter.ShowFromRecord(runtimeNamespace, record)
  if runtimeNamespace.LootAlertDialog and runtimeNamespace.LootAlertDialog.ShowFromRecord then
    runtimeNamespace.LootAlertDialog.ShowFromRecord(runtimeNamespace, record)
  end
end

if type(namespace) == "table" then
  namespace.AlertPresenter = AlertPresenter
end

return AlertPresenter
