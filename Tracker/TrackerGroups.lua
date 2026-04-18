local _, namespace = ...

local TrackerGroups = {}

TrackerGroups.OTHER_GROUP = "Other"
TrackerGroups.OTHER_SOURCE_KEY = "source:other"
TrackerGroups.OTHER_SLOT_KEY = "slot:other"

local SLOT_GROUPS = {
  INVTYPE_HEAD = { id = "head", sortIndex = 1 },
  INVTYPE_NECK = { id = "neck", sortIndex = 2 },
  INVTYPE_SHOULDER = { id = "shoulder", sortIndex = 3 },
  INVTYPE_CLOAK = { id = "back", sortIndex = 4 },
  INVTYPE_CHEST = { id = "chest", sortIndex = 5 },
  INVTYPE_ROBE = { id = "chest", sortIndex = 5 },
  INVTYPE_WRIST = { id = "wrist", sortIndex = 6 },
  INVTYPE_HAND = { id = "hands", sortIndex = 7 },
  INVTYPE_WAIST = { id = "waist", sortIndex = 8 },
  INVTYPE_LEGS = { id = "legs", sortIndex = 9 },
  INVTYPE_FEET = { id = "feet", sortIndex = 10 },
  INVTYPE_FINGER = { id = "rings", sortIndex = 11 },
  INVTYPE_TRINKET = { id = "trinkets", sortIndex = 12 },
  INVTYPE_2HWEAPON = { id = "two_hand", sortIndex = 13 },
  INVTYPE_WEAPONMAINHAND = { id = "main_hand", sortIndex = 14 },
  INVTYPE_WEAPON = { id = "main_hand", sortIndex = 14 },
  INVTYPE_WEAPONOFFHAND = { id = "off_hand", sortIndex = 15 },
  INVTYPE_SHIELD = { id = "off_hand", sortIndex = 15 },
  INVTYPE_HOLDABLE = { id = "off_hand", sortIndex = 15 },
}

local function normalizeMode(groupBy)
  return groupBy == "slot" and "slot" or "source"
end

local function getSourceLabel(itemData, otherLabel)
  if itemData == nil then
    return otherLabel
  end

  local instanceName = itemData.instanceName or itemData.currentInstanceName or itemData.sourceName or itemData.instance or itemData.sourceLabel
  if type(instanceName) ~= "string" or instanceName == "" then
    return otherLabel
  end

  return instanceName
end

local function getSlotLabel(itemData, otherLabel)
  if itemData == nil then
    return otherLabel
  end

  local slotLabel = itemData.slotLabel
  if type(slotLabel) == "string" and slotLabel ~= "" then
    return slotLabel
  end

  local inventoryType = itemData.inventoryType
  if type(inventoryType) == "string" and inventoryType ~= "" then
    return inventoryType
  end

  return otherLabel
end

local function normalizeSlotGroup(itemData)
  local inventoryType = itemData and itemData.inventoryType or nil
  if type(inventoryType) ~= "string" or inventoryType == "" or inventoryType == "INVTYPE_NON_EQUIP_IGNORE" then
    return nil
  end

  return SLOT_GROUPS[inventoryType]
end

function TrackerGroups.resolveGroup(groupBy, itemData, otherLabel)
  local mode = normalizeMode(groupBy)
  otherLabel = otherLabel or TrackerGroups.OTHER_GROUP

  if mode == "slot" then
    local slotGroup = normalizeSlotGroup(itemData)
    local label = getSlotLabel(itemData, otherLabel)
    if slotGroup ~= nil then
      return {
        key = "slot:" .. slotGroup.id,
        label = label,
        mode = mode,
        sortIndex = slotGroup.sortIndex,
      }
    end

    return {
      key = TrackerGroups.OTHER_SLOT_KEY,
      label = otherLabel,
      mode = mode,
      sortIndex = 999,
    }
  end

  local instanceID = itemData and itemData.instanceID or nil
  local label = getSourceLabel(itemData, otherLabel)
  if type(instanceID) == "number" and instanceID > 0 then
    return {
      key = "source:instance:" .. tostring(instanceID),
      label = label,
      mode = mode,
    }
  end

  if label ~= otherLabel then
    return {
      key = "source:label:" .. label,
      label = label,
      mode = mode,
    }
  end

  return {
    key = TrackerGroups.OTHER_SOURCE_KEY,
    label = otherLabel,
    mode = mode,
  }
end

local function compareGroupLabels(otherLabel, left, right)
  if left == right then
    return false
  end

  if left == otherLabel then
    return false
  end

  if right == otherLabel then
    return true
  end

  return left < right
