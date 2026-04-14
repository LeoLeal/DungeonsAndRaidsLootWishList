local _, namespace = ...

local TrackerPreferences = {}

local function ensureTrackerState(character)
  local legacyCollapsedGroups = character.collapsedGroups or {}

  character.tracker = character.tracker or {}
  character.tracker.groupBy = character.tracker.groupBy == "slot" and "slot" or "source"
  character.tracker.collapsedGroupsByMode = character.tracker.collapsedGroupsByMode or {}
  character.tracker.collapsedGroupsByMode.source = character.tracker.collapsedGroupsByMode.source or {}
  character.tracker.collapsedGroupsByMode.slot = character.tracker.collapsedGroupsByMode.slot or {}

  if not character.tracker.legacyCollapsedGroupsMigrated then
    for groupKey, collapsed in pairs(legacyCollapsedGroups) do
      if collapsed then
        character.tracker.collapsedGroupsByMode.source[groupKey] = true
      end
    end

    character.tracker.legacyCollapsedGroupsMigrated = true
  end

  return character.tracker
end

local function getCollapsedGroups(character, groupBy)
  local tracker = ensureTrackerState(character)
  local mode = groupBy == "slot" and "slot" or "source"
  tracker.collapsedGroupsByMode[mode] = tracker.collapsedGroupsByMode[mode] or {}
  return tracker.collapsedGroupsByMode[mode]
end

function TrackerPreferences.ensureTrackerState(character)
  return ensureTrackerState(character)
end

function TrackerPreferences.getGroupingMode(character)
  return ensureTrackerState(character).groupBy
end

function TrackerPreferences.setGroupingMode(character, groupBy)
  local tracker = ensureTrackerState(character)
  tracker.groupBy = groupBy == "slot" and "slot" or "source"
  return tracker.groupBy
end

function TrackerPreferences.setGroupCollapsed(character, groupBy, groupKey, collapsed)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  collapsedGroups[groupKey] = collapsed and true or nil
end

function TrackerPreferences.isGroupCollapsed(character, groupBy, groupKey)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  return collapsedGroups[groupKey] == true
end

function TrackerPreferences.toggleGroupCollapse(character, groupBy, groupKey)
  local collapsedGroups = getCollapsedGroups(character, groupBy)
  local currentState = collapsedGroups[groupKey] == true
  TrackerPreferences.setGroupCollapsed(character, groupBy, groupKey, not currentState)
  return not currentState
end

if type(namespace) == "table" then
  namespace.TrackerPreferences = TrackerPreferences
end

return TrackerPreferences
