local _, namespace = ...

local TrackerPreferences = {}

local function normalizeAttachmentMode(mode)
  return mode == "detached" and "detached" or "attached"
end

local function normalizeDetachedPosition(position)
  if type(position) ~= "table" then
    return nil
  end

  local point = type(position.point) == "string" and position.point or nil
  local relativePoint = type(position.relativePoint) == "string" and position.relativePoint or nil
  local x = tonumber(position.x)
  local y = tonumber(position.y)
  if not point or not relativePoint or x == nil or y == nil then
    return nil
  end

  return {
    point = point,
    relativePoint = relativePoint,
    x = x,
    y = y,
  }
end

local function ensureTrackerState(character)
  local legacyCollapsedGroups = character.collapsedGroups or {}

  character.tracker = character.tracker or {}
  character.tracker.groupBy = character.tracker.groupBy == "slot" and "slot" or "source"
  character.tracker.collapsedGroupsByMode = character.tracker.collapsedGroupsByMode or {}
  character.tracker.collapsedGroupsByMode.source = character.tracker.collapsedGroupsByMode.source or {}
  character.tracker.collapsedGroupsByMode.slot = character.tracker.collapsedGroupsByMode.slot or {}
  character.tracker.tagFilterSelection = type(character.tracker.tagFilterSelection) == "table" and character.tracker.tagFilterSelection or {}
  character.tracker.attachmentMode = normalizeAttachmentMode(character.tracker.attachmentMode)
  character.tracker.detachedLocked = character.tracker.detachedLocked == true
  character.tracker.detachedPosition = normalizeDetachedPosition(character.tracker.detachedPosition)

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

function TrackerPreferences.getAttachmentMode(character)
  return ensureTrackerState(character).attachmentMode
end

function TrackerPreferences.setAttachmentMode(character, mode)
  local tracker = ensureTrackerState(character)
  tracker.attachmentMode = normalizeAttachmentMode(mode)
  return tracker.attachmentMode
end

function TrackerPreferences.getDetachedPosition(character)
  return ensureTrackerState(character).detachedPosition
end

function TrackerPreferences.setDetachedPosition(character, position)
  local tracker = ensureTrackerState(character)
  tracker.detachedPosition = normalizeDetachedPosition(position)
  return tracker.detachedPosition
end

function TrackerPreferences.isDetachedLocked(character)
  return ensureTrackerState(character).detachedLocked == true
end

function TrackerPreferences.setDetachedLocked(character, locked)
  local tracker = ensureTrackerState(character)
  tracker.detachedLocked = locked == true
  return tracker.detachedLocked
end

function TrackerPreferences.toggleDetachedLocked(character)
  local currentState = TrackerPreferences.isDetachedLocked(character)
  return TrackerPreferences.setDetachedLocked(character, not currentState)
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

function TrackerPreferences.getTagFilterSelection(character)
  return ensureTrackerState(character).tagFilterSelection
end

if type(namespace) == "table" then
  namespace.TrackerPreferences = TrackerPreferences
end

return TrackerPreferences
