local _, namespace = ...

local WishlistStore = {}

local function normalizeItemId(itemId)
  if itemId == nil then
    return nil
  end

  return tostring(itemId)
end

local function resolveInventoryType(itemId)
  if itemId == nil or type(GetItemInfoInstant) ~= "function" then
    return nil
  end

  local _, _, _, inventoryType = GetItemInfoInstant(itemId)
  if type(inventoryType) == "string" and inventoryType ~= "" then
    return inventoryType
  end

  return nil
end

function WishlistStore.ensureCharacter(db, characterKey)
  db.characters = db.characters or {}
  db.characters[characterKey] = db.characters[characterKey] or { items = {} }
  db.characters[characterKey].items = db.characters[characterKey].items or {}

  if namespace and namespace.TrackerPreferences then
    namespace.TrackerPreferences.ensureTrackerState(db.characters[characterKey])
  end

  return db.characters[characterKey]
end

function WishlistStore.getItemEntry(db, characterKey, itemId)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return nil
  end

  character.items[itemKey] = character.items[itemKey] or {}
  return character.items[itemKey]
end

function WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return nil
  end

  return character.items[itemKey]
end

function WishlistStore.setTracked(db, characterKey, itemId, tracked)
  if tracked then
    return WishlistStore.getItemEntry(db, characterKey, itemId)
  end

  WishlistStore.removeItem(db, characterKey, itemId)
  return nil
end

function WishlistStore.setItemMetadata(db, characterKey, itemId, metadata)
  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)

  if metadata.encounterID ~= nil then
    entry.encounterID = metadata.encounterID
  end

  if metadata.instanceID ~= nil then
    entry.instanceID = metadata.instanceID
  end

  if metadata.inventoryType ~= nil then
    entry.inventoryType = metadata.inventoryType
  end

  if metadata.selectedVariantRef ~= nil then
    entry.selectedVariantRef = metadata.selectedVariantRef
  end

  if entry.inventoryType == nil then
    entry.inventoryType = resolveInventoryType(itemId)
  end
end

function WishlistStore.isTracked(db, characterKey, itemId)
  return WishlistStore.getExistingItemEntry(db, characterKey, itemId) ~= nil
end

function WishlistStore.removeItem(db, characterKey, itemId)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return
  end

  character.items[itemKey] = nil
end

function WishlistStore.getGroupingMode(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.getGroupingMode(character)
end

function WishlistStore.setGroupingMode(db, characterKey, groupBy)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.setGroupingMode(character, groupBy)
end

function WishlistStore.getTrackerAttachmentMode(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.getAttachmentMode(character)
end

function WishlistStore.setTrackerAttachmentMode(db, characterKey, mode)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.setAttachmentMode(character, mode)
end

function WishlistStore.getTrackerDetachedPosition(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.getDetachedPosition(character)
end

function WishlistStore.setTrackerDetachedPosition(db, characterKey, position)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.setDetachedPosition(character, position)
end

function WishlistStore.isTrackerDetachedLocked(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.isDetachedLocked(character)
end

function WishlistStore.setTrackerDetachedLocked(db, characterKey, locked)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.setDetachedLocked(character, locked)
end

function WishlistStore.toggleTrackerDetachedLocked(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.toggleDetachedLocked(character)
end

function WishlistStore.setGroupCollapsed(db, characterKey, groupBy, groupKey, collapsed)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  namespace.TrackerPreferences.setGroupCollapsed(character, groupBy, groupKey, collapsed)
end

function WishlistStore.isGroupCollapsed(db, characterKey, groupBy, groupKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.isGroupCollapsed(character, groupBy, groupKey)
end

function WishlistStore.toggleGroupCollapse(db, characterKey, groupBy, groupKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return namespace.TrackerPreferences.toggleGroupCollapse(character, groupBy, groupKey)
end

function WishlistStore.getTrackedItems(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local trackedItems = {}

  for itemKey, entry in pairs(character.items) do
    if type(entry) == "table" then
      table.insert(trackedItems, {
        itemID = tonumber(itemKey) or itemKey,
        encounterID = entry.encounterID,
        instanceID = entry.instanceID,
        inventoryType = entry.inventoryType,
        selectedVariantRef = entry.selectedVariantRef,
      })
    end
  end

  table.sort(trackedItems, function(left, right)
    return tostring(left.itemID) < tostring(right.itemID)
  end)

  return trackedItems
end

function WishlistStore.performBackfill(db, characterKey, runtimeNamespace)
  return namespace.WishlistMigration.performBackfill(db, characterKey, runtimeNamespace or namespace)
end

function WishlistStore.repairTrackedMetadata(db, characterKey)
  return namespace.WishlistMigration.repairTrackedMetadata(db, characterKey)
end

function WishlistStore.runMigration(db, runtimeNamespace)
  return namespace.WishlistMigration.runMigration(db, runtimeNamespace or namespace)
end

if type(namespace) == "table" then
  namespace.WishlistStore = WishlistStore
end

return WishlistStore
