local TrackerRowStyle = {}

TrackerRowStyle.CHECK_ATLAS = "ui-questtracker-tracker-check"
TrackerRowStyle.CHECK_SIZE = 16

function TrackerRowStyle.getRowLayout(isComplete)
  if isComplete then
    return {
      checkLeftOffset = 12,
      textLeftOffset = 28,
    }
  end

  return {
    checkLeftOffset = 8,
    textLeftOffset = 20,
  }
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TrackerRowStyle = TrackerRowStyle
end

return TrackerRowStyle
