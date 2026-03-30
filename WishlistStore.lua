local WishlistStore = {}

local LEGACY_LOCALIZED_FIELDS = {
  tracked = true,
  itemName = true,
  itemLink = true,
  sourceLabel = true,
  bossName = true,
}

local function normalizeItemId(itemId)
  if itemId == nil then
    return nil
  end

  return tostring(itemId)
end

local function ensureTrackerState(character)
  local legacyCollapsedGroups = character.collapsedGroups or {}

  character.tracker = character.tracker or {}
  character.tracker.groupBy = character.tracker.groupBy == "slot" and "slot" or "source"
  character.tracker.collapsedGroupsByMode = character.tracker.collapsedGroupsByMode or {}
  character.tracker.collapsedGroupsByMode.source = character.tracker.collapsedGroupsByMode.source or {}
  character.tracker.collapsedGroupsByMode.slot = character.tracker.collapsedGroupsByMode.slot or {}

  if not character.tracker.legacyCollapsedGroupsMigrated then
    for groupKey, collapsed in pairs(legacyCollapsedGroups) do
      if collapsed then
        character.tracker.collapsedGroupsByMode.source[groupKey] = true
      end
    end

    character.tracker.legacyCollapsedGroupsMigrated = true
  end

  return character.tracker
end

local function getCollapsedGroups(character, groupBy)
  local tracker = ensureTrackerState(character)
  local mode = groupBy == "slot" and "slot" or "source"
  tracker.collapsedGroupsByMode[mode] = tracker.collapsedGroupsByMode[mode] or {}
  return tracker.collapsedGroupsByMode[mode], mode
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
  db.characters[characterKey] = db.characters[characterKey] or { items = {}, collapsedGroups = {} }
  db.characters[characterKey].items = db.characters[characterKey].items or {}
  ensureTrackerState(db.characters[characterKey])

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

  if metadata.bestLootedItemLevel ~= nil then
    entry.bestLootedItemLevel = metadata.bestLootedItemLevel
  end

  if metadata.selectedVariantRef ~= nil then
    entry.selectedVariantRef = metadata.selectedVariantRef
  end

  if entry.inventoryType == nil then
    entry.inventoryType = resolveInventoryType(itemId)
  end
end

function WishlistStore.isTracked(db, characterKey, itemId)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  return entry ~= nil
end

function WishlistStore.updateBestLootedItemLevel(db, characterKey, itemId, itemLevel)
  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)
  if not entry then return nil end

  if itemLevel == nil then
    return entry.bestLootedItemLevel
  end

  if entry.bestLootedItemLevel == nil or itemLevel > entry.bestLootedItemLevel then
    entry.bestLootedItemLevel = itemLevel
  end

  return entry.bestLootedItemLevel
end

function WishlistStore.getBestLootedItemLevel(db, characterKey, itemId)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  return entry and entry.bestLootedItemLevel or nil
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
  local tracker = ensureTrackerState(character)
  return tracker.groupBy
end

function WishlistStore.setGroupingMode(db, characterKey, groupBy)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local tracker = ensureTrackerState(character)
  tracker.groupBy = groupBy == "slot" and "slot" or "source"
  return tracker.groupBy
end

function WishlistStore.setGroupCollapsed(db, characterKey, groupBy, groupKey, collapsed)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  collapsedGroups[groupKey] = collapsed and true or nil
end

