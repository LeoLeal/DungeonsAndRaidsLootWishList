local _, namespace = ...

local WishlistMigration = {}

local LEGACY_LOCALIZED_FIELDS = {
  tracked = true,
  itemName = true,
  itemLink = true,
  sourceLabel = true,
  bossName = true,
}

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

local function normalizeSelectedVariantRef(runtimeNamespace, itemLink)
  if type(itemLink) ~= "string" or itemLink == "" then
    return nil
  end

  if runtimeNamespace and runtimeNamespace.ItemResolver and type(runtimeNamespace.ItemResolver.getVariantRef) == "function" then
    return runtimeNamespace.ItemResolver.getVariantRef(itemLink)
  end

  return itemLink:match("|H([^|]+)|h") or (itemLink:match("^item:") and itemLink) or nil
end

local function buildCatalog(character, runtimeNamespace)
  local ordered = {}
  local byNormalized = {}
  local changed = false
  local defaultTag = runtimeNamespace.WishlistStore.getDefaultTagLabel()
  local sourceTags = type(character.tags) == "table" and character.tags or {}

  if type(character.tags) ~= "table" then
    changed = true
  end

  for _, rawTag in ipairs(sourceTags) do
    local trimmed = runtimeNamespace.WishlistStore.trimTagLabel(rawTag)
    local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(trimmed)

    if normalized and not byNormalized[normalized] then
      byNormalized[normalized] = trimmed
      table.insert(ordered, trimmed)
      if trimmed ~= rawTag then
        changed = true
      end
    else
      changed = true
    end
  end

  if #ordered == 0 then
    ordered[1] = defaultTag
    byNormalized[runtimeNamespace.WishlistStore.normalizeTagLabel(defaultTag)] = defaultTag
    changed = true
  end

  return {
    ordered = ordered,
    byNormalized = byNormalized,
  }, changed
end

local function ensureCatalogTag(catalog, runtimeNamespace, rawTag)
  local trimmed = runtimeNamespace.WishlistStore.trimTagLabel(rawTag)
  local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(trimmed)
  if not normalized then
    return nil, false
  end

  local existing = catalog.byNormalized[normalized]
  if existing then
    return existing, false
  end

  catalog.byNormalized[normalized] = trimmed
  table.insert(catalog.ordered, trimmed)
  return trimmed, true
end

local function buildAssignedTags(entry, catalog, runtimeNamespace)
  local assignedLookup = {}
  local changed = false
  local sourceTags = type(entry.tags) == "table" and entry.tags or nil

  if sourceTags then
    for _, rawTag in ipairs(sourceTags) do
      local canonicalTag, addedToCatalog = ensureCatalogTag(catalog, runtimeNamespace, rawTag)
      if canonicalTag then
        assignedLookup[runtimeNamespace.WishlistStore.normalizeTagLabel(canonicalTag)] = true
        if canonicalTag ~= rawTag or addedToCatalog then
          changed = true
        end
      else
        changed = true
      end
    end
  elseif entry.tags ~= nil then
    changed = true
  end

  if next(assignedLookup) == nil then
    assignedLookup[runtimeNamespace.WishlistStore.normalizeTagLabel(catalog.ordered[1])] = true
    changed = true
  end

  local orderedTags = {}
  for _, catalogTag in ipairs(catalog.ordered) do
    local normalized = runtimeNamespace.WishlistStore.normalizeTagLabel(catalogTag)
    if normalized and assignedLookup[normalized] then
      table.insert(orderedTags, catalogTag)
    end
  end

  return orderedTags, changed
end

local function migrateEntry(runtimeNamespace, itemId, entry, catalog)
  if type(entry) ~= "table" then
    return nil, true
  end

  if entry.tracked ~= nil and entry.tracked ~= true then
    return nil, true
  end

  local orderedTags, tagsChanged = buildAssignedTags(entry, catalog, runtimeNamespace)
  local selectedVariantRef = entry.selectedVariantRef
  if selectedVariantRef == nil then
    selectedVariantRef = normalizeSelectedVariantRef(runtimeNamespace, entry.itemLink)
  else
    selectedVariantRef = normalizeSelectedVariantRef(runtimeNamespace, selectedVariantRef)
  end

  local inventoryType = entry.inventoryType or resolveInventoryType(tonumber(itemId))
  local changed = tagsChanged

  if inventoryType ~= entry.inventoryType then
    changed = true
  end

  if selectedVariantRef ~= entry.selectedVariantRef then
    changed = true
  end

  for fieldName in pairs(LEGACY_LOCALIZED_FIELDS) do
    if entry[fieldName] ~= nil then
      changed = true
      break
    end
  end

  if entry.bestLootedItemLevel ~= nil then
    changed = true
  end

  return {
    instanceID = entry.instanceID,
    encounterID = entry.encounterID,
    inventoryType = inventoryType,
    selectedVariantRef = selectedVariantRef,
    tags = orderedTags,
  }, changed
