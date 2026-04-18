local _, namespace = ...

local WishlistTags = {}

local function copyList(values)
  local copy = {}
  if type(values) ~= "table" then
    return copy
  end

  for index, value in ipairs(values) do
    copy[index] = value
  end

  return copy
end

local function resolveItemId(itemOrItemID)
  if type(itemOrItemID) == "table" then
    return itemOrItemID.itemID
  end

  return itemOrItemID
end

function WishlistTags.getOrderedCatalogTags(runtimeNamespace)
  if not runtimeNamespace or type(runtimeNamespace.WishlistStore) ~= "table" then
    return {}
  end

  return copyList(runtimeNamespace.WishlistStore.getOrderedTags(
    runtimeNamespace.GetCurrentDb(),
    runtimeNamespace.GetCharacterKey()
  ))
end

function WishlistTags.getUsedTags(runtimeNamespace)
  if not runtimeNamespace or type(runtimeNamespace.WishlistStore) ~= "table" then
    return {}
  end

  return copyList(runtimeNamespace.WishlistStore.getUsedTags(
    runtimeNamespace.GetCurrentDb(),
    runtimeNamespace.GetCharacterKey()
  ))
end

function WishlistTags.getOrderedAssignedTags(runtimeNamespace, itemOrItemID)
  if not runtimeNamespace or type(runtimeNamespace.WishlistStore) ~= "table" then
    return {}
  end

  local itemID = resolveItemId(itemOrItemID)
  if itemID == nil then
    return {}
  end

  return copyList(runtimeNamespace.WishlistStore.getOrderedItemTags(
    runtimeNamespace.GetCurrentDb(),
    runtimeNamespace.GetCharacterKey(),
    itemID
  ))
end

function WishlistTags.formatTagList(tags)
  if type(tags) ~= "table" or #tags == 0 then
    return ""
  end

  return table.concat(tags, ", ")
end

if type(namespace) == "table" then
  namespace.WishlistTags = WishlistTags
end

return WishlistTags
