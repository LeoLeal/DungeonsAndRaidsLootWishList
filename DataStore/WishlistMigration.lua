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

local function migrateEntry(runtimeNamespace, itemId, entry)
  if type(entry) ~= "table" then
    return nil
  end

  if entry.tracked ~= nil and entry.tracked ~= true then
    return nil
  end

  local migrated = {
    instanceID = entry.instanceID,
    encounterID = entry.encounterID,
    inventoryType = entry.inventoryType,
    selectedVariantRef = entry.selectedVariantRef,
  }

  if migrated.selectedVariantRef == nil then
    migrated.selectedVariantRef = normalizeSelectedVariantRef(runtimeNamespace, entry.itemLink)
  else
    migrated.selectedVariantRef = normalizeSelectedVariantRef(runtimeNamespace, migrated.selectedVariantRef)
  end

  if migrated.inventoryType == nil then
    migrated.inventoryType = resolveInventoryType(tonumber(itemId))
  end

  if next(migrated) == nil then
    return {}
  end

  return migrated
end

local function migrateCharacterItems(db, characterKey, runtimeNamespace)
  local character = runtimeNamespace.WishlistStore.ensureCharacter(db, characterKey)
  local migratedItems = {}
  local changed = false

  for itemKey, entry in pairs(character.items or {}) do
    local migratedEntry = migrateEntry(runtimeNamespace, itemKey, entry)
    if migratedEntry ~= nil then
      migratedItems[itemKey] = migratedEntry
      if migratedEntry ~= entry then
        changed = true
      end
    else
      changed = true
    end
  end

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

  for t = 1, EJ_GetNumTiers() do
    EJ_SelectTier(t)
    for isRaid = 0, 1 do
      local i = 1
      while true do
        local instanceID = EJ_GetInstanceByIndex(i, isRaid == 1)
        if not instanceID then
          break
        end

        EJ_SelectInstance(instanceID)
        local e = 1
        while true do
          local _, _, encounterID = EJ_GetEncounterInfoByIndex(e)
          if not encounterID then
            break
          end

          if type(EJ_SelectEncounter) == "function" and type(EJ_GetNumLoot) == "function" then
            EJ_SelectEncounter(encounterID)
            local numLoot = EJ_GetNumLoot() or 0
            for l = 1, numLoot do
              local lootInfo = nil
              if C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
                lootInfo = C_EncounterJournal.GetLootInfoByIndex(l)
              end

              local lootItemID = lootInfo and lootInfo.itemID
              if lootItemID and itemsPending[lootItemID] then
                itemsPending[lootItemID].encounterID = encounterID
                itemsPending[lootItemID].instanceID = instanceID
                itemsPending[lootItemID].inventoryType = itemsPending[lootItemID].inventoryType or resolveInventoryType(lootItemID)
              end
            end
          end

          e = e + 1
        end

        i = i + 1
      end
    end
  end
end

function WishlistMigration.repairTrackedMetadata(db, characterKey)
  local character = db.characters and db.characters[characterKey]
  if type(character) ~= "table" then
    return false
  end

  local changed = false

  for itemID, entry in pairs(character.items or {}) do
    local numericItemID = tonumber(itemID)

    if type(entry) == "table" then
      if not entry.inventoryType then
        local inventoryType = resolveInventoryType(numericItemID)
        if inventoryType then
          entry.inventoryType = inventoryType
          changed = true
        end
      end

      for fieldName in pairs(LEGACY_LOCALIZED_FIELDS) do
        if entry[fieldName] ~= nil then
          entry[fieldName] = nil
          changed = true
        end
      end

      if entry.bestLootedItemLevel ~= nil then
        entry.bestLootedItemLevel = nil
        changed = true
      end
    end
  end

  return changed
end

function WishlistMigration.runMigration(db, runtimeNamespace)
  if db.version == 4 then
    return
  end

  for characterKey in pairs(db.characters or {}) do
    runtimeNamespace.WishlistStore.ensureCharacter(db, characterKey)
  end

  for characterKey in pairs(db.characters or {}) do
    migrateCharacterItems(db, characterKey, runtimeNamespace)
    WishlistMigration.performBackfill(db, characterKey, runtimeNamespace)
    WishlistMigration.repairTrackedMetadata(db, characterKey)
  end

  db.version = 4
end

if type(namespace) == "table" then
  namespace.WishlistMigration = WishlistMigration
end

return WishlistMigration
