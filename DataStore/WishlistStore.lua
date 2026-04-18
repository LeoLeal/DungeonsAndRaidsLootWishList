local _, namespace = ...

local WishlistStore = {}

local function normalizeItemId(itemId)
  if itemId == nil then
    return nil
  end

  return tostring(itemId)
end

local function trimTagLabel(label)
  if type(label) ~= "string" then
    return nil
  end

  local trimmed = label:match("^%s*(.-)%s*$")
  if trimmed == "" then
    return nil
  end

  return trimmed
end

local function normalizeTagLabel(label)
  local trimmed = trimTagLabel(label)
  if not trimmed then
    return nil
  end

  return string.lower(trimmed)
end

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

local function resolveDefaultTagLabel()
  if namespace and type(namespace.GetText) == "function" then
    local localized = trimTagLabel(namespace.GetText("DEFAULT_WISHLIST_TAG"))
    if localized then
      return localized
    end
  end

  return "Best in slot"
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

local function ensureTagCatalog(character)
  character.tags = type(character.tags) == "table" and character.tags or {}
  if #character.tags == 0 then
    table.insert(character.tags, resolveDefaultTagLabel())
  end

  return character.tags
end

local function ensureCharacterState(character)
  character.items = type(character.items) == "table" and character.items or {}
  ensureTagCatalog(character)

  if namespace and namespace.TrackerPreferences then
    namespace.TrackerPreferences.ensureTrackerState(character)
  end

  return character
end

local function findCatalogTag(character, tagLabel)
  local normalized = normalizeTagLabel(tagLabel)
  if not normalized then
    return nil, nil
  end

  for index, existingTag in ipairs(ensureTagCatalog(character)) do
    if normalizeTagLabel(existingTag) == normalized then
      return index, existingTag
    end
  end

  return nil, nil
end

local function buildAssignedTagLookup(tags)
  local lookup = {}

  for _, tagLabel in ipairs(tags or {}) do
    local normalized = normalizeTagLabel(tagLabel)
    if normalized then
      lookup[normalized] = true
    end
  end

  return lookup
end

local function orderAssignedTags(character, tags)
  local ordered = {}
  local assignedLookup = buildAssignedTagLookup(tags)

  for _, catalogTag in ipairs(ensureTagCatalog(character)) do
    local normalized = normalizeTagLabel(catalogTag)
    if normalized and assignedLookup[normalized] then
      table.insert(ordered, catalogTag)
      assignedLookup[normalized] = nil
    end
  end

  return ordered
end

local function getOrderedEntryTags(character, entry)
  if type(entry) ~= "table" then
    return {}
  end

  return orderAssignedTags(character, entry.tags)
end

local function hasAssignedTags(character, entry)
  return #getOrderedEntryTags(character, entry) > 0
end

local function setOrderedEntryTags(character, entry, orderedTags)
  if type(entry) ~= "table" then
    return
  end

  local normalizedTags = orderAssignedTags(character, orderedTags)
  if #normalizedTags == 0 then
    entry.tags = nil
    return
  end

  entry.tags = copyList(normalizedTags)
end

local function getCharacter(db, characterKey)
  db.characters = db.characters or {}
  db.characters[characterKey] = ensureCharacterState(db.characters[characterKey] or {})
  return db.characters[characterKey]
end

local function getExistingCharacter(db, characterKey)
  local character = db.characters and db.characters[characterKey] or nil
  if type(character) ~= "table" then
    return nil
  end

  return ensureCharacterState(character)
end

function WishlistStore.trimTagLabel(label)
  return trimTagLabel(label)
end

function WishlistStore.normalizeTagLabel(label)
  return normalizeTagLabel(label)
end

function WishlistStore.getDefaultTagLabel()
  return resolveDefaultTagLabel()
end

function WishlistStore.ensureCharacter(db, characterKey)
  return getCharacter(db, characterKey)
end

function WishlistStore.getItemEntry(db, characterKey, itemId)
  local character = getCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return nil
  end

  character.items[itemKey] = character.items[itemKey] or {}
  return character.items[itemKey]
end

function WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  local character = getCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return nil
  end

  return character.items[itemKey]
end

function WishlistStore.getOrderedTags(db, characterKey)
  local character = getCharacter(db, characterKey)
  return copyList(ensureTagCatalog(character))
end

function WishlistStore.getOrderedItemTags(db, characterKey, itemId)
  local character = getCharacter(db, characterKey)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  return getOrderedEntryTags(character, entry)
