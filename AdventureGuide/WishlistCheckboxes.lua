local _, namespace = ...

local WishlistCheckboxes = {}

local FAVORITE_OFF_ATLAS = "delves-scenario-heart-icon"
local FAVORITE_ON_ATLAS = "delves-scenario-heart-icon"
local FAVORITE_BUTTON_SIZE = 20
local FAVORITE_BG_OFF_ATLAS = "pvpqueue-rewardring-black"
local FAVORITE_BG_ON_ATLAS = "pvpqueue-rewardring"
local FAVORITE_ALPHA_TRACKED = 1
local FAVORITE_ALPHA_UNTRACKED = 0.66
local FAVORITE_ALPHA_PRESSED = 0.8

local favoriteButtonTooltip = CreateFrame("GameTooltip", "LootWishListFavoriteButtonTooltip", UIParent, "GameTooltipTemplate")

local buttonByLootButton = setmetatable({}, { __mode = "k" })
local lootButtonByButton = setmetatable({}, { __mode = "k" })
local itemDataByLootButton = setmetatable({}, { __mode = "k" })
local buttonOverlay = nil

local function setFavoriteButtonAlpha(button, alpha)
  if not button then
    return
  end

  if button.icon then
    button.icon:SetAlpha(alpha)
  end

  if button.bg then
    button.bg:SetAlpha(alpha)
  end
end

local function getFavoriteButtonIdleAlpha(button)
  if button and button.isTracked then
    return FAVORITE_ALPHA_TRACKED
  end

  return FAVORITE_ALPHA_UNTRACKED
end

local function restoreFavoriteButtonAlpha(button)
  setFavoriteButtonAlpha(button, getFavoriteButtonIdleAlpha(button))
end

local function ensureButtonOverlay()
  local scrollBox = namespace.LootRowScanner.GetLootScrollBox()
  if not scrollBox then
    return nil
  end

  if buttonOverlay and buttonOverlay:GetParent() ~= scrollBox then
    buttonOverlay:Hide()
    buttonOverlay:SetParent(scrollBox)
    buttonOverlay:ClearAllPoints()
    buttonOverlay:SetAllPoints(scrollBox)
  end

  if not buttonOverlay then
    buttonOverlay = CreateFrame("Frame", nil, scrollBox)
    buttonOverlay:SetAllPoints(scrollBox)
    buttonOverlay:EnableMouse(false)
  end

  buttonOverlay:SetFrameStrata(scrollBox:GetFrameStrata())
  buttonOverlay:SetFrameLevel((scrollBox:GetFrameLevel() or 0) + 20)
  buttonOverlay:Show()
  return buttonOverlay
end

local function updateFavoriteButtonState(button, tracked)
  if not button or not button.icon then
    return
  end

  button.isTracked = tracked == true
  button.icon:SetAtlas(tracked and FAVORITE_ON_ATLAS or FAVORITE_OFF_ATLAS, false)
  if tracked then
    button.icon:SetVertexColor(1, 1, 1, 1)
    if button.bg then
      button.bg:SetAtlas(FAVORITE_BG_ON_ATLAS, false)
    end
  else
    button.icon:SetVertexColor(0, 0, 0, 1)
    if button.bg then
      button.bg:SetAtlas(FAVORITE_BG_OFF_ATLAS, false)
    end
  end

  restoreFavoriteButtonAlpha(button)
end

local function positionFavoriteButton(lootButton, favoriteButton)
  local overlayParent = ensureButtonOverlay()
  favoriteButton:ClearAllPoints()
  favoriteButton:SetParent(overlayParent or EncounterJournal or UIParent)
  if lootButton and lootButton.GetFrameLevel then
    favoriteButton:SetFrameLevel((lootButton:GetFrameLevel() or 0) + 30)
  end

  local textRegion = namespace.LootRowItemData.GetPrimaryTextRegion(lootButton)
  if textRegion then
    favoriteButton:SetPoint("LEFT", textRegion, "RIGHT", -10, 0)
  else
    favoriteButton:SetPoint("RIGHT", lootButton, "RIGHT", -10, 0)
  end
end

