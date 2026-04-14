local _, namespace = ...

local MetadataCapture = {}

function MetadataCapture.GetCurrentSourceLabel(runtimeNamespace, itemData)
  local rawItemData = itemData and (itemData.itemData or itemData) or nil

  if rawItemData and rawItemData.instanceName then
    return rawItemData.instanceName
  end

  if rawItemData and rawItemData.currentInstanceName and rawItemData.currentInstanceName ~= "" then
    return rawItemData.currentInstanceName
  end

  if itemData and itemData.currentTitle and itemData.currentTitle ~= "" then
    return itemData.currentTitle
  end

  if EncounterJournal and EncounterJournal.instanceID and type(EJ_GetInstanceInfo) == "function" then
    local instanceName = EJ_GetInstanceInfo(EncounterJournal.instanceID)
    if instanceName and instanceName ~= "" then
      return instanceName
    end
  end

  if EncounterJournal and EncounterJournal.selectedInstanceID and type(EJ_GetInstanceInfo) == "function" then
    local selectedInstanceName = EJ_GetInstanceInfo(EncounterJournal.selectedInstanceID)
    if selectedInstanceName and selectedInstanceName ~= "" then
      return selectedInstanceName
    end
  end

  if type(EJ_GetCurrentInstance) == "function" and type(EJ_GetInstanceInfo) == "function" then
    local currentInstanceID = EJ_GetCurrentInstance()
    if currentInstanceID then
      local currentInstanceName = EJ_GetInstanceInfo(currentInstanceID)
      if currentInstanceName and currentInstanceName ~= "" then
        return currentInstanceName
      end
    end
  end

  if type(EJ_GetInstanceInfo) == "function" then
    local instanceID = rawItemData and (rawItemData.instanceID or rawItemData.journalInstanceID)
    if instanceID then
      local instanceName = EJ_GetInstanceInfo(instanceID)
      if instanceName and instanceName ~= "" then
        return instanceName
      end
    end
  end

  if EncounterJournal and EncounterJournal.TitleText and EncounterJournal.TitleText.GetText then
    local currentTitle = EncounterJournal.TitleText:GetText()
    if currentTitle and currentTitle ~= "" then
      return currentTitle
    end
  end

  return runtimeNamespace.GetText("OTHER")
end

if type(namespace) == "table" then
  namespace.MetadataCapture = MetadataCapture
end

return MetadataCapture
