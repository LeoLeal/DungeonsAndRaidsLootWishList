local _, namespace = ...

local RollBadgeLifecycle = {}

local function getRuntimeState(runtimeNamespace)
  if type(runtimeNamespace) ~= "table" then
    return nil
  end

  runtimeNamespace.state = runtimeNamespace.state or {}
  return runtimeNamespace.state
end

local function installFrameHooks(runtimeNamespace, frame)
  if not frame or frame.LootWishListBadgeHooksInstalled or not frame.HookScript then
    return
  end

  frame.LootWishListBadgeHooksInstalled = true
  frame:HookScript("OnShow", function(self)
    runtimeNamespace.RollBadgeLifecycle.SyncFrame(runtimeNamespace, self)
  end)
  frame:HookScript("OnHide", function(self)
    runtimeNamespace.RollBadgeView.HideForFrame(self)
  end)
end

function RollBadgeLifecycle.SyncFrame(runtimeNamespace, frame)
  if not frame then
    return false
  end

  if frame.IsShown and not frame:IsShown() then
    runtimeNamespace.RollBadgeView.HideForFrame(frame)
    return false
  end

  return runtimeNamespace.RollBadgeView.SyncFrame(runtimeNamespace, frame)
end

function RollBadgeLifecycle.Initialize(runtimeNamespace)
  if not runtimeNamespace or not runtimeNamespace.RollFrameLocator or not runtimeNamespace.RollBadgeView then
    return false
  end

  local state = getRuntimeState(runtimeNamespace)
  if state and state.rollBadgeLifecycleInitialized then
    return true
  end

  local sawFrame = false

  runtimeNamespace.RollFrameLocator.forEach(function(frame)
    sawFrame = true
    installFrameHooks(runtimeNamespace, frame)
    if not frame.LootWishListBadgePrepared then
      frame.LootWishListBadgePrepared = true
      runtimeNamespace.RollBadgeView.PrepareFrame(frame)
    end

    if frame.IsShown and frame:IsShown() then
      RollBadgeLifecycle.SyncFrame(runtimeNamespace, frame)
    end
  end)

  if state and sawFrame then
    state.rollBadgeLifecycleInitialized = true
  end

  return sawFrame
end

function RollBadgeLifecycle.SyncRoll(runtimeNamespace, rollID)
  RollBadgeLifecycle.Initialize(runtimeNamespace)

  local frame = runtimeNamespace.RollFrameLocator.findById(rollID)
  if not frame then
    return false
  end

  return RollBadgeLifecycle.SyncFrame(runtimeNamespace, frame)
end

if type(namespace) == "table" then
  namespace.RollBadgeLifecycle = RollBadgeLifecycle
end

return RollBadgeLifecycle
