local _, namespace = ...

local LootRowItemData = {}
local NAMED_TEXT_REGION_KEYS = { "name", "text", "label", "itemName", "Name" }

local function getRegionText(region)
  if not region or not region.GetText then
    return nil
  end

  local text = region:GetText()
  if text and text ~= "" then
    return text
  end

  return nil
end

local function findNamedTextRegion(frame)
  for _, key in ipairs(NAMED_TEXT_REGION_KEYS) do
    local region = frame[key]
    if getRegionText(region) then
      return region
    end
  end

  return nil
end

local function extractTextFromFrame(frame)
  local namedRegion = findNamedTextRegion(frame)
  if namedRegion then
    return namedRegion:GetText()
  end

  local regions = { frame:GetRegions() }
  for _, region in ipairs(regions) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      local text = getRegionText(region)
      if text then
        return text
      end
    end
  end

  return nil
end

function LootRowItemData.GetPrimaryTextRegion(frame)
  local namedRegion = findNamedTextRegion(frame)
  if namedRegion then
    return namedRegion
  end

  local bestRegion = nil
  local bestTop = nil
  local regions = { frame:GetRegions() }
  for _, region in ipairs(regions) do
    if region.GetObjectType and region:GetObjectType() == "FontString" then
      if getRegionText(region) then
        local top = region.GetTop and region:GetTop() or 0
        if bestRegion == nil or top > bestTop then
          bestRegion = region
          bestTop = top
        end
      end
    end
  end

  return bestRegion
end

function LootRowItemData.Build(runtimeNamespace, frame)
  local data = frame.data or frame.info or frame.itemInfo
  local itemID = frame.itemID or frame.itemId or (data and (data.itemID or data.itemId or data.id))
  local itemLink = frame.link or frame.itemLink or (data and (data.link or data.itemLink))

  if not itemID and itemLink then
    itemID = runtimeNamespace.ItemResolver.getItemIdFromLink(itemLink)
  end

  if not itemID then
    return nil
  end

  local encounterID = frame.encounterID or frame.bossID or (data and (data.encounterID or data.bossID))
  if not encounterID and EncounterJournal then
    encounterID = EncounterJournal.encounterID
  end

  local instanceID = frame.instanceID or (data and data.instanceID)
  if not instanceID and EncounterJournal then
    instanceID = EncounterJournal.instanceID
  end

  return {
    itemID = itemID,
    itemLink = itemLink,
    selectedVariantRef = runtimeNamespace.ItemResolver.getVariantRef(itemLink),
    itemName = extractTextFromFrame(frame),
    encounterID = encounterID,
    instanceID = instanceID,
    instanceName = runtimeNamespace.MetadataCapture.GetCurrentSourceLabel(runtimeNamespace, {
      itemData = data,
      frame = frame,
      currentTitle = EncounterJournal and EncounterJournal.instanceSelect and EncounterJournal.instanceSelect.title and
        EncounterJournal.instanceSelect.title.GetText and EncounterJournal.instanceSelect.title:GetText() or nil,
    }),
  }
end

if type(namespace) == "table" then
  namespace.LootRowItemData = LootRowItemData
end

return LootRowItemData
