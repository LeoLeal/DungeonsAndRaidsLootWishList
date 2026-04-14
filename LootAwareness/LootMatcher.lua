local _, namespace = ...

local LootMatcher = {}

function LootMatcher.matchTrackedItem(runtimeNamespace, itemLink)
  local itemID = itemLink and runtimeNamespace.ItemResolver.getItemIdFromLink(itemLink) or nil
  if not itemID or not runtimeNamespace.IsTrackedItem(itemID) then
    return nil
  end

  return itemID
end

if type(namespace) == "table" then
  namespace.LootMatcher = LootMatcher
end

return LootMatcher