function WishlistStore.isGroupCollapsed(db, characterKey, groupBy, groupKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  return collapsedGroups[groupKey] == true
end

function WishlistStore.toggleGroupCollapse(db, characterKey, groupBy, groupKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  local currentState = collapsedGroups[groupKey] == true
  WishlistStore.setGroupCollapsed(db, characterKey, groupBy, groupKey, not currentState)
  return not currentState
end

function WishlistStore.getTrackedItems(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local trackedItems = {}

  for itemKey, entry in pairs(character.items) do
    if type(entry) == "table" then
      table.insert(trackedItems, {
        itemID = tonumber(itemKey) or itemKey,
        bestLootedItemLevel = entry.bestLootedItemLevel,
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

function WishlistStore.performBackfill(db, characterKey, namespace)
  local character = WishlistStore.ensureCharacter(db, characterKey)
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

  -- Scan EJ for missing encounter/instance IDs
  -- This is a one-time heavy task for migration
  if type(EJ_GetNumTiers) ~= "function" then return end

  for t = 1, EJ_GetNumTiers() do
    EJ_SelectTier(t)
    for isRaid = 0, 1 do
      local i = 1
      while true do
        local instanceID, name = EJ_GetInstanceByIndex(i, isRaid == 1)
        if not instanceID then break end

        EJ_SelectInstance(instanceID)
        local e = 1
        while true do
          local ename, _, encounterID = EJ_GetEncounterInfoByIndex(e)
          if not encounterID then break end

          if type(EJ_SelectEncounter) == "function" and type(EJ_GetNumLoot) == "function" then
            EJ_SelectEncounter(encounterID)
            local numLoot = EJ_GetNumLoot() or 0
            for l = 1, numLoot do
              local litem
              if C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
                litem = C_EncounterJournal.GetLootInfoByIndex(l)
              end

              local litemID = litem and litem.itemID
              if litemID and itemsPending[litemID] then
                itemsPending[litemID].encounterID = encounterID
                itemsPending[litemID].instanceID = instanceID
                itemsPending[litemID].inventoryType = itemsPending[litemID].inventoryType or resolveInventoryType(litemID)
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

function WishlistStore.repairTrackedMetadata(db, characterKey, namespace)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local changed = false

  for itemID, entry in pairs(character.items) do
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
    end
  end

  return changed
end

local function normalizeSelectedVariantRef(namespace, itemLink)
  if type(itemLink) ~= "string" or itemLink == "" then
    return nil
  end

  if namespace and namespace.ItemResolver and type(namespace.ItemResolver.getVariantRef) == "function" then
    return namespace.ItemResolver.getVariantRef(itemLink)
  end

  return itemLink:match("|H([^|]+)|h") or (itemLink:match("^item:") and itemLink) or nil
end

local function migrateEntry(namespace, itemId, entry)
  if type(entry) ~= "table" then
    return nil
  end

  if entry.tracked ~= nil and entry.tracked ~= true then
    return nil
  end

  local migrated = {
    bestLootedItemLevel = entry.bestLootedItemLevel,
    instanceID = entry.instanceID,
    encounterID = entry.encounterID,
    inventoryType = entry.inventoryType,
    selectedVariantRef = entry.selectedVariantRef,
  }

  if migrated.selectedVariantRef == nil then
    migrated.selectedVariantRef = normalizeSelectedVariantRef(namespace, entry.itemLink)
  else
    migrated.selectedVariantRef = normalizeSelectedVariantRef(namespace, migrated.selectedVariantRef)
  end

  if migrated.inventoryType == nil then
    migrated.inventoryType = resolveInventoryType(tonumber(itemId))
  end

  if next(migrated) == nil then
    return {}
  end

  return migrated
end

local function migrateCharacterItems(db, characterKey, namespace)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local migratedItems = {}
  local changed = false

  for itemKey, entry in pairs(character.items or {}) do
    local migratedEntry = migrateEntry(namespace, itemKey, entry)
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

function WishlistStore.runMigration(db, namespace)
  if db.version == 4 then return end

  for characterKey, _ in pairs(db.characters or {}) do
    WishlistStore.ensureCharacter(db, characterKey)
  end

  for characterKey, _ in pairs(db.characters or {}) do
    migrateCharacterItems(db, characterKey, namespace)
    WishlistStore.performBackfill(db, characterKey, namespace)
    WishlistStore.repairTrackedMetadata(db, characterKey, namespace)
  end

  db.version = 4
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.WishlistStore = WishlistStore
end

return WishlistStore