local function ensureFavoriteButton(runtimeNamespace, lootButton)
  local favoriteButton = buttonByLootButton[lootButton]
  if favoriteButton then
    return favoriteButton
  end

  local buttonParent = buttonOverlay or namespace.LootRowScanner.GetLootScrollBox() or EncounterJournal or UIParent
  favoriteButton = CreateFrame("Button", nil, buttonParent)
  favoriteButton:SetSize(FAVORITE_BUTTON_SIZE, FAVORITE_BUTTON_SIZE)
  favoriteButton:SetFrameStrata("DIALOG")

  favoriteButton.icon = favoriteButton:CreateTexture(nil, "ARTWORK")
  favoriteButton.icon:SetPoint("CENTER", favoriteButton, "CENTER", 0, 0)
  favoriteButton.icon:SetSize(14, 14)

  favoriteButton.bg = favoriteButton:CreateTexture(nil, "BACKGROUND")
  favoriteButton.bg:SetPoint("CENTER", favoriteButton, "CENTER", 0, 0)
  favoriteButton.bg:SetSize(FAVORITE_BUTTON_SIZE * 1.5, FAVORITE_BUTTON_SIZE * 1.5)

  favoriteButton:SetScript("OnMouseDown", function(self)
    setFavoriteButtonAlpha(self, FAVORITE_ALPHA_PRESSED)
  end)
  favoriteButton:SetScript("OnMouseUp", function(self)
    restoreFavoriteButtonAlpha(self)
  end)
  favoriteButton:SetScript("OnLeave", function(self)
    restoreFavoriteButtonAlpha(self)
    favoriteButtonTooltip:Hide()
  end)
  favoriteButton:SetScript("OnClick", function(self)
    local ownerButton = lootButtonByButton[self]
    local itemData = ownerButton and itemDataByLootButton[ownerButton] or nil
    if not itemData then
      return
    end

    runtimeNamespace.WishlistTagPopover.Toggle(runtimeNamespace, ownerButton, itemData)
  end)

  favoriteButton:SetScript("OnEnter", function(self)
    local ownerButton = lootButtonByButton[self]
    local itemData = ownerButton and itemDataByLootButton[ownerButton] or nil
    if not itemData then
      return
    end

    if not runtimeNamespace.IsTrackedItem(itemData.itemID) then
      return
    end

    if runtimeNamespace.WishlistTagPopover.IsOwnerShown(ownerButton) then
      return
    end

    local tags = runtimeNamespace.GetOrderedAssignedTags(itemData.itemID)
    if not tags or #tags == 0 then
      return
    end

    local formattedTags = runtimeNamespace.FormatWishlistTagList(tags)
    favoriteButtonTooltip:SetOwner(self, "ANCHOR_RIGHT")
    favoriteButtonTooltip:ClearLines()
    favoriteButtonTooltip:AddLine(formattedTags, 1, 1, 1)
    favoriteButtonTooltip:Show()
  end)

  buttonByLootButton[lootButton] = favoriteButton
  lootButtonByButton[favoriteButton] = lootButton
  return favoriteButton
end

function WishlistCheckboxes.SyncButton(runtimeNamespace, frame, shouldShowCheckboxes)
  local favoriteButton = buttonByLootButton[frame]
  if favoriteButton and not shouldShowCheckboxes then
    runtimeNamespace.WishlistTagPopover.HideForOwner(frame)
    favoriteButton:Hide()
    itemDataByLootButton[frame] = nil
    return
  end

  if shouldShowCheckboxes then
    local itemData = namespace.LootRowItemData.Build(runtimeNamespace, frame)
    if itemData then
      favoriteButton = ensureFavoriteButton(runtimeNamespace, frame)
      positionFavoriteButton(frame, favoriteButton)
      itemDataByLootButton[frame] = itemData
      updateFavoriteButtonState(favoriteButton, runtimeNamespace.IsTrackedItem(itemData.itemID))
      favoriteButton:Show()
      runtimeNamespace.WishlistTagPopover.RefreshOwner(runtimeNamespace, frame, itemData)
    elseif favoriteButton then
      runtimeNamespace.WishlistTagPopover.HideForOwner(frame)
      favoriteButton:Hide()
      itemDataByLootButton[frame] = nil
    end
  end
end

function WishlistCheckboxes.Cleanup(shouldShowCheckboxes, seenButtons)
  for button, favoriteButton in pairs(buttonByLootButton) do
    if favoriteButton and (not shouldShowCheckboxes or not seenButtons[button]) then
      namespace.WishlistTagPopover.HideForOwner(button)
      favoriteButton:Hide()
      itemDataByLootButton[button] = nil
    end
  end
end

if type(namespace) == "table" then
  namespace.WishlistCheckboxes = WishlistCheckboxes
end

return WishlistCheckboxes
