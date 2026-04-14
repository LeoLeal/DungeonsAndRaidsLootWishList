local _, namespace = ...

local RaidBossOrdering = {}

local raidInstances = {}
local instanceEncounterRanks = {}

function RaidBossOrdering.IsRaidInstance(instanceID)
  if not instanceID then
    return false
  end

  if raidInstances[instanceID] ~= nil then
    return raidInstances[instanceID]
  end

  if type(EJ_GetInstanceByIndex) ~= "function" then
    return false
  end

  local index = 1
  while true do
    local id = EJ_GetInstanceByIndex(index, true)
    if not id then
      break
    end
    raidInstances[id] = true
    if id == instanceID then
      return true
    end
    index = index + 1
  end

  raidInstances[instanceID] = false
  return false
end

function RaidBossOrdering.PrimeEncounterDataForInstance(instanceID)
  if not instanceID or instanceEncounterRanks[instanceID] then
    return
  end

  instanceEncounterRanks[instanceID] = {}

  if type(EJ_SelectInstance) ~= "function" or type(EJ_GetEncounterInfoByIndex) ~= "function" then
    return
  end

  EJ_SelectInstance(instanceID)
  local encounterIndex = 1
  while true do
    local _, _, encounterID = EJ_GetEncounterInfoByIndex(encounterIndex)
    if not encounterID then
      break
    end

    instanceEncounterRanks[instanceID][encounterID] = encounterIndex
    encounterIndex = encounterIndex + 1
  end
end

function RaidBossOrdering.PrimeTrackedEncounterData(runtimeNamespace)
  local trackedItems = runtimeNamespace.WishlistStore.getTrackedItems(runtimeNamespace.GetCurrentDb(), runtimeNamespace.GetCharacterKey())
  local primed = {}

  for _, item in ipairs(trackedItems) do
    local instanceID = item.instanceID
    if RaidBossOrdering.IsRaidInstance(instanceID) and not primed[instanceID] then
      primed[instanceID] = true
      RaidBossOrdering.PrimeEncounterDataForInstance(instanceID)
    end
  end
end

function RaidBossOrdering.GetEncounterRank(encounterID, instanceID)
  if not encounterID or not instanceID then
    return 999
  end

  if not instanceEncounterRanks[instanceID] then
    return 999
  end

  return instanceEncounterRanks[instanceID][encounterID] or 999
end

function RaidBossOrdering.ResolveBossName(encounterID, instanceID)
  if not encounterID or not instanceID then
    return nil
  end

  if not RaidBossOrdering.IsRaidInstance(instanceID) then
    return nil
  end

  if type(EJ_GetEncounterInfo) == "function" then
    return EJ_GetEncounterInfo(encounterID)
  end

  return nil
end

if type(namespace) == "table" then
  namespace.RaidBossOrdering = RaidBossOrdering
end

return RaidBossOrdering
