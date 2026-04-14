local _, namespace = ...

local JournalHooks = {}

function JournalHooks.Initialize(runtimeNamespace, refreshCallback)
  local updater = CreateFrame("Frame")
  runtimeNamespace.journalUpdater = updater

  local function startUpdater()
    updater:SetScript("OnUpdate", function(_, elapsed)
      runtimeNamespace.journalElapsed = (runtimeNamespace.journalElapsed or 0) + elapsed
      if runtimeNamespace.journalElapsed < 0.1 then
        return
      end

      runtimeNamespace.journalElapsed = 0
      refreshCallback(runtimeNamespace)
    end)
  end

  local function stopUpdater()
    updater:SetScript("OnUpdate", nil)
    runtimeNamespace.journalElapsed = 0
  end

  local function hookEncounterJournal()
    if not EncounterJournal then
      return
    end

    EncounterJournal:HookScript("OnShow", startUpdater)
    EncounterJournal:HookScript("OnHide", stopUpdater)

    if EncounterJournal:IsShown() then
      startUpdater()
    end
  end

  if EncounterJournal then
    hookEncounterJournal()
  else
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", function(self, _, addonName)
      if addonName == "Blizzard_EncounterJournal" then
        self:UnregisterAllEvents()
        hookEncounterJournal()
      end
    end)
  end

  local hookTargets = {
    "EncounterJournal_LootUpdate",
    "EncounterJournal_UpdateLootInfo",
    "EncounterJournal_UpdateFilterString",
  }

  for _, hookName in ipairs(hookTargets) do
    if type(_G[hookName]) == "function" then
      hooksecurefunc(hookName, function()
        refreshCallback(runtimeNamespace)
      end)
    end
  end
end

if type(namespace) == "table" then
  namespace.JournalHooks = JournalHooks
end

return JournalHooks