end

local function migrateCharacterItems(db, characterKey, runtimeNamespace)
  local character = runtimeNamespace.WishlistStore.ensureCharacter(db, characterKey)
  local catalog, changed = buildCatalog(character, runtimeNamespace)
  local migratedItems = {}

  for itemKey, entry in pairs(character.items or {}) do
    local migratedEntry, entryChanged = migrateEntry(runtimeNamespace, itemKey, entry, catalog)
    if migratedEntry ~= nil then
      migratedItems[itemKey] = migratedEntry
    end

    if entryChanged then
      changed = true
    end
  end

  character.tags = catalog.ordered
  if changed then
    character.items = migratedItems
  end

  return changed
end

function WishlistMigration.performBackfill(db, characterKey, runtimeNamespace)
  local character = runtimeNamespace.WishlistStore.ensureCharacter(db, characterKey)
  local itemsPending = {}

  for itemID, entry in pairs(character.items) do
    if type(entry) == "table" and (not entry.encounterID or not entry.instanceID or not entry.inventoryType) then
      itemsPending[tonumber(itemID)] = entry
    end

    if type(entry) == "table" and not entry.inventoryType then
      entry.inventoryType = resolveInventoryType(tonumber(itemID))
    end
  end

  if next(itemsPending) == nil then
    return
  end

  if type(EJ_GetNumTiers) ~= "function" then
    return
  end

  for tierIndex = 1, EJ_GetNumTiers() do
    EJ_SelectTier(tierIndex)
    for isRaid = 0, 1 do
      local instanceIndex = 1
      while true do
        local instanceID = EJ_GetInstanceByIndex(instanceIndex, isRaid == 1)
        if not instanceID then
          break
        end

        EJ_SelectInstance(instanceID)
        local encounterIndex = 1
        while true do
          local _, _, encounterID = EJ_GetEncounterInfoByIndex(encounterIndex)
          if not encounterID then
            break
          end

          if type(EJ_SelectEncounter) == "function" and type(EJ_GetNumLoot) == "function" then
            EJ_SelectEncounter(encounterID)
            local numLoot = EJ_GetNumLoot() or 0
            for lootIndex = 1, numLoot do
              local lootInfo = nil
              if C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
                lootInfo = C_EncounterJournal.GetLootInfoByIndex(lootIndex)
              end

              local lootItemID = lootInfo and lootInfo.itemID
              if lootItemID and itemsPending[lootItemID] then
                itemsPending[lootItemID].encounterID = encounterID
                itemsPending[lootItemID].instanceID = instanceID
                itemsPending[lootItemID].inventoryType = itemsPending[lootItemID].inventoryType or resolveInventoryType(lootItemID)
              end
            end
          end

          encounterIndex = encounterIndex + 1
        end

        instanceIndex = instanceIndex + 1
      end
    end
  end
end

function WishlistMigration.repairTrackedMetadata(db, characterKey, runtimeNamespace)
  local character = db.characters and db.characters[characterKey]
  if type(character) ~= "table" then
    return false
  end

  return migrateCharacterItems(db, characterKey, runtimeNamespace or namespace)
end

function WishlistMigration.runMigration(db, runtimeNamespace)
  if db.version == 5 then
    return
  end

  db.characters = db.characters or {}

  for characterKey in pairs(db.characters) do
    runtimeNamespace.WishlistStore.ensureCharacter(db, characterKey)
  end

  for characterKey in pairs(db.characters) do
    WishlistMigration.repairTrackedMetadata(db, characterKey, runtimeNamespace)
    WishlistMigration.performBackfill(db, characterKey, runtimeNamespace)
  end

  db.version = 5
end

if type(namespace) == "table" then
  namespace.WishlistMigration = WishlistMigration
end

return WishlistMigration
