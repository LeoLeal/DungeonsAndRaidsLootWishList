local _, namespace = ...

local TrackerRenderData = {}

local TOOLTIP_SOURCE_ATLAS_SIZE = 18
local TOOLTIP_SOURCE_DUNGEON_ATLAS = "questlog-questtypeicon-dungeon"
local TOOLTIP_SOURCE_RAID_ATLAS = "questlog-questtypeicon-raid"

local function resolveInstanceName(instanceID)
  if type(instanceID) ~= "number" or instanceID <= 0 or type(EJ_GetInstanceInfo) ~= "function" then
    return nil
  end

  local instanceName = EJ_GetInstanceInfo(instanceID)
  if type(instanceName) == "string" and instanceName ~= "" then
    return instanceName
  end

  return nil
end

local function getInventoryTypeLabel(runtimeNamespace, inventoryType)
  if type(inventoryType) ~= "string" or inventoryType == "" or inventoryType == "INVTYPE_NON_EQUIP_IGNORE" then
    return runtimeNamespace.GetText("OTHER")
  end

  local globalLabel = _G[inventoryType]
  if type(globalLabel) == "string" and globalLabel ~= "" then
    return globalLabel
  end

  return inventoryType
end

local function buildInlineAtlasMarkup(atlasName)
  if type(atlasName) ~= "string" or atlasName == "" then
    return nil
  end

  return string.format("|A:%s:%d:%d|a", atlasName, TOOLTIP_SOURCE_ATLAS_SIZE, TOOLTIP_SOURCE_ATLAS_SIZE)
end

local function buildTooltipFooter(runtimeNamespace, groupingMode, item)
  if groupingMode ~= "slot" then
    return nil
  end

  local sourceLabel = resolveInstanceName(item.instanceID)
  if type(sourceLabel) ~= "string" or sourceLabel == "" then
    return nil
  end

  if runtimeNamespace.RaidBossOrdering.IsRaidInstance(item.instanceID) then
    local bossName = runtimeNamespace.RaidBossOrdering.ResolveBossName(item.encounterID, item.instanceID)
    if type(bossName) ~= "string" or bossName == "" then
      return nil
    end

    return string.format("%s%s - %s", buildInlineAtlasMarkup(TOOLTIP_SOURCE_RAID_ATLAS), sourceLabel, bossName)
  end

  return string.format("%s%s", buildInlineAtlasMarkup(TOOLTIP_SOURCE_DUNGEON_ATLAS), sourceLabel)
end

function TrackerRenderData.resolveEffectiveDisplayLink(runtimeNamespace, item, bestOwnedLinks)
  bestOwnedLinks = bestOwnedLinks or runtimeNamespace.state.bestOwnedLinks or {}
  local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
  local bestOwnedLink = key and bestOwnedLinks[key] or nil
  if type(bestOwnedLink) == "string" and bestOwnedLink ~= "" then
    return bestOwnedLink
  end

  local selectedVariantRef = runtimeNamespace.ItemResolver.getVariantRef(item.selectedVariantRef)
  if selectedVariantRef then
    return selectedVariantRef
  end

  return runtimeNamespace.ItemResolver.getTooltipRef({ itemID = item.itemID })
end

function TrackerRenderData.buildTrackedGroups(runtimeNamespace)
  local trackedItems = runtimeNamespace.WishlistStore.getTrackedItems(runtimeNamespace.GetCurrentDb(), runtimeNamespace.GetCharacterKey())
  local renderItems = {}
  local bestOwnedLinks = runtimeNamespace.state.bestOwnedLinks or {}
  local groupingMode = runtimeNamespace.GetTrackerGroupingMode()

  for _, item in ipairs(trackedItems) do
    local effectiveDisplayLink = TrackerRenderData.resolveEffectiveDisplayLink(runtimeNamespace, item, bestOwnedLinks)
    local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
    local sourceLabel = resolveInstanceName(item.instanceID)
    local itemName = runtimeNamespace.GetItemInfoName(effectiveDisplayLink) or runtimeNamespace.GetItemInfoName(item.itemID) or
        ("Item " .. tostring(item.itemID))
    local group = runtimeNamespace.TrackerGroups.resolveGroup(groupingMode, {
      instanceID = item.instanceID,
      instanceName = sourceLabel,
      inventoryType = item.inventoryType,
      slotLabel = getInventoryTypeLabel(runtimeNamespace, item.inventoryType),
    }, runtimeNamespace.GetText("OTHER"))
    local raidSource = runtimeNamespace.RaidBossOrdering.IsRaidInstance(item.instanceID)
    local bossName = raidSource and runtimeNamespace.RaidBossOrdering.ResolveBossName(item.encounterID, item.instanceID) or nil
    local tooltipFooter = buildTooltipFooter(runtimeNamespace, groupingMode, {
      instanceID = item.instanceID,
      encounterID = item.encounterID,
    })
    local bossRank = bossName and runtimeNamespace.RaidBossOrdering.GetEncounterRank(item.encounterID, item.instanceID) or nil

    table.insert(renderItems, {
      itemID = item.itemID,
      itemName = itemName,
      groupKey = group.key,
      groupLabel = group.label,
      groupSortIndex = group.sortIndex,
      instanceID = item.instanceID,
      isPossessed = runtimeNamespace.state.possessed[key] == true,
      bossName = bossName,
      bossRank = bossRank,
      tooltipRef = effectiveDisplayLink,
      displayLink = effectiveDisplayLink,
      sourceLabel = sourceLabel,
      inventoryType = item.inventoryType,
      tooltipFooter = tooltipFooter,
      isRaidSource = raidSource,
    })
  end

  return runtimeNamespace.TrackerGroups.buildGroups(renderItems, {
    groupBy = groupingMode,
    otherLabel = runtimeNamespace.GetText("OTHER"),
  })
end

if type(namespace) == "table" then
  namespace.TrackerRenderData = TrackerRenderData
end

return TrackerRenderData
