-- Run from the addon root with: lua5.1 tests/item_api_compatibility.lua
local tests = {}

local function test(name, callback)
  tests[#tests + 1] = { name = name, callback = callback }
end

local function equal(actual, expected, message)
  if actual ~= expected then
    error((message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

-- Only record calls needed by these tests; this is not a frame/layout simulator.
local function widget(parent)
  local value = { parent = parent, scripts = {}, shown = false }
  local function noop() end
  for _, name in ipairs({
    "ClearAllPoints", "SetPoint", "SetFontObject", "RegisterForClicks",
    "SetSize", "SetFrameStrata", "SetToplevel", "SetClampedToScreen", "EnableMouse",
    "SetAllPoints", "SetBackdrop", "SetJustifyH", "SetJustifyV", "SetSpacing",
    "SetFont", "SetWordWrap", "SetAutoFocus", "ClearFocus", "SetNormalAtlas",
    "SetPushedAtlas", "SetDisabledAtlas", "SetHighlightAtlas", "SetOwner",
  }) do
    value[name] = noop
  end
  function value:SetText(text) self.text = text end
  function value:SetTextColor(r, g, b) self.color = { r, g, b } end
  function value:SetScript(name, callback) self.scripts[name] = callback end
  function value:SetWidth(width) self.width = width end
  function value:GetWidth() return self.width or 0 end
  function value:SetHeight(height) self.height = height end
  function value:GetFont() return "TestFont", 12, "" end
  function value:GetStringWidth() return #(self.text or "") * 6 end
  function value:GetParent() return self.parent end
  function value:GetEffectiveScale() return 1 end
  function value:SetEnabled(enabled) self.enabled = enabled end
  function value:IsEnabled() return self.enabled ~= false end
  function value:SetChecked(checked) self.checked = checked end
  function value:SetTexture(texture) self.texture = texture end
  function value:SetHyperlink(ref) self.tooltipRef = ref end
  function value:CreateTexture() return widget(self) end
  function value:CreateFontString() return widget(self) end
  function value:RegisterEvent() end
  function value:Show() self.shown = true end
  function value:Hide() self.shown = false end
  function value:IsShown() return self.shown end
  return value
end

local function runtime()
  local ns = {}
  local frames = {}
  local env = setmetatable({
    SlashCmdList = {},
    CreateFrame = function(_, name, parent)
      local frame = widget(parent)
      if name then frames[name] = frame end
      return frame
    end,
    frames = frames,
    UIParent = widget(),
    GameTooltip = widget(),
    GetCursorPosition = function() return 100, 100 end,
    GameFontHighlight = { GetTextColor = function() return 1, 1, 1 end },
    ITEM_QUALITY_COLORS = {
      [3] = { r = 0, g = 0.44, b = 0.87 },
      [4] = { r = 0.64, g = 0.21, b = 0.93 },
    },
    C_Item = {},
  }, { __index = _G })
  env._G = env
  local function loadModule(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    return chunk("LootWishListTest", ns)
  end
  loadModule("Core/Shared/ItemResolver.lua")
  loadModule("Tracker/TrackerGroups.lua")
  loadModule("Tracker/TrackerRowStyle.lua")
  loadModule("Tracker/TrackerRenderData.lua")
  loadModule("Tracker/TrackerRows.lua")
  loadModule("Core/Bootstrap.lua")
  ns.TrackerHeaders = { GetHeaderTextInset = function() return 0 end }
  return ns, env, loadModule
end

local function setItemData(env, records)
  local calls = {}
  env.C_Item.GetItemInfo = function(ref)
    calls[#calls + 1] = ref
    local data = records[ref]
    if data then
      return data.name, data.link, data.quality
    end
  end
  return calls
end

local function trackedGroups(ns, item, mode)
  ns.WishlistStore = { getTrackedItems = function() return { item } end }
  ns.GetCurrentDb = function() return {} end
  ns.GetCharacterKey = function() return "Test-Realm" end
  ns.GetTrackerGroupingMode = function() return mode or "source" end
  ns.GetText = function(key) return key end
  ns.FormatWishlistTagList = function(tags) return table.concat(tags, ", ") end
  ns.GetOrderedAssignedTags = function() return {} end
  ns.TrackerFilterMenu = { GetSelectedTagLookup = function() return nil end }
  ns.RaidBossOrdering = { IsRaidInstance = function() return false end }
  return ns.TrackerRenderData.buildTrackedGroups(ns)
end

local function renderRow(ns, item, row)
  if not row then
    row = widget()
    row.text, row.tick, row.dash, row.collapseButton = widget(), widget(), widget(), widget()
  end
  ns.TrackerRows.RenderItemRow(ns, {}, row, item, {})
  return row
end

test("legacy item globals are absent", function()
  for _, name in ipairs({ "GetItemInfo", "GetItemInfoInstant", "GetItemIcon", "GetDetailedItemLevelInfo", "GetItemQualityColor" }) do
    equal(_G[name], nil, name)
  end
end)

test("namespaced name lookup", function()
  local ns, env = runtime()
  local calls = setItemData(env, { [100] = { name = "Localized Sword" } })
  equal(ns.GetItemInfoName(100), "Localized Sword")
  equal(calls[1], 100)
end)

test("name lookup tolerates unavailable API and empty data", function()
  local ns, env = runtime()
  equal(ns.GetItemInfoName(100), nil)
  env.C_Item = nil
  equal(ns.GetItemInfoName(100), nil)
  env.C_Item = {}
  setItemData(env, { [100] = { name = "" } })
  equal(ns.GetItemInfoName(100), nil)
  setItemData(env, { [100] = { name = false } })
  equal(ns.GetItemInfoName(100), nil)
end)

test("tracked groups prefer effective variant name", function()
  local ns, env = runtime()
  local variant = "item:100:0:0:0:0:0:0:0:80:0:0:16"
  local calls = setItemData(env, { [variant] = { name = "Variant Sword", quality = 4 } })
  local item = { itemID = 100, selectedVariantRef = variant, tags = { "Best in slot" } }
  local row = trackedGroups(ns, item)[1].items[1]
  equal(row.displayText, "Variant Sword")
  equal(row.tooltipRef, variant)
  equal(calls[1], variant)
  equal(#calls, 1)
  equal(item.selectedVariantRef, variant)
  equal(item.tags[1], "Best in slot")
end)

test("tracked groups fall back to base name without replacing tooltip variant", function()
  local ns, env = runtime()
  local variant = "item:100:0:0:0:0:0:0:0:80:0:0:16"
  local calls = setItemData(env, { [100] = { name = "Base Sword" } })
  local row = trackedGroups(ns, { itemID = 100, selectedVariantRef = variant })[1].items[1]
  equal(row.displayText, "Base Sword")
  equal(row.tooltipRef, variant)
  equal(calls[1], variant)
  equal(calls[2], 100)
end)

test("effective variant preserves owned then selected then base priority", function()
  local ns = runtime()
  local selected, owned = "item:100:0:0:0:0:0:0:0:80:0:0:1", "|Hitem:100:0:0:0:0:0:0:0:80:0:0:16|h[Owned Sword]|h"
  local item = { itemID = 100, selectedVariantRef = selected }
  equal(ns.TrackerRenderData.resolveEffectiveDisplayLink(ns, item, { ["item:100"] = owned }), owned)
  equal(ns.TrackerRenderData.resolveEffectiveDisplayLink(ns, item, {}), selected)
  equal(ns.TrackerRenderData.resolveEffectiveDisplayLink(ns, { itemID = 100 }, {}), "item:100")
end)

test("row uses effective variant quality and preserves tooltip and tick", function()
  local ns, env = runtime()
  local variant = "item:100:0:0:0:0:0:0:0:80:0:0:16"
  local calls = setItemData(env, { [variant] = { name = "Epic Sword", quality = 4 }, [100] = { quality = 3 } })
  local row = renderRow(ns, { itemID = 100, displayText = "Epic Sword", displayLink = variant, showTick = true })
  equal(row.text.text, "Epic Sword")
  equal(row.text.color[1], 0.64)
  equal(row.text.color[2], 0.21)
  equal(row.text.color[3], 0.93)
  equal(calls[1], variant)
  equal(row.tooltipRef, variant)
  equal(row.tick.shown, true)
  equal(row.dash.shown, false)
  equal(row.isPossessed, true)
end)

test("missing name and quality retain visible fallback row and tooltip", function()
  local ns, env = runtime()
  setItemData(env, {})
  ns.state.possessed["item:100"] = true
  local item = trackedGroups(ns, { itemID = 100 })[1].items[1]
  local row = renderRow(ns, item)
  equal(row.text.text, "Item 100")
  equal(row.text.color[1], 1)
  equal(row.text.color[2], 1)
  equal(row.text.color[3], 1)
  equal(row.tooltipRef, "item:100")
  equal(row.tick.shown, true)
  equal(row.shown, true)
end)

test("row resets stale rarity color when API or quality is unavailable", function()
  local ns, env = runtime()
  setItemData(env, { ["item:100"] = { quality = 4 } })
  local item = { itemID = 100, displayText = "Sword", displayLink = "item:100" }
  local row = renderRow(ns, item)
  equal(row.text.color[1], 0.64)
  for _, api in ipairs({ {}, { GetItemInfo = function() return "Sword", nil, 99 end } }) do
    env.C_Item = api
    renderRow(ns, item, row)
    equal(row.text.color[1], 1)
    equal(row.dash.shown, true)
    equal(row.tick.shown, false)
  end
  env.C_Item = nil
  equal(renderRow(ns, { displayText = "Sword", displayLink = "item:100" }).text.color[1], 1)
end)

test("source and slot groups retain resolved names and references", function()
  local ns, env = runtime()
  setItemData(env, { ["item:100"] = { name = "Sword" } })
  for _, mode in ipairs({ "source", "slot" }) do
    local row = trackedGroups(ns, { itemID = 100, inventoryType = "INVTYPE_WEAPON" }, mode)[1].items[1]
    equal(row.displayText, "Sword")
    equal(row.displayLink, "item:100")
  end
end)

local function presentationNamespace(ns)
  ns.GetText = function(key)
    if key == "PLAYER_LOOTED_WISHLIST_ITEM" then return "%s looted an item (%s)" end
    return key
  end
  ns.FormatWishlistTagList = function(tags) return table.concat(tags, ", ") end
  ns.GetOrderedAssignedTags = function() return { "BIS" } end
end

test("alert uses dropped link for icon quality and tooltip", function()
  local ns, env, loadModule = runtime()
  presentationNamespace(ns)
  loadModule("LootAwareness/Alerts/LootAlertDialog.lua")
  local dropped = "|Hitem:100:0:0:0:0:0:0:0:80:0:0:16|h[Dropped Sword]|h"
  local calls = setItemData(env, { [dropped] = { quality = 4 }, [100] = { quality = 3 } })
  env.C_Item.GetItemIconByID = function(ref) equal(ref, dropped); return 12345 end
  env.C_Item.GetItemQualityColor = function(quality) equal(quality, 4); return 0.64, 0.21, 0.93 end
  ns.LootAlertDialog.ShowFromRecord(ns, { itemID = 100, itemLink = dropped, playerName = "Other Player" })
  local frame = env.frames.LootWishListAlertFrame
  equal(frame.itemButton.name.text, "Dropped Sword")
  equal(frame.itemButton.icon.texture, 12345)
  equal(frame.itemButton.name.color[1], 0.64)
  equal(frame.itemButton.itemLink, dropped)
  equal(calls[1], dropped)
  frame.itemButton.scripts.OnEnter(frame.itemButton)
  equal(env.frames.LootWishListAlertTooltip.tooltipRef, dropped)
  frame.button1.scripts.OnClick()
  equal(frame.shown, false)
end)

test("alert resolves base link and retains unavailable-data fallbacks", function()
  local ns, env, loadModule = runtime()
  presentationNamespace(ns)
  loadModule("LootAwareness/Alerts/LootAlertDialog.lua")
  local base = "|Hitem:100|h[Base Sword]|h"
  setItemData(env, { [100] = { link = base } })
  ns.LootAlertDialog.ShowFromRecord(ns, { itemID = 100, playerName = "Other Player" })
  local frame = env.frames.LootWishListAlertFrame
  equal(frame.itemButton.name.text, "Base Sword")
  equal(frame.itemButton.itemLink, base)
  equal(frame.itemButton.icon.texture, 134400)
  equal(frame.itemButton.name.color[1], 1)
  env.C_Item = nil
  ns.LootAlertDialog.ShowFromRecord(ns, { itemID = 100, itemName = "Fallback Sword", playerName = "Other Player" })
  equal(frame.itemButton.name.text, "Fallback Sword")
  equal(frame.itemButton.icon.texture, 134400)
  equal(frame.itemButton.name.color[1], 1)
end)

local function showDeleteConfirmation(ns, env, loadModule, item)
  presentationNamespace(ns)
  ns.WishlistStore = { normalizeTagLabel = string.lower }
  ns.GetWishlistTags = function() return { "BIS", "Other" } end
  ns.PreviewDeleteWishlistTag = function() return "BIS", { item } end
  loadModule("AdventureGuide/WishlistTagPopover.lua")
  local owner = widget()
  owner:Show()
  ns.WishlistTagPopover.Toggle(ns, owner, item)
  local button = env.frames.LootWishListTagPopover.rows[1].deleteButton
  button.scripts.OnClick(button)
  return env.frames.LootWishListTagDeleteDialog
end

test("tag delete confirmation preserves selected variant icon color and tooltip", function()
  local ns, env, loadModule = runtime()
  local selected = "item:100:0:0:0:0:0:0:0:80:0:0:1"
  setItemData(env, { [100] = { name = "Selected Sword" }, [selected] = { quality = 3 } })
  env.C_Item.GetItemIconByID = function(ref) equal(ref, selected); return 54321 end
  env.C_Item.GetItemQualityColor = function(quality) equal(quality, 3); return 0, 0.44, 0.87 end
  local dialog = showDeleteConfirmation(ns, env, loadModule, { itemID = 100, selectedVariantRef = selected })
  local row = dialog.itemRows[1]
  equal(row.name.text, "Selected Sword")
  equal(row.icon.texture, 54321)
  equal(row.name.color[2], 0.44)
  equal(row.tooltipRef, selected)
  row.scripts.OnEnter(row)
  equal(env.GameTooltip.tooltipRef, selected)
  dialog.cancelButton.scripts.OnClick()
  equal(dialog.shown, false)
end)

test("tag delete confirmation retains missing-data icon and color fallbacks", function()
  local ns, env, loadModule = runtime()
  env.C_Item = nil
  local dialog = showDeleteConfirmation(ns, env, loadModule, { itemID = 100 })
  local row = dialog.itemRows[1]
  equal(row.name.text, "Item 100")
  equal(row.icon.texture, 134400)
  equal(row.name.color[1], 1)
  equal(row.tooltipRef, "item:100")
end)

test("item resolver obtains inventory type through namespaced instant lookup", function()
  local ns, env = runtime()
  local count = 0
  env.C_Item.GetItemInfoInstant = function(id)
    equal(id, 100)
    count = count + 1
    return id, "Weapon", "Sword", "INVTYPE_WEAPON"
  end
  local item = ns.ItemResolver.normalizeItemData({ itemID = 100 })
  equal(item.inventoryType, "INVTYPE_WEAPON")
  equal(item.wishlistKey, "item:100")
  equal(count, 1)
  equal(ns.ItemResolver.normalizeItemData({ itemID = 100, inventoryType = "INVTYPE_2HWEAPON" }).inventoryType, "INVTYPE_2HWEAPON")
  equal(count, 1)
  env.C_Item = nil
  equal(ns.ItemResolver.normalizeItemData({ itemID = 100 }).inventoryType, nil)
end)

test("wishlist metadata repair resolves slot without changing schema or identity", function()
  local ns, env, loadModule = runtime()
  ns.GetText = function() return "Best in slot" end
  loadModule("DataStore/WishlistMigration.lua")
  loadModule("DataStore/WishlistStore.lua")
  env.C_Item.GetItemInfoInstant = function(id)
    equal(id, 100)
    return id, "Weapon", "Sword", "INVTYPE_WEAPON"
  end
  local selected = "item:100:0:0:0:0:0:0:0:80:0:0:1"
  local db = { version = 5, characters = { ["Test-Realm"] = {
    tags = { "BIS" }, items = { ["100"] = { tags = { "BIS" }, selectedVariantRef = selected, instanceID = 10, encounterID = 20 } },
  } } }
  equal(ns.WishlistMigration.repairTrackedMetadata(db, "Test-Realm", ns), true)
  local item = db.characters["Test-Realm"].items["100"]
  equal(item.inventoryType, "INVTYPE_WEAPON")
  equal(item.selectedVariantRef, selected)
  equal(item.tags[1], "BIS")
  equal(item.instanceID, 10)
  equal(item.encounterID, 20)
  equal(item.itemName, nil)
  equal(db.version, 5)
  env.C_Item = nil
  equal(ns.WishlistMigration.resolveInventoryType(100), nil)
  env.C_Item = {}
  equal(ns.WishlistMigration.resolveInventoryType(100), nil)
  env.C_Item.GetItemInfoInstant = function() return 100, nil, nil, "" end
  equal(ns.WishlistMigration.resolveInventoryType(100), nil)
end)

local function scanOwned(ns, env, loadModule)
  loadModule("Tracker/PossessionScanner.lua")
  env.INVSLOT_FIRST_EQUIPPED, env.INVSLOT_LAST_EQUIPPED, env.NUM_BAG_SLOTS = 1, 2, 0
  local low, high, bag = "|Hitem:100:low|h[Sword]|h", "|Hitem:100:high|h[Sword]|h", "|Hitem:100:bag|h[Sword]|h"
  env.GetInventoryItemLink = function(_, slot) return slot == 1 and low or high end
  env.C_Container = {
    GetContainerNumSlots = function() return 1 end,
    GetContainerItemLink = function() return bag end,
  }
  ns.WishlistStore = { getTrackedItems = function() return {} end }
  ns.GetCurrentDb = function() return {} end
  ns.GetCharacterKey = function() return "Test-Realm" end
  return low, high, bag
end

test("possession scanner ranks owned links by namespaced actual item level", function()
  local ns, env, loadModule = runtime()
  local low, high, bag = scanOwned(ns, env, loadModule)
  local levels = { [low] = 200, [high] = 250, [bag] = 220 }
  local count = 0
  env.C_Item.GetDetailedItemLevelInfo = function(ref)
    count = count + 1
    return levels[ref], false, 100
  end
  ns.PossessionScanner.Refresh(ns)
  equal(count, 3)
  equal(ns.state.possessed["item:100"], true)
  equal(ns.state.bestOwnedLinks["item:100"], high)
end)

test("possession survives unavailable item-level data", function()
  local ns, env, loadModule = runtime()
  local low = scanOwned(ns, env, loadModule)
  for _, api in ipairs({ {}, { GetDetailedItemLevelInfo = function() return nil end } }) do
    env.C_Item = api
    ns.PossessionScanner.Refresh(ns)
    equal(ns.state.possessed["item:100"], true)
    equal(ns.state.bestOwnedLinks["item:100"], low)
  end
  env.C_Item = nil
  ns.PossessionScanner.Refresh(ns)
  equal(ns.state.possessed["item:100"], true)
end)

local failed, total = 0, 0
for _, entry in ipairs(tests) do
  if not arg[1] or entry.name:find(arg[1], 1, true) then
    total = total + 1
    local ok, err = pcall(entry.callback)
    if ok then
      print("PASS " .. entry.name)
    else
      failed = failed + 1
      print("FAIL " .. entry.name .. ": " .. tostring(err))
    end
  end
end
print(string.format("%d/%d tests passed", total - failed, total))
if failed > 0 or total == 0 then os.exit(1) end
