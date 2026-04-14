local AdventureGuide = {}

function AdventureGuide.Refresh(namespace)
  if not EncounterJournal or not EncounterJournal:IsShown() then
    return
  end

  local isDungeonTab = type(EncounterJournal_IsDungeonTabSelected) == "function" and
    EncounterJournal_IsDungeonTabSelected(EncounterJournal)
  local isRaidTab = type(EncounterJournal_IsRaidTabSelected) == "function" and
    EncounterJournal_IsRaidTabSelected(EncounterJournal)
  local shouldShowCheckboxes = isDungeonTab or isRaidTab
  local seenButtons = {}

  namespace.LootRowScanner.ForEachVisibleLootButton(function(frame)
    seenButtons[frame] = true
    namespace.WishlistCheckboxes.SyncButton(namespace, frame, shouldShowCheckboxes)
  end)

  namespace.WishlistCheckboxes.Cleanup(shouldShowCheckboxes, seenButtons)
end

function AdventureGuide.Initialize(namespace)
  namespace.JournalHooks.Initialize(namespace, AdventureGuide.Refresh)
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.AdventureGuide = AdventureGuide
end

return AdventureGuide
