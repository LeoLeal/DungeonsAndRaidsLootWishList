local _, namespace = ...

local TrackerRenderData = {}

local TOOLTIP_SOURCE_ATLAS_SIZE = 18
local TOOLTIP_TAG_ATLAS_SIZE = 22
local TOOLTIP_TAG_ATLAS_OFFSET_X = -1
local TOOLTIP_SOURCE_DUNGEON_ATLAS = "questlog-questtypeicon-dungeon"
local TOOLTIP_SOURCE_RAID_ATLAS = "questlog-questtypeicon-raid"
local TOOLTIP_TAG_ATLAS = "delves-scenario-heart-icon"

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

local function buildInlineAtlasMarkup(atlasName, atlasSize, offsetX, offsetY)
  if type(atlasName) ~= "string" or atlasName == "" then
    return nil
  end

  atlasSize = tonumber(atlasSize) or TOOLTIP_SOURCE_ATLAS_SIZE
  offsetX = tonumber(offsetX) or 0
  offsetY = tonumber(offsetY) or 0
  return string.format("|A:%s:%d:%d:%d:%d|a", atlasName, atlasSize, atlasSize, offsetX, offsetY)
end

local function buildSourceTooltipFooter(runtimeNamespace, item)

  local sourceLabel = resolveInstanceName(item.instanceID)
  if type(sourceLabel) ~= "string" or sourceLabel == "" then
    return nil
  end

  if runtimeNamespace.RaidBossOrdering.IsRaidInstance(item.instanceID) then
    local bossName = runtimeNamespace.RaidBossOrdering.ResolveBossName(item.encounterID, item.instanceID)
    if type(bossName) ~= "string" or bossName == "" then
      return nil
    end

    return string.format("%s  %s - %s", buildInlineAtlasMarkup(TOOLTIP_SOURCE_RAID_ATLAS), sourceLabel, bossName)
  end

  return string.format("%s  %s", buildInlineAtlasMarkup(TOOLTIP_SOURCE_DUNGEON_ATLAS), sourceLabel)
end

local function buildTagsTooltipFooter(runtimeNamespace, tags)
  if type(tags) ~= "table" or #tags == 0 then
    return nil
  end

  local formattedTags = runtimeNamespace.FormatWishlistTagList(tags)
  if formattedTags == "" then
    return nil
  end

  return string.format(
    "%s %s",
    buildInlineAtlasMarkup(TOOLTIP_TAG_ATLAS, TOOLTIP_TAG_ATLAS_SIZE, TOOLTIP_TAG_ATLAS_OFFSET_X),
    formattedTags
  )
end

local function buildTooltipFooterLines(runtimeNamespace, groupingMode, item, tags)
  local footerLines = {}
  local tagsFooter = buildTagsTooltipFooter(runtimeNamespace, tags)
  if tagsFooter then
    table.insert(footerLines, tagsFooter)
  end

  if groupingMode == "slot" then
    local sourceFooter = buildSourceTooltipFooter(runtimeNamespace, item)
    if sourceFooter then
      table.insert(footerLines, sourceFooter)
    end
  end

  return footerLines
end

local function itemMatchesTagFilter(tags, selectedLookup, normalizeTagLabel)
  if not selectedLookup then
    return true
  end

  for _, tagLabel in ipairs(tags or {}) do
    local normalized = normalizeTagLabel(tagLabel)
    if normalized and selectedLookup[normalized] then
      return true
    end
  end

  return false
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
  local selectedTagLookup = runtimeNamespace.TrackerFilterMenu.GetSelectedTagLookup(runtimeNamespace)

  for _, item in ipairs(trackedItems) do
    local orderedTags = item.tags or runtimeNamespace.GetOrderedAssignedTags(item.itemID)
    if itemMatchesTagFilter(orderedTags, selectedTagLookup, runtimeNamespace.WishlistStore.normalizeTagLabel) then
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
    local tooltipFooterLines = buildTooltipFooterLines(runtimeNamespace, groupingMode, {
      instanceID = item.instanceID,
      encounterID = item.encounterID,
    }, orderedTags)
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
      tags = orderedTags,
      tooltipFooterLines = tooltipFooterLines,
      isRaidSource = raidSource,
    })
    end
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