end

function WishlistStore.getUsedTags(db, characterKey)
  local character = getCharacter(db, characterKey)
  local usedLookup = {}

  for _, entry in pairs(character.items) do
    for _, tagLabel in ipairs(getOrderedEntryTags(character, entry)) do
      local normalized = normalizeTagLabel(tagLabel)
      if normalized then
        usedLookup[normalized] = true
      end
    end
  end

  local usedTags = {}
  for _, tagLabel in ipairs(ensureTagCatalog(character)) do
    local normalized = normalizeTagLabel(tagLabel)
    if normalized and usedLookup[normalized] then
      table.insert(usedTags, tagLabel)
    end
  end

  return usedTags
end

function WishlistStore.createTag(db, characterKey, tagLabel)
  local character = getCharacter(db, characterKey)
  local trimmed = trimTagLabel(tagLabel)
  if not trimmed then
    return false, "invalid"
  end

  if findCatalogTag(character, trimmed) then
    return false, "duplicate"
  end

  table.insert(character.tags, trimmed)
  return true, trimmed
end

function WishlistStore.assignTag(db, characterKey, itemId, tagLabel)
  local character = getCharacter(db, characterKey)
  local _, canonicalTag = findCatalogTag(character, tagLabel)
  if not canonicalTag then
    return false, "missing_tag"
  end

  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)
  local assignedLookup = buildAssignedTagLookup(getOrderedEntryTags(character, entry))
  assignedLookup[normalizeTagLabel(canonicalTag)] = true

  local orderedTags = {}
  for _, catalogTag in ipairs(ensureTagCatalog(character)) do
    local normalized = normalizeTagLabel(catalogTag)
    if normalized and assignedLookup[normalized] then
      table.insert(orderedTags, catalogTag)
    end
  end

  setOrderedEntryTags(character, entry, orderedTags)
  return true, canonicalTag, entry
end

function WishlistStore.unassignTag(db, characterKey, itemId, tagLabel)
  local character = getCharacter(db, characterKey)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  if not entry then
    return false, "missing_item"
  end

  local _, canonicalTag = findCatalogTag(character, tagLabel)
  if not canonicalTag then
    return false, "missing_tag"
  end

  local assignedLookup = buildAssignedTagLookup(getOrderedEntryTags(character, entry))
  assignedLookup[normalizeTagLabel(canonicalTag)] = nil

  local orderedTags = {}
  for _, catalogTag in ipairs(ensureTagCatalog(character)) do
    local normalized = normalizeTagLabel(catalogTag)
    if normalized and assignedLookup[normalized] then
      table.insert(orderedTags, catalogTag)
    end
  end

  if #orderedTags == 0 then
    WishlistStore.removeItem(db, characterKey, itemId)
    return true, canonicalTag, nil, true
  end

  setOrderedEntryTags(character, entry, orderedTags)
  return true, canonicalTag, entry, false
end

function WishlistStore.previewDeleteTag(db, characterKey, tagLabel)
  local character = getCharacter(db, characterKey)
  local _, canonicalTag = findCatalogTag(character, tagLabel)
  if not canonicalTag then
    return nil, {}
  end

  local normalizedTarget = normalizeTagLabel(canonicalTag)
  local affectedItems = {}

  for itemKey, entry in pairs(character.items) do
    local orderedTags = getOrderedEntryTags(character, entry)
    if #orderedTags == 1 and normalizeTagLabel(orderedTags[1]) == normalizedTarget then
      table.insert(affectedItems, {
        itemID = tonumber(itemKey) or itemKey,
        selectedVariantRef = entry.selectedVariantRef,
      })
    end
  end

  table.sort(affectedItems, function(left, right)
    return tostring(left.itemID) < tostring(right.itemID)
  end)

  return canonicalTag, affectedItems
end

