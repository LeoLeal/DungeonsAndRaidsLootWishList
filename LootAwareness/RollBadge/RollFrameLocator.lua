local _, namespace = ...

local RollFrameLocator = {}

local function getMaxFrames()
  local maxFrames = tonumber(NUM_GROUP_LOOT_FRAMES) or 4
  if maxFrames < 1 then
    return 4
  end

  return maxFrames
end

function RollFrameLocator.forEach(callback)
  if type(callback) ~= "function" then
    return
  end

  local maxFrames = getMaxFrames()
  for index = 1, maxFrames do
    local frame = _G["GroupLootFrame" .. index]
    if frame then
      callback(frame, index)
    end
  end
end

function RollFrameLocator.findById(rollID)
  local foundFrame = nil

  RollFrameLocator.forEach(function(frame)
    if foundFrame or not frame or not frame.IsShown or not frame:IsShown() then
      return
    end

    if frame.rollID == rollID then
      foundFrame = frame
    end
  end)

  return foundFrame
end

if type(namespace) == "table" then
  namespace.RollFrameLocator = RollFrameLocator
end

return RollFrameLocator