end

local function compareGroups(otherLabel, left, right)
  local leftSort = left.sortIndex or 999
  local rightSort = right.sortIndex or 999
  if leftSort ~= rightSort then
    return leftSort < rightSort
  end

  return compareGroupLabels(otherLabel, left.label or otherLabel, right.label or otherLabel)
end

local function buildDisplayText(item, skipBoss)
  local text = item.itemName

  if not skipBoss and item.bossName ~= nil and item.bossName ~= "" then
    text = string.format("%s |cffa0a0a0(%s)|r", text, item.bossName)
  end

  return text
end

local function isValidInstanceID(instanceID)
  return type(instanceID) == "number" and instanceID > 0
end

function TrackerGroups.buildGroups(items, options)
  local groupsByKey = {}
  local groupingMode = options and options.groupBy or "source"
  local otherLabel = options and options.otherLabel or "Other"
  otherLabel = otherLabel or "Other"

  for _, item in ipairs(items) do
    local groupKey = item.groupKey or ("fallback:" .. tostring(item.groupLabel or otherLabel))
    local label = item.groupLabel or otherLabel

    if groupsByKey[groupKey] == nil then
      groupsByKey[groupKey] = {
        key = groupKey,
        label = label,
        mode = groupingMode,
        sortIndex = item.groupSortIndex,
        items = {},
        isRaid = false,
        instanceID = nil,
      }
    end

    if item.isRaidSource == true then
      groupsByKey[groupKey].isRaid = true
    end

    if groupsByKey[groupKey].instanceID == nil and isValidInstanceID(item.instanceID) then
      groupsByKey[groupKey].instanceID = item.instanceID
    end

    table.insert(groupsByKey[groupKey].items, item)
  end

  local groupKeys = {}
  for groupKey in pairs(groupsByKey) do
    table.insert(groupKeys, groupKey)
  end
  table.sort(groupKeys, function(left, right)
    return compareGroups(otherLabel, groupsByKey[left], groupsByKey[right])
  end)

  local orderedGroups = {}
  for _, groupKey in ipairs(groupKeys) do
    local group = groupsByKey[groupKey]
    local flattenedItems = {}

    if groupingMode == "source" and group.isRaid then
      local itemsByBoss = {}
      local bossOrder = {}
      local bossRanks = {}

      for _, item in ipairs(group.items) do
        local bossName = item.bossName or "Unknown"
        if not itemsByBoss[bossName] then
          itemsByBoss[bossName] = {}
          table.insert(bossOrder, bossName)
          bossRanks[bossName] = item.bossRank or 999
        end
        table.insert(itemsByBoss[bossName], item)
      end

      table.sort(bossOrder, function(left, right)
        return bossRanks[left] < bossRanks[right]
      end)

      for _, bossName in ipairs(bossOrder) do
        table.insert(flattenedItems, {
          itemID = "header:" .. bossName,
          displayText = bossName,
          isBossHeader = true,
          showTick = false,
        })

        for _, item in ipairs(itemsByBoss[bossName]) do
          table.insert(flattenedItems, {
            itemID = item.itemID,
            itemName = item.itemName,
            displayText = buildDisplayText(item, true),
            showTick = item.isPossessed == true,
            tooltipRef = item.tooltipRef,
            displayLink = item.displayLink,
            sourceLabel = item.sourceLabel,
            bossName = item.bossName,
            inventoryType = item.inventoryType,
            tags = item.tags,
            tooltipFooterLines = item.tooltipFooterLines,
            isRaidSource = item.isRaidSource,
          })
        end
      end
    else
      for _, item in ipairs(group.items) do
        table.insert(flattenedItems, {
          itemID = item.itemID,
          itemName = item.itemName,
          displayText = buildDisplayText(item, true),
          showTick = item.isPossessed == true,
          tooltipRef = item.tooltipRef,
          displayLink = item.displayLink,
          sourceLabel = item.sourceLabel,
          bossName = item.bossName,
          inventoryType = item.inventoryType,
          tags = item.tags,
          tooltipFooterLines = item.tooltipFooterLines,
          isRaidSource = item.isRaidSource,
        })
      end
    end

    local instanceID = isValidInstanceID(group.instanceID) and group.instanceID or nil
    table.insert(orderedGroups, {
      key = group.key,
      label = group.label,
      mode = group.mode,
      sortIndex = group.sortIndex,
      items = flattenedItems,
      instanceID = instanceID,
    })
  end

  return orderedGroups
end

if type(namespace) == "table" then
  namespace.TrackerGroups = TrackerGroups
end

return TrackerGroups
