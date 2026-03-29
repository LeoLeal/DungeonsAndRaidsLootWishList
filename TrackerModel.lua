local TrackerModel = {}

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
  if item.bestLootedItemLevel ~= nil then
    text = string.format("%s (%s)", text, tostring(item.bestLootedItemLevel))
  end

  if not skipBoss and item.bossName ~= nil and item.bossName ~= "" then
    text = string.format("%s |cffa0a0a0(%s)|r", text, item.bossName)
  end

  return text
end

local function isValidInstanceID(instanceID)
  return type(instanceID) == "number" and instanceID > 0
end

function TrackerModel.buildGroups(items, options)
  local groupsByKey = {}
  local groupingMode = options and options.groupBy or "source"
  local otherLabel = options and options.otherLabel or "Other"
  otherLabel = otherLabel or "Other"

  -- First, group items by stable group key.
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
        local bname = item.bossName or "Unknown"
        if not itemsByBoss[bname] then
          itemsByBoss[bname] = {}
          table.insert(bossOrder, bname)
          bossRanks[bname] = item.bossRank or 999
        end
        table.insert(itemsByBoss[bname], item)
      end

      table.sort(bossOrder, function(left, right)
        return bossRanks[left] < bossRanks[right]
      end)

      for _, bname in ipairs(bossOrder) do
        table.insert(flattenedItems, {
          itemID = "header:" .. bname,
          displayText = bname,
          isBossHeader = true,
          showTick = false,
        })

        for _, item in ipairs(itemsByBoss[bname]) do
          table.insert(flattenedItems, {
            itemID = item.itemID,
            itemName = item.itemName,
            displayText = buildDisplayText(item, true), -- skip inline boss name
            showTick = item.isPossessed == true,
            bestLootedItemLevel = item.bestLootedItemLevel,
            tooltipRef = item.tooltipRef,
            displayLink = item.displayLink,
            sourceLabel = item.sourceLabel,
            bossName = item.bossName,
            inventoryType = item.inventoryType,
            tooltipFooter = item.tooltipFooter,
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
          bestLootedItemLevel = item.bestLootedItemLevel,
          tooltipRef = item.tooltipRef,
          displayLink = item.displayLink,
          sourceLabel = item.sourceLabel,
          bossName = item.bossName,
          inventoryType = item.inventoryType,
          tooltipFooter = item.tooltipFooter,
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

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TrackerModel = TrackerModel
end

return TrackerModel
