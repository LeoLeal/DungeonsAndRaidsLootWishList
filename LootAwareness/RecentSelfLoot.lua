local _, namespace = ...

local RecentSelfLoot = {}

local RECENT_SELF_LOOT_TTL_SECONDS = 3

local function getNow()
  if type(GetTime) == "function" then
    return GetTime()
  end

  return 0
end

local function prune(runtimeNamespace, now)
  local recentSelfLootByKey = runtimeNamespace.state.recentSelfLootByKey or {}
  runtimeNamespace.state.recentSelfLootByKey = recentSelfLootByKey

  for key, timestamp in pairs(recentSelfLootByKey) do
    if type(timestamp) ~= "number" or (now - timestamp) > RECENT_SELF_LOOT_TTL_SECONDS then
      recentSelfLootByKey[key] = nil
    end
  end
end

function RecentSelfLoot.Mark(runtimeNamespace, itemID)
  if type(itemID) ~= "number" then
    return
  end

  local now = getNow()
  prune(runtimeNamespace, now)
  local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = itemID })
  if key then
    runtimeNamespace.state.recentSelfLootByKey[key] = now
  end
end

function RecentSelfLoot.WasRecent(runtimeNamespace, itemID)
  if type(itemID) ~= "number" then
    return false
  end

  local now = getNow()
  prune(runtimeNamespace, now)
  local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = itemID })
  if not key then
    return false
  end

  return runtimeNamespace.state.recentSelfLootByKey[key] ~= nil
end

if type(namespace) == "table" then
  namespace.RecentSelfLoot = RecentSelfLoot
end

return RecentSelfLoot
