local _, namespace = ...

local LootRowScanner = {}

local function frameOrAncestorNameMatches(frame, patterns)
  while frame do
    local name = frame.GetName and frame:GetName() or nil
    if type(name) == "string" then
      local lowered = name:lower()
      for _, pattern in ipairs(patterns) do
        if lowered:find(pattern, 1, true) then
          return true
        end
      end
    end

    frame = frame:GetParent()
  end

  return false
end

local function isLikelyLootButton(frame)
  local data = frame.data or frame.info or frame.itemInfo
  local hasItemIdentity = frame.itemID or frame.itemId or frame.itemLink or frame.link or
    (data and (data.itemID or data.itemId or data.link or data.itemLink))
  if not hasItemIdentity then
    return false
  end

  if frameOrAncestorNameMatches(frame, { "instanceselect", "dropdown", "filter", "nav" }) then
    return false
  end

  if frameOrAncestorNameMatches(frame, { "loot" }) then
    return true
  end

  if data and (data.slot or data.encounterID or data.bossID) then
    return true
  end

  if frame.icon or frame.Icon then
    return true
  end

  return false
end

function LootRowScanner.GetLootScrollBox()
  return EncounterJournal and EncounterJournal.encounter and EncounterJournal.encounter.info and
    EncounterJournal.encounter.info.LootContainer and EncounterJournal.encounter.info.LootContainer.ScrollBox or nil
end

local function visitLootDescendants(frame, callback, visited)
  if not frame or visited[frame] then
    return
  end

  visited[frame] = true

  if frame ~= LootRowScanner.GetLootScrollBox() and frame.GetObjectType and frame:GetObjectType() == "Button" and frame:IsShown() and isLikelyLootButton(frame) then
    callback(frame)
  end

  if frame.GetChildren then
    for _, child in ipairs({ frame:GetChildren() }) do
      visitLootDescendants(child, callback, visited)
    end
  end
end

function LootRowScanner.ForEachVisibleLootButton(callback)
  local scrollBox = LootRowScanner.GetLootScrollBox()
  if not scrollBox or not scrollBox:IsShown() then
    return
  end

  if type(scrollBox.ForEachFrame) == "function" then
    scrollBox:ForEachFrame(function(frame)
      if frame and frame:IsShown() and frame.GetObjectType and frame:GetObjectType() == "Button" and isLikelyLootButton(frame) then
        callback(frame)
      end
    end)
    return
  end

  visitLootDescendants(scrollBox, callback, {})
end

if type(namespace) == "table" then
  namespace.LootRowScanner = LootRowScanner
end

return LootRowScanner
