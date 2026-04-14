local LootAlertDialog = {}

local lootAlertFrame = nil
local lootAlertTooltip = CreateFrame("GameTooltip", "LootWishListAlertTooltip", UIParent, "GameTooltipTemplate")
local alertNamespace = nil

local LOOT_ALERT_WIDTH = 360
local LOOT_ALERT_ITEM_ICON_SIZE = 40
local LOOT_ALERT_ITEM_NAME_WIDTH = 150
local LOOT_ALERT_ITEM_GAP = 16

local function playAlertSound(soundKit)
  if type(PlaySound) ~= "function" or type(SOUNDKIT) ~= "table" then
    return
  end

  local soundID = SOUNDKIT[soundKit]
  if soundID then
    PlaySound(soundID)
  end
end

local function buildAlertItemLink(record)
  if type(record.itemLink) == "string" and record.itemLink:find("item:") then
    return record.itemLink
  end

  if record.itemID and type(GetItemInfo) == "function" then
    local itemLink = select(2, GetItemInfo(record.itemID))
    if itemLink then
      return itemLink
    end
  end

  if record.itemID then
    local itemName = record.itemName or ("Item " .. tostring(record.itemID))
    return string.format("|Hitem:%d::::::::::::|h[%s]|h", record.itemID, itemName)
  end

  return nil
end

local function getAlertItemIcon(record)
  local itemLink = buildAlertItemLink(record)
  if type(GetItemIcon) ~= "function" then
    return nil
  end

  if itemLink then
    return GetItemIcon(itemLink)
  end

  if record.itemID then
    return GetItemIcon(record.itemID)
  end

  return nil
end

local function getAlertItemDisplayName(record, itemLink)
  local itemName = itemLink
  if type(itemName) ~= "string" or itemName == "" then
    itemName = record.itemName
  end

  if type(itemName) ~= "string" then
    return ""
  end

  local bracketedName = itemName:match("|h%[(.-)%]|h") or itemName:match("%[(.-)%]")
  if bracketedName then
    itemName = bracketedName
  end

  itemName = itemName:gsub("^%[", ""):gsub("%]$", "")
  return itemName
end

local function getAlertItemColor(itemLink)
  if type(itemLink) == "string" then
    local hexColor = itemLink:match("|c[fF][fF](%x%x%x%x%x%x)")
    if hexColor and #hexColor == 6 then
      local r = tonumber(hexColor:sub(1, 2), 16)
      local g = tonumber(hexColor:sub(3, 4), 16)
      local b = tonumber(hexColor:sub(5, 6), 16)
      if r and g and b then
        return r / 255, g / 255, b / 255
      end
    end
  end

  local quality = nil
  if type(GetItemInfo) == "function" and type(itemLink) == "string" then
    quality = select(3, GetItemInfo(itemLink))
  end

  if quality and type(GetItemQualityColor) == "function" then
    local r, g, b = GetItemQualityColor(quality)
    if r and g and b then
      return r, g, b
    end
  end

  return 1, 1, 1
end

local function hideLootAlertTooltip()
  if lootAlertTooltip and alertNamespace and alertNamespace.TooltipCompare and alertNamespace.TooltipCompare.hide then
    alertNamespace.TooltipCompare.hide(lootAlertTooltip)
  elseif lootAlertTooltip then
    lootAlertTooltip:Hide()
  end
end

local function showLootAlertTooltip(anchor, itemLink)
  if not lootAlertTooltip or not anchor or type(itemLink) ~= "string" or itemLink == "" then
    return
  end

  hideLootAlertTooltip()
  lootAlertTooltip:SetOwner(anchor, "ANCHOR_RIGHT")
  lootAlertTooltip:SetHyperlink(itemLink)
  lootAlertTooltip:Show()

  if alertNamespace and alertNamespace.TooltipCompare and alertNamespace.TooltipCompare.showComparison then
    alertNamespace.TooltipCompare.showComparison(lootAlertTooltip, anchor)
  end
end

function LootAlertDialog.Close()
  hideLootAlertTooltip()

  if lootAlertFrame and lootAlertFrame:IsShown() then
    playAlertSound("IG_MAINMENU_CLOSE")
    lootAlertFrame:Hide()
  end
end

function LootAlertDialog.IsShown()
  return lootAlertFrame and lootAlertFrame:IsShown() or false
end

