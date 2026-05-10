local _, namespace = ...

local FrameUtils = {}

function FrameUtils.IsCursorOverFrame(frame)
  if not frame or type(frame.IsShown) ~= "function" or not frame:IsShown() then
    return false
  end

  if type(GetCursorPosition) ~= "function" then
    return false
  end

  local left = frame.GetLeft and frame:GetLeft() or nil
  local right = frame.GetRight and frame:GetRight() or nil
  local top = frame.GetTop and frame:GetTop() or nil
  local bottom = frame.GetBottom and frame:GetBottom() or nil
  if not left or not right or not top or not bottom then
    return false
  end

  local scale = UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
  local cursorX, cursorY = GetCursorPosition()
  cursorX = cursorX / scale
  cursorY = cursorY / scale

  return cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

if type(namespace) == "table" then
  namespace.FrameUtils = FrameUtils
end

return FrameUtils
