local _, namespace = ...

local RollBadgeView = {}

local LOOT_ROLL_BADGE_ICON_ATLAS = "Banker"
local LOOT_ROLL_BADGE_ICON_SIZE = 18
local LOOT_ROLL_BADGE_GAP = 2
local LOOT_ROLL_BADGE_SIDE_PADDING = 40
local LOOT_ROLL_BADGE_GLOW_PAD_X = 120
local LOOT_ROLL_BADGE_GLOW_PAD_Y = 16

local function hideRollBadge(frame)
  if not frame or not frame.LootWishListBadge then
    return
  end

  frame.LootWishListBadge.rollID = nil
  frame.LootWishListBadge.itemID = nil
  if frame.LootWishListBadge.text then
    frame.LootWishListBadge.text:SetText("")
  end
  frame.LootWishListBadge:SetWidth(0)
  frame.LootWishListBadge:Hide()
end

local function ensureRollBadge(frame)
  if not frame then
    return nil
  end

  if frame.LootWishListBadge then
    return frame.LootWishListBadge
  end

  local badge = CreateFrame("Frame", nil, frame)
  badge:SetHeight(LOOT_ROLL_BADGE_ICON_SIZE)

  badge.glow = badge:CreateTexture(nil, "BACKGROUND")
  badge.glow:SetAtlas("pvpscoreboard-header-glow", false)
  badge.glow:SetBlendMode("ADD")
  badge.glow:SetVertexColor(1, 1, 1, 1)
  badge.glow:SetPoint("TOPLEFT", badge, "TOPLEFT", -LOOT_ROLL_BADGE_GLOW_PAD_X, LOOT_ROLL_BADGE_GLOW_PAD_Y + 14)
  badge.glow:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", LOOT_ROLL_BADGE_GLOW_PAD_X, -LOOT_ROLL_BADGE_GLOW_PAD_Y)

  badge.icon = badge:CreateTexture(nil, "OVERLAY")
  badge.icon:SetSize(LOOT_ROLL_BADGE_ICON_SIZE, LOOT_ROLL_BADGE_ICON_SIZE)
  badge.icon:SetAtlas(LOOT_ROLL_BADGE_ICON_ATLAS, false)
  badge.icon:SetPoint("LEFT", badge, "LEFT", LOOT_ROLL_BADGE_SIDE_PADDING, 0)

  badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local font, size = badge.text:GetFont()
  if font and size then
    badge.text:SetFont(font, size, "OUTLINE")
  end
  badge.text:SetShadowColor(0, 0, 0, 1)
  badge.text:SetShadowOffset(1, -1)
  badge.text:SetTextColor(1, 0.82, 0)
  badge.text:SetPoint("LEFT", badge.icon, "RIGHT", LOOT_ROLL_BADGE_GAP, 0)

  frame.LootWishListBadge = badge
  return badge
end

local function applyTrackedBadge(runtimeNamespace, frame, rollID, itemID)
  local badge = ensureRollBadge(frame)
  if not badge then
    hideRollBadge(frame)
    return false
  end

  local tags = runtimeNamespace.GetOrderedAssignedTags(itemID)
  badge.rollID = rollID
  badge.itemID = itemID
  badge.text:SetText(runtimeNamespace.GetText("WISHLIST_WITH_TAGS", runtimeNamespace.FormatWishlistTagList(tags)))
  badge:SetWidth((LOOT_ROLL_BADGE_SIDE_PADDING * 2) + LOOT_ROLL_BADGE_ICON_SIZE + LOOT_ROLL_BADGE_GAP +
    badge.text:GetStringWidth())
  badge:ClearAllPoints()
  badge:SetPoint("TOP", frame, "TOP", 0, 12)
  badge:Show()
  return true
end

function RollBadgeView.PrepareFrame(frame)
  local badge = ensureRollBadge(frame)
  if badge then
    hideRollBadge(frame)
  end

  return badge
end

function RollBadgeView.HideForFrame(frame)
  hideRollBadge(frame)
end

function RollBadgeView.SyncFrame(runtimeNamespace, frame)
  if not frame then
    return false
  end

  if frame.IsShown and not frame:IsShown() then
    hideRollBadge(frame)
    return false
  end

  local rollID = frame.rollID
  if type(rollID) ~= "number" then
    hideRollBadge(frame)
    return false
  end

  if type(GetLootRollItemLink) ~= "function" then
    hideRollBadge(frame)
    return false
  end

  local itemLink = GetLootRollItemLink(rollID)
  local itemID = runtimeNamespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID or not runtimeNamespace.IsTrackedItem(itemID) then
    hideRollBadge(frame)
    return false
  end

  return applyTrackedBadge(runtimeNamespace, frame, rollID, itemID)
end

if type(namespace) == "table" then
  namespace.RollBadgeView = RollBadgeView
end

return RollBadgeView
