local ItemResolver = {}

local function trimHyperlinkPayload(itemRef)
  if type(itemRef) ~= "string" then
    return nil
  end

  local hyperlink = itemRef:match("|H([^|]+)|h")
  if type(hyperlink) == "string" and hyperlink ~= "" then
    return hyperlink
  end

  if itemRef:match("^item:") then
    return itemRef
  end

  return nil
end

function ItemResolver.getWishlistKey(itemData)
  if itemData == nil then
    return nil
  end

  local itemId = itemData.itemID or itemData.itemId or itemData.id
  if itemId == nil then
    return nil
  end

  return "item:" .. tostring(itemId)
end

function ItemResolver.getItemIdFromLink(itemLink)
  local itemRef = trimHyperlinkPayload(itemLink)
  if type(itemRef) ~= "string" then
    return nil
  end

  local itemId = string.match(itemRef, "item:(%d+)")
  if itemId == nil then
    return nil
  end

  return tonumber(itemId)
end

function ItemResolver.getVariantRef(itemRef)
  return trimHyperlinkPayload(itemRef)
end

function ItemResolver.normalizeItemData(itemData)
  if itemData == nil then
    return nil
  end

  local itemId = itemData.itemID or itemData.itemId or ItemResolver.getItemIdFromLink(itemData.itemLink)
  if itemId == nil then
    return nil
  end

  local inventoryType = itemData.inventoryType or itemData.invType or itemData.equipLoc
  if (type(inventoryType) ~= "string" or inventoryType == "") and type(GetItemInfoInstant) == "function" then
    local _, _, _, resolvedInventoryType = GetItemInfoInstant(itemId)
    inventoryType = resolvedInventoryType
  end

  return {
    itemID = itemId,
    wishlistKey = ItemResolver.getWishlistKey({ itemID = itemId }),
    itemLink = itemData.itemLink,
    selectedVariantRef = ItemResolver.getVariantRef(itemData.selectedVariantRef or itemData.itemLink),
    itemName = itemData.itemName,
    itemLevel = itemData.itemLevel,
    instanceName = itemData.instanceName,
    encounterID = itemData.encounterID or itemData.bossID,
    instanceID = itemData.instanceID,
    inventoryType = inventoryType,
  }
end

function ItemResolver.getTooltipRef(item)
  if item == nil then
    return nil
  end

  local selectedVariantRef = ItemResolver.getVariantRef(item.selectedVariantRef)
  if selectedVariantRef then
    return selectedVariantRef
  end

  local itemLink = ItemResolver.getVariantRef(item.itemLink)
  if itemLink then
    return itemLink
  end

  local itemId = item.itemID or item.itemId or item.id
  if itemId ~= nil then
    return "item:" .. tostring(itemId)
  end

  return nil
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.ItemResolver = ItemResolver
end

return ItemResolver
