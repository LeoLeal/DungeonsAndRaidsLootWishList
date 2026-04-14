local TrackerRowStyle = {}

TrackerRowStyle.CHECK_ATLAS = "ui-questtracker-tracker-check"
TrackerRowStyle.CHECK_SIZE = 16
TrackerRowStyle.ITEM_TEXT_PADDING = 12
TrackerRowStyle.COMPLETE_CHECK_LEFT_OFFSET = -5
TrackerRowStyle.INCOMPLETE_DASH_LEFT_OFFSET = 1

function TrackerRowStyle.getRowLayout(isComplete)
  if isComplete then
    return {
      checkLeftOffset = TrackerRowStyle.COMPLETE_CHECK_LEFT_OFFSET,
      textLeftOffset = TrackerRowStyle.ITEM_TEXT_PADDING,
    }
  end

  return {
    checkLeftOffset = TrackerRowStyle.INCOMPLETE_DASH_LEFT_OFFSET,
    textLeftOffset = TrackerRowStyle.ITEM_TEXT_PADDING,
  }
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.TrackerRowStyle = TrackerRowStyle
end

return TrackerRowStyle
