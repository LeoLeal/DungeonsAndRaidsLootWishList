local _, namespace = ...

local RollFrameLocator = {}

function RollFrameLocator.findById(rollID)
  local maxFrames = NUM_GROUP_LOOT_FRAMES or 4
  for index = 1, maxFrames do
    local frame = _G["GroupLootFrame" .. index]
    if frame and frame.rollID == rollID then
      return frame
    end
  end

  return nil
end

if type(namespace) == "table" then
  namespace.RollFrameLocator = RollFrameLocator
end

return RollFrameLocator
