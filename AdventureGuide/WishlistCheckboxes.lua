local _, namespace = ...

local WishlistCheckboxes = {}

local checkboxByButton = setmetatable({}, { __mode = "k" })
local buttonByCheckbox = setmetatable({}, { __mode = "k" })
local itemDataByButton = setmetatable({}, { __mode = "k" })
local checkboxOverlay = nil

local function ensureCheckboxOverlay()
  local scrollBox = namespace.LootRowScanner.GetLootScrollBox()
  if not scrollBox then
    return nil
  end

  if checkboxOverlay and checkboxOverlay:GetParent() ~= scrollBox then
    checkboxOverlay:Hide()
    checkboxOverlay:SetParent(scrollBox)
    checkboxOverlay:ClearAllPoints()
    checkboxOverlay:SetAllPoints(scrollBox)
  end

  if not checkboxOverlay then
    checkboxOverlay = CreateFrame("Frame", nil, scrollBox)
    checkboxOverlay:SetAllPoints(scrollBox)
    checkboxOverlay:EnableMouse(false)
  end

  checkboxOverlay:SetFrameStrata(scrollBox:GetFrameStrata())
  checkboxOverlay:SetFrameLevel((scrollBox:GetFrameLevel() or 0) + 20)
  checkboxOverlay:Show()
  return checkboxOverlay
end

local function ensureCheckbox(runtimeNamespace, lootButton)
  local checkbox = checkboxByButton[lootButton]
  if checkbox then
    return checkbox
  end

  local checkboxParent = checkboxOverlay or namespace.LootRowScanner.GetLootScrollBox() or EncounterJournal or UIParent
  checkbox = CreateFrame("CheckButton", nil, checkboxParent, "UICheckButtonTemplate")
  checkbox:SetSize(24, 24)
  checkbox:SetFrameStrata("DIALOG")
  checkbox:HookScript("OnClick", function(self)
    local ownerButton = buttonByCheckbox[self]
    local itemData = ownerButton and itemDataByButton[ownerButton] or nil
    if self.isUpdating or not itemData then
      return
    end

    runtimeNamespace.SetTrackedFromItemData(itemData, self:GetChecked())
  end)

  checkboxByButton[lootButton] = checkbox
  buttonByCheckbox[checkbox] = lootButton
  return checkbox
end

local function positionCheckbox(lootButton, checkbox)
  local overlayParent = ensureCheckboxOverlay()
  checkbox:ClearAllPoints()
  checkbox:SetParent(overlayParent or EncounterJournal or UIParent)
  if lootButton and lootButton.GetFrameLevel then
    checkbox:SetFrameLevel((lootButton:GetFrameLevel() or 0) + 30)
  end

  local textRegion = namespace.LootRowItemData.GetPrimaryTextRegion(lootButton)
  if textRegion then
    checkbox:SetPoint("LEFT", textRegion, "RIGHT", 0, 0)
  else
    checkbox:SetPoint("RIGHT", lootButton, "RIGHT", 0, 0)
  end
end

function WishlistCheckboxes.SyncButton(runtimeNamespace, frame, shouldShowCheckboxes)
  local checkbox = checkboxByButton[frame]
  if checkbox and not shouldShowCheckboxes then
    checkbox:Hide()
    itemDataByButton[frame] = nil
    return
  end

  if shouldShowCheckboxes then
    local itemData = namespace.LootRowItemData.Build(runtimeNamespace, frame)
    if itemData then
      checkbox = ensureCheckbox(runtimeNamespace, frame)
      positionCheckbox(frame, checkbox)
      itemDataByButton[frame] = itemData
      checkbox.isUpdating = true
      checkbox:SetChecked(runtimeNamespace.IsTrackedItem(itemData.itemID))
      checkbox.isUpdating = false
      checkbox:Show()
    elseif checkbox then
      checkbox:Hide()
      itemDataByButton[frame] = nil
    end
  end
end

function WishlistCheckboxes.Cleanup(shouldShowCheckboxes, seenButtons)
  for button, checkbox in pairs(checkboxByButton) do
    if checkbox and (not shouldShowCheckboxes or not seenButtons[button]) then
      checkbox:Hide()
      itemDataByButton[button] = nil
    end
  end
end

if type(namespace) == "table" then
  namespace.WishlistCheckboxes = WishlistCheckboxes
end

return WishlistCheckboxes
