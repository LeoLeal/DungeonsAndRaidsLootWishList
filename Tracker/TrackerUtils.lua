local _, namespace = ...

local TrackerUtils = {}

function TrackerUtils.IsDescendantOf(frame, ancestor)
  while frame do
    if frame == ancestor then
      return true
    end

    if type(frame.GetParent) ~= "function" then
      break
    end

    frame = frame:GetParent()
  end

  return false
end

if type(namespace) == "table" then
  namespace.TrackerUtils = TrackerUtils
end

return TrackerUtils