local function ensureLootAlertFrame(namespace)
  if lootAlertFrame then
    return lootAlertFrame
  end

  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  lootAlertFrame = CreateFrame("Frame", "LootWishListAlertFrame", UIParent, template)
  lootAlertFrame:SetSize(LOOT_ALERT_WIDTH, 156)
  lootAlertFrame:SetFrameStrata("DIALOG")
  lootAlertFrame:SetToplevel(true)
  lootAlertFrame:SetClampedToScreen(true)
  lootAlertFrame:EnableMouse(true)

  if type(UISpecialFrames) == "table" then
    local known = false
    for _, frameName in ipairs(UISpecialFrames) do
      if frameName == "LootWishListAlertFrame" then
        known = true
        break
      end
    end
    if not known then
      table.insert(UISpecialFrames, "LootWishListAlertFrame")
    end
  end

  if lootAlertFrame.SetBackdrop then
    lootAlertFrame:SetBackdrop({
      bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
      edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end
  lootAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 220)

  lootAlertFrame.text = lootAlertFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  lootAlertFrame.text:SetPoint("TOPLEFT", lootAlertFrame, "TOPLEFT", 24, -26)
  lootAlertFrame.text:SetPoint("TOPRIGHT", lootAlertFrame, "TOPRIGHT", -24, -26)
  lootAlertFrame.text:SetJustifyH("CENTER")
  lootAlertFrame.text:SetJustifyV("TOP")

  lootAlertFrame.itemPanel = CreateFrame("Frame", nil, lootAlertFrame, template)
  lootAlertFrame.itemPanel:SetPoint("TOPLEFT", lootAlertFrame.text, "BOTTOMLEFT", 18, -14)
  lootAlertFrame.itemPanel:SetPoint("TOPRIGHT", lootAlertFrame.text, "BOTTOMRIGHT", -18, -14)
  lootAlertFrame.itemPanel:SetHeight(52)

  lootAlertFrame.itemButton = CreateFrame("Button", nil, lootAlertFrame.itemPanel)
  lootAlertFrame.itemButton:SetSize(LOOT_ALERT_ITEM_ICON_SIZE + LOOT_ALERT_ITEM_GAP + LOOT_ALERT_ITEM_NAME_WIDTH, 38)
  lootAlertFrame.itemButton:SetPoint("CENTER", lootAlertFrame.itemPanel, "CENTER", 0, 0)

  lootAlertFrame.itemButton.icon = lootAlertFrame.itemButton:CreateTexture(nil, "ARTWORK")
  lootAlertFrame.itemButton.icon:SetSize(LOOT_ALERT_ITEM_ICON_SIZE, LOOT_ALERT_ITEM_ICON_SIZE)
  lootAlertFrame.itemButton.icon:SetPoint("LEFT", lootAlertFrame.itemButton, "LEFT", 0, 0)

  lootAlertFrame.itemButton.name = lootAlertFrame.itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  lootAlertFrame.itemButton.name:SetPoint("LEFT", lootAlertFrame.itemButton.icon, "RIGHT", LOOT_ALERT_ITEM_GAP, 0)
  lootAlertFrame.itemButton.name:SetWidth(LOOT_ALERT_ITEM_NAME_WIDTH)
  lootAlertFrame.itemButton.name:SetHeight(38)
  lootAlertFrame.itemButton.name:SetJustifyH("LEFT")
  lootAlertFrame.itemButton.name:SetJustifyV("MIDDLE")
  lootAlertFrame.itemButton.name:SetSpacing(1)
  do
    local font, size, flags = lootAlertFrame.itemButton.name:GetFont()
    if font and size then
      lootAlertFrame.itemButton.name:SetFont(font, size + 2, flags)
    end
  end

  lootAlertFrame.itemButton.nameFrame = lootAlertFrame.itemButton:CreateTexture(nil, "ARTWORK")
  lootAlertFrame.itemButton.nameFrame:SetTexture("Interface\\QuestFrame\\UI-QuestItemNameFrame")
  lootAlertFrame.itemButton.nameFrame:SetSize(140, 62)
  lootAlertFrame.itemButton.nameFrame:SetPoint("BOTTOMRIGHT", lootAlertFrame.itemButton.name, "BOTTOMRIGHT", 13, -12)
  lootAlertFrame.itemButton.nameFrame:SetPoint("TOPLEFT", lootAlertFrame.itemButton.name, "TOPLEFT", -21, 12)

  lootAlertFrame.itemButton:SetScript("OnEnter", function(self)
    local record = lootAlertFrame and lootAlertFrame.record or nil
    local itemLink = record and buildAlertItemLink(record) or nil
    if not itemLink then
      return
    end

    showLootAlertTooltip(self, itemLink)
  end)
  lootAlertFrame.itemButton:SetScript("OnLeave", function()
    hideLootAlertTooltip()
  end)

  lootAlertFrame.button1 = CreateFrame("Button", nil, lootAlertFrame, "UIPanelButtonTemplate")
  lootAlertFrame.button1:SetSize(120, 22)
  lootAlertFrame.button1:SetPoint("BOTTOM", lootAlertFrame, "BOTTOM", 0, 20)
  lootAlertFrame.button1:SetText(OKAY or "OK")
  lootAlertFrame.button1:SetScript("OnClick", function()
    LootAlertDialog.Close()
  end)

  lootAlertFrame:SetScript("OnHide", function(self)
    hideLootAlertTooltip()
    self.record = nil

    if namespace.state.pendingLootAlerts and #namespace.state.pendingLootAlerts > 0 and not namespace.state.lootAlertFlushQueued then
      namespace.state.lootAlertFlushQueued = true
      namespace.QueueAfterCombat(function()
        namespace.LootAwareness.FlushAlerts(namespace)
      end)
    end
  end)

  return lootAlertFrame
end

function LootAlertDialog.ShowFromRecord(namespace, record)
  if type(record) ~= "table" then
    return
  end

  local playerName = record.playerName
  local itemLink = buildAlertItemLink(record)
  if type(playerName) ~= "string" or not itemLink then
    return
  end

  local frame = ensureLootAlertFrame(namespace)
  if not frame then
    return
  end

  local message = string.format(
    namespace.GetText("PLAYER_LOOTED_WISHLIST_ITEM") or "%s looted an item on your Wishlist!",
    "|cffffcc00" .. playerName .. "|cFFFFFFFF"
  )

  frame.record = record
  frame.text:SetText(message)
  frame.itemButton.icon:SetTexture(getAlertItemIcon(record) or 134400)
  frame.itemButton.name:SetText(getAlertItemDisplayName(record, itemLink))
  frame.itemButton.name:SetTextColor(getAlertItemColor(itemLink))
  frame.itemButton.itemLink = itemLink
  playAlertSound("IG_MAINMENU_OPEN")
  frame:Show()
end

local _, namespace = ...
if type(namespace) == "table" then
  alertNamespace = namespace
  namespace.LootAlertDialog = LootAlertDialog
end

return LootAlertDialog