function WishlistStore.deleteTag(db, characterKey, tagLabel)
  local character = getCharacter(db, characterKey)
  if #ensureTagCatalog(character) <= 1 then
    return false, "last_tag", {}
  end

  local deleteIndex, canonicalTag = findCatalogTag(character, tagLabel)
  if not deleteIndex then
    return false, "missing_tag", {}
  end

  local _, affectedItems = WishlistStore.previewDeleteTag(db, characterKey, canonicalTag)
  local normalizedTarget = normalizeTagLabel(canonicalTag)

  table.remove(character.tags, deleteIndex)

  for itemKey, entry in pairs(character.items) do
    local assignedLookup = buildAssignedTagLookup(getOrderedEntryTags(character, entry))
    assignedLookup[normalizedTarget] = nil

    local orderedTags = {}
    for _, catalogTag in ipairs(ensureTagCatalog(character)) do
      local normalized = normalizeTagLabel(catalogTag)
      if normalized and assignedLookup[normalized] then
        table.insert(orderedTags, catalogTag)
      end
    end

    if #orderedTags == 0 then
      character.items[itemKey] = nil
    else
      setOrderedEntryTags(character, entry, orderedTags)
    end
  end

  return true, canonicalTag, affectedItems
end

function WishlistStore.setTracked(db, characterKey, itemId, tracked)
  if tracked then
    local defaultTag = WishlistStore.getOrderedTags(db, characterKey)[1]
    return WishlistStore.assignTag(db, characterKey, itemId, defaultTag)
  end

  WishlistStore.removeItem(db, characterKey, itemId)
  return nil
end

function WishlistStore.setItemMetadata(db, characterKey, itemId, metadata)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  if not entry or type(metadata) ~= "table" then
    return nil
  end

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

  return entry
end

function WishlistStore.isTracked(db, characterKey, itemId)
  local character = getCharacter(db, characterKey)
  return hasAssignedTags(character, WishlistStore.getExistingItemEntry(db, characterKey, itemId))
end

function WishlistStore.removeItem(db, characterKey, itemId)
  local character = getCharacter(db, characterKey)
  local itemKey = normalizeItemId(itemId)

  if itemKey == nil then
    return
  end

  character.items[itemKey] = nil
end

function WishlistStore.getGroupingMode(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.getGroupingMode(character)
end

function WishlistStore.setGroupingMode(db, characterKey, groupBy)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.setGroupingMode(character, groupBy)
end

function WishlistStore.getTrackerAttachmentMode(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.getAttachmentMode(character)
end

function WishlistStore.setTrackerAttachmentMode(db, characterKey, mode)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.setAttachmentMode(character, mode)
end

function WishlistStore.getTrackerDetachedPosition(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.getDetachedPosition(character)
end

function WishlistStore.setTrackerDetachedPosition(db, characterKey, position)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.setDetachedPosition(character, position)
end

function WishlistStore.isTrackerDetachedLocked(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.isDetachedLocked(character)
end

function WishlistStore.setTrackerDetachedLocked(db, characterKey, locked)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.setDetachedLocked(character, locked)
end

function WishlistStore.toggleTrackerDetachedLocked(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.toggleDetachedLocked(character)
end

function WishlistStore.setGroupCollapsed(db, characterKey, groupBy, groupKey, collapsed)
  local character = getCharacter(db, characterKey)
  namespace.TrackerPreferences.setGroupCollapsed(character, groupBy, groupKey, collapsed)
end

function WishlistStore.isGroupCollapsed(db, characterKey, groupBy, groupKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.isGroupCollapsed(character, groupBy, groupKey)
end

function WishlistStore.toggleGroupCollapse(db, characterKey, groupBy, groupKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.toggleGroupCollapse(character, groupBy, groupKey)
end

function WishlistStore.getTrackerTagFilterSelection(db, characterKey)
  local character = getCharacter(db, characterKey)
  return namespace.TrackerPreferences.getTagFilterSelection(character)
end

function WishlistStore.getTrackedItems(db, characterKey)
  local character = getCharacter(db, characterKey)
  local trackedItems = {}

  for itemKey, entry in pairs(character.items) do
    local orderedTags = getOrderedEntryTags(character, entry)
    if type(entry) == "table" and #orderedTags > 0 then
      table.insert(trackedItems, {
        itemID = tonumber(itemKey) or itemKey,
        encounterID = entry.encounterID,
        instanceID = entry.instanceID,
        inventoryType = entry.inventoryType,
        selectedVariantRef = entry.selectedVariantRef,
        tags = orderedTags,
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

function WishlistStore.repairTrackedMetadata(db, characterKey, runtimeNamespace)
  return namespace.WishlistMigration.repairTrackedMetadata(db, characterKey, runtimeNamespace or namespace)
end

function WishlistStore.runMigration(db, runtimeNamespace)
  return namespace.WishlistMigration.runMigration(db, runtimeNamespace or namespace)
end

if type(namespace) == "table" then
  namespace.WishlistStore = WishlistStore
end

return WishlistStore
