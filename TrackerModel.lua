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

function TrackerModel.buildGroups(items, otherLabel)
  local groupsByLabel = {}
  otherLabel = otherLabel or "Other"

  -- First, group items by Source (groupLabel)
  for _, item in ipairs(items) do
    local label = item.groupLabel or "Other"
    if groupsByLabel[label] == nil then
      groupsByLabel[label] = {
        label = label,
        items = {},
        isRaid = false, -- Will be set if any item has a bossName
        instanceID = nil,
      }
    end

    if item.bossName and item.bossName ~= "" then
      groupsByLabel[label].isRaid = true
    end

    if groupsByLabel[label].instanceID == nil and isValidInstanceID(item.instanceID) then
      groupsByLabel[label].instanceID = item.instanceID
    end

    table.insert(groupsByLabel[label].items, item)
  end

  -- Sort sources
  local labels = {}
  for label in pairs(groupsByLabel) do
    table.insert(labels, label)
  end
  table.sort(labels, function(left, right)
    return compareGroupLabels(otherLabel, left, right)
  end)

  local orderedGroups = {}
  for _, label in ipairs(labels) do
    local group = groupsByLabel[label]
    local flattenedItems = {}

    if group.isRaid then
      -- Hierarchical grouping for Raids: Boss > Items
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

      -- Sort bosses by their EJ rank
      table.sort(bossOrder, function(left, right)
        return bossRanks[left] < bossRanks[right]
      end)

      -- Flatten into rows with headers
      for _, bname in ipairs(bossOrder) do
        -- Boss Header row
        table.insert(flattenedItems, {
          itemID = "header:" .. bname,
          displayText = bname,
          isBossHeader = true,
          showTick = false,
        })

        -- Items under this boss
        for _, item in ipairs(itemsByBoss[bname]) do
          table.insert(flattenedItems, {
            itemID = item.itemID,
            itemName = item.itemName,
            displayText = buildDisplayText(item, true), -- skip inline boss name
            showTick = item.isPossessed == true,
            bestLootedItemLevel = item.bestLootedItemLevel,
            tooltipRef = item.tooltipRef,
            displayLink = item.displayLink,
          })
        end
      end
    else
      -- Flat list for Dungeons and Other
      for _, item in ipairs(group.items) do
        table.insert(flattenedItems, {
          itemID = item.itemID,
          itemName = item.itemName,
          displayText = buildDisplayText(item),
          showTick = item.isPossessed == true,
          bestLootedItemLevel = item.bestLootedItemLevel,
          tooltipRef = item.tooltipRef,
          displayLink = item.displayLink,
        })
      end
    end

    local instanceID = isValidInstanceID(group.instanceID) and group.instanceID or nil
    table.insert(orderedGroups, {
      label = group.label,
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
