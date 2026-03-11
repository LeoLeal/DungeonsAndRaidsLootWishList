local WishlistStore = {}

local function normalizeItemId(itemId)
  if itemId == nil then
    return nil
  end

  return tostring(itemId)
end

function WishlistStore.ensureCharacter(db, characterKey)
  db.characters = db.characters or {}
  db.characters[characterKey] = db.characters[characterKey] or { items = {}, collapsedGroups = {} }
  db.characters[characterKey].items = db.characters[characterKey].items or {}
  db.characters[characterKey].collapsedGroups = db.characters[characterKey].collapsedGroups or {}

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
  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)
  entry.tracked = tracked and true or false
end

function WishlistStore.setSourceLabel(db, characterKey, itemId, sourceLabel)
  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)
  entry.sourceLabel = sourceLabel
end

function WishlistStore.setItemMetadata(db, characterKey, itemId, metadata)
  local entry = WishlistStore.getItemEntry(db, characterKey, itemId)

  if metadata.itemName ~= nil then
    entry.itemName = metadata.itemName
  end

  if metadata.itemLink ~= nil then
    entry.itemLink = metadata.itemLink
  end

  if metadata.sourceLabel ~= nil then
    entry.sourceLabel = metadata.sourceLabel
  end

  if metadata.encounterID ~= nil then
    entry.encounterID = metadata.encounterID
  end

  if metadata.instanceID ~= nil then
    entry.instanceID = metadata.instanceID
  end
end

function WishlistStore.getSourceLabel(db, characterKey, itemId)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  return entry and entry.sourceLabel or nil
end

function WishlistStore.isTracked(db, characterKey, itemId)
  local entry = WishlistStore.getExistingItemEntry(db, characterKey, itemId)
  return entry ~= nil and entry.tracked == true
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

  character.items[itemKey] = {
    tracked = false,
  }
end

function WishlistStore.setGroupCollapsed(db, characterKey, label, collapsed)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  character.collapsedGroups[label] = collapsed and true or nil
end

function WishlistStore.isGroupCollapsed(db, characterKey, label)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  return character.collapsedGroups[label] == true
end

function WishlistStore.toggleGroupCollapse(db, characterKey, label)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local currentState = character.collapsedGroups[label] == true
  WishlistStore.setGroupCollapsed(db, characterKey, label, not currentState)
  return not currentState
end

function WishlistStore.getTrackedItems(db, characterKey)
  local character = WishlistStore.ensureCharacter(db, characterKey)
  local trackedItems = {}

  for itemKey, entry in pairs(character.items) do
    if entry.tracked == true then
      table.insert(trackedItems, {
        itemID = tonumber(itemKey) or itemKey,
        tracked = true,
        bestLootedItemLevel = entry.bestLootedItemLevel,
        sourceLabel = entry.sourceLabel,
        itemName = entry.itemName,
        itemLink = entry.itemLink,
        encounterID = entry.encounterID,
        instanceID = entry.instanceID,
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
    if entry.tracked and (not entry.encounterID or not entry.instanceID) then
      itemsPending[tonumber(itemID)] = entry
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

function WishlistStore.runMigration(db, namespace)
  if db.version == 2 then return end

  for characterKey, _ in pairs(db.characters or {}) do
    WishlistStore.performBackfill(db, characterKey, namespace)
  end

  db.version = 2
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.WishlistStore = WishlistStore
end

return WishlistStore
