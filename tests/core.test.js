const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const { LuaFactory } = require('wasmoon')

async function loadLuaModule(relativePath) {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const modulePath = path.join(process.cwd(), relativePath)
  const source = fs.readFileSync(modulePath, 'utf8')
  const module = await lua.doString(source)

  return {
    module,
    lua,
    close() {
      lua.global.close()
    },
  }
}

test('wishlist store persists normalized tracked items without best looted item levels per character', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'WishlistStore.lua'), 'utf8').replace(/return WishlistStore\s*$/, '')

  try {
    const result = await lua.doString(`${source}
      local db = {}
      WishlistStore.setTracked(db, 'Player-Realm', 19019, true)
      WishlistStore.setItemMetadata(db, 'Player-Realm', 19019, {
        encounterID = 11502,
        instanceID = 469,
        inventoryType = 'INVTYPE_WEAPON',
        selectedVariantRef = 'item:19019::::::::70::5:1:3524::::::'
      })
      local items = WishlistStore.getTrackedItems(db, 'Player-Realm')
      local entry = WishlistStore.getExistingItemEntry(db, 'Player-Realm', 19019)
      return {
        tracked = WishlistStore.isTracked(db, 'Player-Realm', 19019),
        count = #items,
        encounterID = items[1].encounterID,
        instanceID = items[1].instanceID,
        inventoryType = items[1].inventoryType,
        selectedVariantRef = items[1].selectedVariantRef,
        itemBestLootedItemLevel = items[1].bestLootedItemLevel,
        savedBestLootedItemLevel = entry.bestLootedItemLevel,
        savedItemName = entry.itemName,
        savedItemLink = entry.itemLink,
        savedSourceLabel = entry.sourceLabel,
      }
    `)

    assert.equal(result.tracked, true)
    assert.equal(result.count, 1)
    assert.equal(result.encounterID, 11502)
    assert.equal(result.instanceID, 469)
    assert.equal(result.inventoryType, 'INVTYPE_WEAPON')
    assert.equal(result.selectedVariantRef, 'item:19019::::::::70::5:1:3524::::::')
    assert.equal(result.itemBestLootedItemLevel, undefined)
    assert.equal(result.savedBestLootedItemLevel, undefined)
    assert.equal(result.savedItemName, undefined)
    assert.equal(result.savedItemLink, undefined)
    assert.equal(result.savedSourceLabel, undefined)
  } finally {
    lua.global.close()
  }
})

test('wishlist store removes untracked items instead of persisting tombstones', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'WishlistStore.lua'), 'utf8').replace(/return WishlistStore\s*$/, '')

  try {
    const result = await lua.doString(`${source}
      local db = {}
      WishlistStore.setTracked(db, 'Player-Realm', 19019, true)
      WishlistStore.removeItem(db, 'Player-Realm', 19019)
      return {
        tracked = WishlistStore.isTracked(db, 'Player-Realm', 19019),
        entry = WishlistStore.getExistingItemEntry(db, 'Player-Realm', 19019),
        count = #WishlistStore.getTrackedItems(db, 'Player-Realm'),
      }
    `)

    assert.equal(result.tracked, false)
    assert.equal(result.entry, undefined)
    assert.equal(result.count, 0)
  } finally {
    lua.global.close()
  }
})

test('wishlist store persists grouping mode and collapse state separately per mode', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'WishlistStore.lua'), 'utf8').replace(/return WishlistStore\s*$/, '')

  try {
    const result = await lua.doString(`${source}
      local db = {}
      local before = WishlistStore.getGroupingMode(db, 'Player-Realm')
      WishlistStore.setGroupingMode(db, 'Player-Realm', 'slot')
      WishlistStore.setGroupCollapsed(db, 'Player-Realm', 'source', 'source:instance:469', true)
      WishlistStore.setGroupCollapsed(db, 'Player-Realm', 'slot', 'slot:INVTYPE_HEAD', true)
      return {
        before = before,
        after = WishlistStore.getGroupingMode(db, 'Player-Realm'),
        sourceCollapsed = WishlistStore.isGroupCollapsed(db, 'Player-Realm', 'source', 'source:instance:469'),
        slotCollapsed = WishlistStore.isGroupCollapsed(db, 'Player-Realm', 'slot', 'slot:INVTYPE_HEAD'),
        sourceHiddenInSlot = WishlistStore.isGroupCollapsed(db, 'Player-Realm', 'slot', 'source:instance:469'),
      }
    `)

    assert.equal(result.before, 'source')
    assert.equal(result.after, 'slot')
    assert.equal(result.sourceCollapsed, true)
    assert.equal(result.slotCollapsed, true)
    assert.equal(result.sourceHiddenInSlot, false)
  } finally {
    lua.global.close()
  }
})

test('wishlist store repairs missing inventory types and strips legacy localized fields without changing version', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'WishlistStore.lua'), 'utf8').replace(/return WishlistStore\s*$/, '')

  try {
    const result = await lua.doString(`
      function GetItemInfoInstant(itemId)
        return itemId, 'Armor', 'Plate', 'INVTYPE_HEAD'
      end

      ${source}

      local db = {
        version = 4,
        characters = {
          ['Player-Realm'] = {
            items = {
              ['19019'] = {
                tracked = true,
                instanceID = 42,
                bestLootedItemLevel = 278,
                itemName = 'Legacy Name',
                sourceLabel = 'Legacy Source'
              }
            }
          }
        }
      }

      local changed = WishlistStore.repairTrackedMetadata(db, 'Player-Realm', {
        IsRaidInstance = function(instanceID)
          return false
        end,
      })

      local entry = WishlistStore.getTrackedItems(db, 'Player-Realm')[1]
      return {
        version = db.version,
        changed = changed,
        inventoryType = entry.inventoryType,
        selectedVariantRef = entry.selectedVariantRef,
        rawBestLootedItemLevel = db.characters['Player-Realm'].items['19019'].bestLootedItemLevel,
        rawItemName = db.characters['Player-Realm'].items['19019'].itemName,
        rawSourceLabel = db.characters['Player-Realm'].items['19019'].sourceLabel,
      }
    `)

    assert.equal(result.version, 4)
    assert.equal(result.changed, true)
    assert.equal(result.inventoryType, 'INVTYPE_HEAD')
    assert.equal(result.selectedVariantRef, undefined)
    assert.equal(result.rawBestLootedItemLevel, undefined)
    assert.equal(result.rawItemName, undefined)
    assert.equal(result.rawSourceLabel, undefined)
  } finally {
    lua.global.close()
  }
})

test('wishlist store migrates legacy entries to normalized storage idempotently', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'WishlistStore.lua'), 'utf8').replace(/return WishlistStore\s*$/, '')

  try {
    const result = await lua.doString(`
      ${source}

      local db = {
        version = 3,
        characters = {
          ['Player-Realm'] = {
            items = {
              ['19019'] = {
                tracked = true,
                itemName = 'Thunderfury',
                itemLink = '|cffa335ee|Hitem:19019::::::::70::5:1:3524::::::|h[Thunderfury]|h|r',
                sourceLabel = 'Blackwing Lair',
                bossName = 'Nefarian',
                bestLootedItemLevel = 278,
                instanceID = 469,
                encounterID = 11583,
                inventoryType = 'INVTYPE_WEAPON',
              },
              ['17182'] = {
                tracked = false,
                itemLink = '|Hitem:17182::::::::70:::::|h[Sulfuras]|h',
              },
            },
          },
        },
      }

      local namespace = {
        ItemResolver = {
          getVariantRef = function(itemRef)
            return itemRef:match('|H([^|]+)|h') or itemRef
          end,
        },
      }

      WishlistStore.runMigration(db, namespace)
      WishlistStore.runMigration(db, namespace)

      local entry = WishlistStore.getExistingItemEntry(db, 'Player-Realm', 19019)
      return {
        version = db.version,
        trackedCount = #WishlistStore.getTrackedItems(db, 'Player-Realm'),
        hasTrackedEntry = entry ~= nil,
        selectedVariantRef = entry and entry.selectedVariantRef or nil,
        bestLootedItemLevel = entry and entry.bestLootedItemLevel or nil,
        itemName = entry and entry.itemName or nil,
        sourceLabel = entry and entry.sourceLabel or nil,
        removedTombstone = WishlistStore.getExistingItemEntry(db, 'Player-Realm', 17182),
      }
    `)

    assert.equal(result.version, 4)
    assert.equal(result.trackedCount, 1)
    assert.equal(result.hasTrackedEntry, true)
    assert.equal(result.selectedVariantRef, 'item:19019::::::::70::5:1:3524::::::')
    assert.equal(result.bestLootedItemLevel, undefined)
    assert.equal(result.itemName, undefined)
    assert.equal(result.sourceLabel, undefined)
    assert.equal(result.removedTombstone, undefined)
  } finally {
    lua.global.close()
  }
})

test('item resolver collapses higher item level variants to the same wishlist key', async () => {
  const { module: resolver, close } = await loadLuaModule('ItemResolver.lua')

  try {
    assert.equal(resolver.getWishlistKey({ itemID: 19019, itemLink: '|Hitem:19019::::::::70:::::|h[Thunderfury]|h' }), 'item:19019')
    assert.equal(resolver.getWishlistKey({ itemID: 19019, itemLink: '|Hitem:19019::::::::70:66::5:5:7982:10355:6652:1507:8767:1:28:1279:::::|h[Thunderfury]|h' }), 'item:19019')
    
    const normalized = resolver.normalizeItemData({ itemID: 19019, encounterID: 11502, instanceID: 469, inventoryType: 'INVTYPE_WEAPON' })
    assert.equal(normalized.encounterID, 11502)
    assert.equal(normalized.instanceID, 469)
    assert.equal(normalized.inventoryType, 'INVTYPE_WEAPON')
    assert.equal(
      resolver.getVariantRef('|cffa335ee|Hitem:19019::::::::70::5:1:3524::::::|h[Thunderfury]|h|r'),
      'item:19019::::::::70::5:1:3524::::::'
    )
  } finally {
    close()
  }
})

test('item resolver falls back to GetItemInfoInstant equip location when metadata lacks inventory type', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'ItemResolver.lua'), 'utf8').replace(/return ItemResolver\s*$/, '')

  try {
    const result = await lua.doString(`
      function GetItemInfoInstant(itemId)
        return itemId, 'Armor', 'Plate', 'INVTYPE_HEAD'
      end
      ${source}
      local normalized = ItemResolver.normalizeItemData({ itemID = 19019 })
      return normalized.inventoryType
    `)

    assert.equal(result, 'INVTYPE_HEAD')
  } finally {
    lua.global.close()
  }
})

test('source resolver groups items by source and falls back to Other', async () => {
  const { module: sourceResolver, close } = await loadLuaModule('SourceResolver.lua')

  try {
    assert.equal(sourceResolver.getGroupLabel({ itemID: 19019, instanceName: 'Blackwing Lair' }), 'Blackwing Lair')
    assert.equal(sourceResolver.getGroupLabel({ itemID: 19019 }), 'Other')

    const sourceGroup = sourceResolver.resolveGroup('source', { instanceID: 469, instanceName: 'Blackwing Lair' }, 'Other')
    assert.equal(sourceGroup.key, 'source:instance:469')
    assert.equal(sourceGroup.label, 'Blackwing Lair')

    const slotGroup = sourceResolver.resolveGroup('slot', { inventoryType: 'INVTYPE_HEAD', slotLabel: 'Head' }, 'Other')
    assert.equal(slotGroup.key, 'slot:head')
    assert.equal(slotGroup.label, 'Head')
  } finally {
    close()
  }
})

test('source resolver sends unsupported or non-equippable inventory types to Other in slot mode', async () => {
  const { module: sourceResolver, close } = await loadLuaModule('SourceResolver.lua')

  try {
    const nonEquip = sourceResolver.resolveGroup('slot', { inventoryType: 'INVTYPE_NON_EQUIP_IGNORE', slotLabel: 'Ignored' }, 'Other')
    const unsupported = sourceResolver.resolveGroup('slot', { inventoryType: 'INVTYPE_BAG', slotLabel: 'Bag' }, 'Other')

    assert.equal(nonEquip.key, 'slot:other')
    assert.equal(nonEquip.label, 'Other')
    assert.equal(unsupported.key, 'slot:other')
    assert.equal(unsupported.label, 'Other')
  } finally {
    close()
  }
})

test('source resolver prefers the current journal instance name before falling back to Other', async () => {
  const { module: sourceResolver, close } = await loadLuaModule('SourceResolver.lua')

  try {
    assert.equal(sourceResolver.getGroupLabel({ currentInstanceName: 'Den of Nalorakk' }), 'Den of Nalorakk')
    assert.equal(sourceResolver.getGroupLabel({ currentInstanceName: '' }), 'Other')
  } finally {
    close()
  }
})

test('tracker model groups rows by source and shows only item identity plus possession state', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { itemID: 1, itemName: 'Stormlash Dagger', groupKey: 'source:instance:1', groupLabel: 'Operation: Floodgate', isPossessed: false, bestLootedItemLevel: 262, itemTrack: 'Champion' },
      { itemID: 2, itemName: 'Circuit Breaker', groupKey: 'source:instance:1', groupLabel: 'Operation: Floodgate', isPossessed: true },
      { itemID: 3, itemName: 'Unknown Relic', groupKey: 'source:other', groupLabel: 'Other', isPossessed: false },
    ], { groupBy: 'source', otherLabel: 'Other' })

    assert.equal(grouped.length, 2)
    assert.equal(grouped[0].key, 'source:instance:1')
    assert.equal(grouped[0].mode, 'source')
    assert.equal(grouped[0].label, 'Operation: Floodgate')
    assert.equal(grouped[0].items[0].displayText, 'Stormlash Dagger')
    assert.equal(grouped[0].items[0].showTick, false)
    assert.equal(grouped[0].items[1].displayText, 'Circuit Breaker')
    assert.equal(grouped[0].items[1].showTick, true)
    assert.equal(grouped[1].items[0].displayText, 'Unknown Relic')
    assert.equal(grouped[1].label, 'Other')
  } finally {
    close()
  }
})

test('tracker model groups raid items by boss and sorts bosses by bossRank', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { 
        itemID: 2, 
        itemName: 'Circuit Breaker', 
        groupKey: 'source:instance:1',
        groupLabel: 'Operation: Floodgate', 
        isPossessed: true,
        isRaidSource: true,
        bossName: 'The Mainframe',
        bossRank: 2 // Second boss
      },
      { 
        itemID: 1, 
        itemName: 'Stormlash Dagger', 
        groupKey: 'source:instance:1',
        groupLabel: 'Operation: Floodgate', 
        isPossessed: false, 
        isRaidSource: true,
        bestLootedItemLevel: 262,
        bossName: 'Enforcer Sunder',
        bossRank: 1 // First boss
      },
    ], { groupBy: 'source', otherLabel: 'Other' })

    // Group 1: Operation: Floodgate (Raid)
    assert.equal(grouped[0].label, 'Operation: Floodgate')
    
    // Row 1: Boss Header for rank 1 (Enforcer Sunder)
    assert.equal(grouped[0].items[0].displayText, 'Enforcer Sunder')
    assert.equal(grouped[0].items[0].itemID, 'header:Enforcer Sunder')
    
    // Row 2: Item 1 (under Sunder)
    assert.equal(grouped[0].items[1].itemID, 1)

    // Row 3: Boss Header for rank 2 (The Mainframe)
    assert.equal(grouped[0].items[2].displayText, 'The Mainframe')
    assert.equal(grouped[0].items[2].itemID, 'header:The Mainframe')

    // Row 4: Item 2 (under Mainframe)
    assert.equal(grouped[0].items[3].itemID, 2)
  } finally {
    close()
  }
})

test('tracker model keeps dungeon items in a flat list without boss headers', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { 
        itemID: 3, 
        itemName: 'Dungeon Blade', 
        groupKey: 'source:instance:2',
        groupLabel: 'The Deadmines', 
        isPossessed: false,
        isRaidSource: false,
        bossName: 'Edwin VanCleef'
      },
    ], { groupBy: 'source', otherLabel: 'Other' })

    assert.equal(grouped[0].label, 'The Deadmines')
    assert.equal(grouped[0].items[0].displayText, 'Dungeon Blade')
    assert.equal(grouped[0].items[0].isBossHeader, undefined)
  } finally {
    close()
  }
})

test('tracker model keeps the localized fallback group at the end', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { itemID: 1, itemName: 'Unknown Relic', groupKey: 'source:other', groupLabel: 'Autre', isPossessed: false },
      { itemID: 2, itemName: 'Stormlash Dagger', groupKey: 'source:instance:77', groupLabel: "Zul'Gurub", isPossessed: false },
    ], { groupBy: 'source', otherLabel: 'Autre' })

    assert.equal(grouped[0].label, "Zul'Gurub")
    assert.equal(grouped[1].label, 'Autre')
  } finally {
    close()
  }
})

test('tracker model keeps slot mode flat even when boss names are present', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      {
        itemID: 1,
        itemName: 'Crown of Storms',
        groupKey: 'slot:INVTYPE_HEAD',
        groupLabel: 'Head',
        isPossessed: false,
        isRaidSource: true,
        bossName: 'Queen Ansurek',
      },
    ], { groupBy: 'slot', otherLabel: 'Other' })

    assert.equal(grouped[0].mode, 'slot')
    assert.equal(grouped[0].items.length, 1)
    assert.equal(grouped[0].items[0].itemID, 1)
    assert.equal(grouped[0].items[0].isBossHeader, undefined)
  } finally {
    close()
  }
})

test('tracker model sorts slot groups in fixed paper-doll order with Other last', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { itemID: 1, itemName: 'Ring', groupKey: 'slot:rings', groupLabel: 'Rings', groupSortIndex: 11, isPossessed: false },
      { itemID: 2, itemName: 'Helmet', groupKey: 'slot:head', groupLabel: 'Head', groupSortIndex: 1, isPossessed: false },
      { itemID: 3, itemName: 'Offhand', groupKey: 'slot:off_hand', groupLabel: 'Off Hand', groupSortIndex: 15, isPossessed: false },
      { itemID: 4, itemName: 'Other Item', groupKey: 'slot:other', groupLabel: 'Other', groupSortIndex: 999, isPossessed: false },
    ], { groupBy: 'slot', otherLabel: 'Other' })

    assert.equal(grouped[0].label, 'Head')
    assert.equal(grouped[1].label, 'Rings')
    assert.equal(grouped[2].label, 'Off Hand')
    assert.equal(grouped[3].label, 'Other')
  } finally {
    close()
  }
})

test('set tracked from item data works before raid helpers are defined later in file', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')

  try {
    await lua.global.set('sourceText', source)
    const result = await lua.doString(`
      local refreshed = 0
      local trackedItemId = nil
      local trackedMetadata = nil
      local primedInstanceId = nil
      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
        },
        ItemResolver = {
          normalizeItemData = function(itemData)
            return itemData
          end,
          getItemIdFromLink = function() return nil end,
          getWishlistKey = function(item) return 'item:' .. tostring(item.itemID) end,
          getVariantRef = function(itemRef) return itemRef end,
          getTooltipRef = function(item) return item.selectedVariantRef or ('item:' .. tostring(item.itemID)) end,
        },
        WishlistStore = {
          isTracked = function() return false end,
          getGroupingMode = function() return 'source' end,
          getTrackedItems = function() return {} end,
          getExistingItemEntry = function() return nil end,
          setTracked = function(_, _, itemID) trackedItemId = itemID end,
          setItemMetadata = function(_, _, _, metadata) trackedMetadata = metadata end,
          removeItem = function() end,
          runMigration = function() end,
          repairTrackedMetadata = function() end,
        },
        AdventureGuideUI = { Refresh = function() end, Initialize = function() end },
        TrackerUI = { Refresh = function() end, Initialize = function() end },
        LootEvents = { HandleChatLoot = function() end, HandleStartLootRoll = function() end },
        Locales = { getString = function(_, _, key) return key end },
      }

      function CreateFrame()
        return {
          RegisterEvent = function() end,
          SetScript = function() end,
          UnregisterAllEvents = function() end,
        }
      end
      StaticPopupDialogs = {}
      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function InCombatLockdown() return false end
      C_Timer = { After = function(_, callback) if callback then callback() end end }
      function GetLocale() return 'enUS' end
      function EJ_GetEncounterInfo() return 'Raid Boss' end
      function GetItemInfo() return nil end
      function hooksecurefunc() end
      SlashCmdList = {}
      NUM_GROUP_LOOT_FRAMES = 4
      UIParent = {}
      function StaticPopup_Show() end
      function GetDetailedItemLevelInfo() return nil end
      function GetInventoryItemLink() return nil end

      local addonName = 'LootWishList'
      local env = setmetatable({ [1] = addonName, [2] = namespace }, { __index = _G })
      local chunk = assert(load(sourceText, nil, 't', env))
      chunk(addonName, namespace)

      namespace.PrimeEncounterDataForInstance = function(instanceID)
        primedInstanceId = instanceID
      end
      namespace.RefreshAllImmediate = function()
        refreshed = refreshed + 1
      end
      namespace.GetCurrentSourceLabel = function() return 'Blackwing Lair' end

      namespace.SetTrackedFromItemData({
        itemID = 19019,
        itemName = 'Thunderfury',
        selectedVariantRef = 'item:19019::::::::70::5:1:3524::::::',
        instanceID = 469,
        encounterID = 11583,
        inventoryType = 'INVTYPE_WEAPON',
        instanceName = 'Blackwing Lair',
      }, true)

      return {
        trackedItemId = trackedItemId,
        inventoryType = trackedMetadata and trackedMetadata.inventoryType or nil,
        selectedVariantRef = trackedMetadata and trackedMetadata.selectedVariantRef or nil,
        itemName = trackedMetadata and trackedMetadata.itemName or nil,
        primedInstanceId = primedInstanceId,
        refreshed = refreshed,
      }
    `)

    assert.equal(result.trackedItemId, 19019)
    assert.equal(result.inventoryType, 'INVTYPE_WEAPON')
    assert.equal(result.selectedVariantRef, 'item:19019::::::::70::5:1:3524::::::')
    assert.equal(result.itemName, undefined)
    assert.equal(result.primedInstanceId, 469)
    assert.equal(result.refreshed, 1)
  } finally {
    lua.global.close()
  }
})

test('localization contains required wishlist keys for all supported locales', async () => {
  const { module: locales, close } = await loadLuaModule('Locales.lua')

  try {
    const requiredKeys = ['LOOT_WISHLIST', 'WISHLIST', 'REMOVE', 'OTHER', 'LOOT_SOURCE', 'EQUIPMENT_SLOT', 'PLAYER_LOOTED_WISHLIST_ITEM']
    const localeIds = locales.getSupportedLocales()

    assert.ok(Array.isArray(localeIds))
    assert.ok(localeIds.length > 0)

    for (const localeId of localeIds) {
      const translations = locales.getLocale(localeId)

      for (const key of requiredKeys) {
        assert.equal(typeof translations[key], 'string', `${localeId} is missing ${key}`)
        assert.ok(translations[key].length > 0, `${localeId} has an empty ${key}`)
      }
    }
  } finally {
    close()
  }
})

test('slot mode tooltip footer uses a dungeon atlas without localized drops text', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetItemInfo(itemRefOrItemID)
        if itemRefOrItemID == 19019 then
          return 'Dungeon Blade'
        end
        return nil
      end
      function EJ_GetInstanceInfo(instanceID)
        if instanceID == 1 then
          return 'The Deadmines'
        end
        return nil
      end
      function EJ_GetInstanceByIndex() return nil end

      local capturedItems = nil
      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getVariantRef = function(itemRef)
            return itemRef
          end,
          getTooltipRef = function(item)
            return item.selectedVariantRef or ('item:' .. tostring(item.itemID))
          end,
        },
        WishlistStore = {
          getTrackedItems = function()
            return {
              {
                itemID = 19019,
                instanceID = 1,
                inventoryType = 'INVTYPE_HEAD',
              },
            }
          end,
          getGroupingMode = function() return 'slot' end,
        },
        SourceResolver = {
          resolveGroup = function(_, item)
            return { key = 'slot:head', label = item.slotLabel, sortIndex = 1 }
          end,
        },
        TrackerModel = {
          buildGroups = function(items)
            capturedItems = items
            return items
          end,
        },
        Locales = {
          getString = function(_, _, key)
            return key
          end,
        },
      }

      INVTYPE_HEAD = 'Head'

      (function(...)
        ${source}
      end)('Addon', namespace)

      namespace.BuildTrackerGroups()
      return capturedItems[1].tooltipFooter
    `)

    assert.equal(result, '|A:Dungeon:24:24|aThe Deadmines')
    assert.equal(result.includes('DROPS_FROM'), false)
    assert.equal(result.includes('Drops from:'), false)
  } finally {
    lua.global.close()
  }
})

test('slot mode tooltip footer uses a raid atlas and boss name without localized drops text', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetItemInfo(itemRefOrItemID)
        if itemRefOrItemID == 19020 then
          return 'Crown of Storms'
        end
        return nil
      end
      function EJ_GetInstanceInfo(instanceID)
        if instanceID == 2 then
          return 'Blackwing Lair'
        end
        return nil
      end
      function EJ_GetEncounterInfo(encounterID)
        if encounterID == 99 then
          return 'Nefarian'
        end
        return nil
      end
      function EJ_GetInstanceByIndex(index, isRaid)
        if isRaid and index == 1 then
          return 2
        end
        return nil
      end

      local capturedItems = nil
      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getVariantRef = function(itemRef)
            return itemRef
          end,
          getTooltipRef = function(item)
            return item.selectedVariantRef or ('item:' .. tostring(item.itemID))
          end,
        },
        WishlistStore = {
          getTrackedItems = function()
            return {
              {
                itemID = 19020,
                instanceID = 2,
                encounterID = 99,
                inventoryType = 'INVTYPE_HEAD',
              },
            }
          end,
          getGroupingMode = function() return 'slot' end,
        },
        SourceResolver = {
          resolveGroup = function(_, item)
            return { key = 'slot:head', label = item.slotLabel, sortIndex = 1 }
          end,
        },
        TrackerModel = {
          buildGroups = function(items)
            capturedItems = items
            return items
          end,
        },
        Locales = {
          getString = function(_, _, key)
            return key
          end,
        },
      }

      INVTYPE_HEAD = 'Head'

      (function(...)
        ${source}
      end)('Addon', namespace)

      namespace.BuildTrackerGroups()
      return capturedItems[1].tooltipFooter
    `)

    assert.equal(result, '|A:Raid:24:24|aBlackwing Lair - Nefarian')
    assert.equal(result.includes('DROPS_FROM'), false)
    assert.equal(result.includes('Drops from:'), false)
  } finally {
    lua.global.close()
  }
})

test('source mode tracker rows do not build a wishlist tooltip footer', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetItemInfo(itemRefOrItemID)
        if itemRefOrItemID == 19020 then
          return 'Crown of Storms'
        end
        return nil
      end
      function EJ_GetInstanceInfo(instanceID)
        if instanceID == 2 then
          return 'Blackwing Lair'
        end
        return nil
      end
      function EJ_GetEncounterInfo(encounterID)
        if encounterID == 99 then
          return 'Nefarian'
        end
        return nil
      end
      function EJ_GetInstanceByIndex(index, isRaid)
        if isRaid and index == 1 then
          return 2
        end
        return nil
      end

      local capturedItems = nil
      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getVariantRef = function(itemRef)
            return itemRef
          end,
          getTooltipRef = function(item)
            return item.selectedVariantRef or ('item:' .. tostring(item.itemID))
          end,
        },
        WishlistStore = {
          getTrackedItems = function()
            return {
              {
                itemID = 19020,
                instanceID = 2,
                encounterID = 99,
                inventoryType = 'INVTYPE_HEAD',
              },
            }
          end,
          getGroupingMode = function() return 'source' end,
        },
        SourceResolver = {
          resolveGroup = function(_, item)
            return { key = 'source:instance:2', label = item.instanceName, sortIndex = 1 }
          end,
        },
        TrackerModel = {
          buildGroups = function(items)
            capturedItems = items
            return items
          end,
        },
        Locales = {
          getString = function(_, _, key)
            return key
          end,
        },
      }

      INVTYPE_HEAD = 'Head'

      (function(...)
        ${source}
      end)('Addon', namespace)

      namespace.BuildTrackerGroups()
      return capturedItems[1].tooltipFooter
    `)

    assert.equal(result, null)
  } finally {
    lua.global.close()
  }
})

test('tracker row style uses quest-style check atlas and row padding', async () => {
  const { module: trackerRowStyle, close } = await loadLuaModule('TrackerRowStyle.lua')

  try {
    const incomplete = trackerRowStyle.getRowLayout(false)
    const complete = trackerRowStyle.getRowLayout(true)

    assert.equal(trackerRowStyle.CHECK_ATLAS, 'ui-questtracker-tracker-check')
    assert.equal(trackerRowStyle.CHECK_SIZE, 16)
    assert.equal(incomplete.textLeftOffset, 20)
    assert.equal(complete.textLeftOffset, 28)
    assert.equal(complete.checkLeftOffset, 12)
  } finally {
    close()
  }
})

test('item resolver getTooltipRef prefers selected variant ref over stable identity fallback', async () => {
  const { module: resolver, close } = await loadLuaModule('ItemResolver.lua')

  try {
    assert.equal(
      resolver.getTooltipRef({ itemID: 19019, selectedVariantRef: 'item:19019::::::::70::5:1:3524::::::' }),
      'item:19019::::::::70::5:1:3524::::::',
      'should return the normalized selected variant when present'
    )
  } finally {
    close()
  }
})

test('item resolver getTooltipRef falls back to stable item identity when no link is saved', async () => {
  const { module: resolver, close } = await loadLuaModule('ItemResolver.lua')

  try {
    assert.equal(
      resolver.getTooltipRef({ itemID: 19019 }),
      'item:19019',
      'should return item:N identity string when no itemLink is stored'
    )
    assert.equal(
      resolver.getTooltipRef({}),
      null,
      'should return nil when neither itemLink nor itemID is available'
    )
  } finally {
    close()
  }
})

test('loot wishlist resolves effective display variant by owned link, then selected variant, then item id', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end

      local namespace = {
        db = {},
        state = {
          bestOwnedLinks = {
            ['item:19019'] = '|Hitem:19019::::::::70::6:1:3524::::::|h[Owned]|h',
          },
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getVariantRef = function(itemRef)
            return itemRef and (itemRef:match('|H([^|]+)|h') or itemRef) or nil
          end,
          getTooltipRef = function(item)
            if item.selectedVariantRef then return item.selectedVariantRef end
            return 'item:' .. tostring(item.itemID)
          end,
        },
      }

      (function(...)
        ${source}
      end)('Addon', namespace)

      return {
        owned = namespace.ResolveEffectiveDisplayVariant({ itemID = 19019, selectedVariantRef = 'item:19019::::::::70::5:1:3524::::::' }),
        selected = namespace.ResolveEffectiveDisplayVariant({ itemID = 17182, selectedVariantRef = 'item:17182::::::::70::5:1:3524::::::' }),
        fallback = namespace.ResolveEffectiveDisplayVariant({ itemID = 18832 }),
      }
    `)

    assert.equal(result.owned, '|Hitem:19019::::::::70::6:1:3524::::::|h[Owned]|h')
    assert.equal(result.selected, 'item:17182::::::::70::5:1:3524::::::')
    assert.equal(result.fallback, 'item:18832')
  } finally {
    lua.global.close()
  }
})

test('self-loot possession refresh marks recent self loot without writing best looted item level', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetTime() return 0 end
      function GetDetailedItemLevelInfo(itemLink)
        if itemLink then
          return 262
        end
        return nil
      end
      function GetInventoryItemLink(unit, slot)
        if unit == 'player' and slot == 1 then
          return '|Hitem:19019::::::::70::6:1:3524::::::|h[Owned]|h'
        end
        return nil
      end

      INVSLOT_FIRST_EQUIPPED = 1
      INVSLOT_LAST_EQUIPPED = 1

      local updateCalls = 0
      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
          hasInitializedPossession = true,
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getItemIdFromLink = function(itemLink)
            if type(itemLink) == 'string' and string.find(itemLink, 'item:19019', 1, true) then
              return 19019
            end
            return nil
          end,
          getVariantRef = function(itemRef)
            return itemRef and (itemRef:match('|H([^|]+)|h') or itemRef) or nil
          end,
          getTooltipRef = function(item)
            return item.selectedVariantRef or ('item:' .. tostring(item.itemID))
          end,
        },
        WishlistStore = {
          getTrackedItems = function()
            return {
              { itemID = 19019, selectedVariantRef = 'item:19019::::::::70::5:1:3524::::::' },
            }
          end,
          getGroupingMode = function() return 'source' end,
        },
        Locales = {
          getString = function(_, _, key)
            return key
          end,
        },
      }

      (function(...)
        ${source}
      end)('Addon', namespace)

      namespace.RefreshPossessionState()

      return {
        wasRecentSelfLoot = namespace.WasRecentSelfLoot(19019),
        isPossessed = namespace.state.possessed['item:19019'],
        bestOwnedLink = namespace.state.bestOwnedLinks['item:19019'],
      }
    `)

    assert.equal(result.wasRecentSelfLoot, true)
    assert.equal(result.isPossessed, true)
    assert.equal(result.bestOwnedLink, '|Hitem:19019::::::::70::6:1:3524::::::|h[Owned]|h')
  } finally {
    lua.global.close()
  }
})

test('loot wishlist extracts localized item track from structured tooltip data', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      Enum = {
        TooltipDataLineType = {
          ItemUpgradeLevel = 42,
        },
      }

      local namespace = {
        db = {},
        state = {},
      }

      (function(...)
        ${source}
      end)('Addon', namespace)

      return namespace.ExtractItemTrackFromTooltipData({
        lines = {
          { type = 1, leftText = 'Ignored' },
          { type = 42, leftText = 'Champion 3/8' },
        },
      })
    `)

    assert.equal(result, 'Champion 3/8')
  } finally {
    lua.global.close()
  }
})

test('loot wishlist trims prefixed upgrade tooltip text down to the track label', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      local namespace = {
        db = {},
        state = {},
      }

      (function(...)
        ${source}
      end)('Addon', namespace)

      return {
        prefixed = namespace.TrimItemTrackLabel('Upgrade Level: Champion 3/8'),
        plain = namespace.TrimItemTrackLabel('Champion 3/8'),
      }
    `)

    assert.equal(result.prefixed, 'Champion')
    assert.equal(result.plain, 'Champion')
  } finally {
    lua.global.close()
  }
})

test('loot wishlist tracker display data omits the old suffix metadata', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetItemInfo(itemRefOrItemID)
        if itemRefOrItemID == 'item:19019::::::::70::5:1:3524::::::' or itemRefOrItemID == 19019 then
          return 'Stormlash Dagger'
        end
        return nil
      end

      Enum = {
        TooltipDataLineType = {
          ItemUpgradeLevel = 42,
        },
      }

      C_TooltipInfo = {
        GetHyperlink = function(itemRef)
          return {
            lines = {
              { type = 42, leftText = 'Upgrade Level: Champion 3/8' },
            },
          }
        end,
      }

      local namespace = {
        db = {},
        state = {
          possessed = {},
          bestOwnedLinks = {},
        },
        ItemResolver = {
          getWishlistKey = function(item)
            return 'item:' .. tostring(item.itemID)
          end,
          getVariantRef = function(itemRef)
            return itemRef
          end,
          getTooltipRef = function(item)
            return item.selectedVariantRef or ('item:' .. tostring(item.itemID))
          end,
        },
        WishlistStore = {
          getTrackedItems = function()
            return {
              {
                itemID = 19019,
                selectedVariantRef = 'item:19019::::::::70::5:1:3524::::::',
                instanceID = 1,
              },
            }
          end,
          getGroupingMode = function() return 'source' end,
        },
        SourceResolver = {
          resolveGroup = function(_, item, otherLabel)
            return { key = 'source:instance:1', label = item.instanceName or otherLabel }
          end,
        },
        TrackerModel = {
          buildGroups = function(items)
            return items
          end,
        },
        Locales = {
          getString = function(_, _, key)
            return key
          end,
        },
      }

      (function(...)
        ${source}
      end)('Addon', namespace)

      local item = namespace.BuildTrackerGroups()[1]
      return {
        itemTrack = item.itemTrack,
        bestLootedItemLevel = item.bestLootedItemLevel,
      }
    `)

    assert.equal(result.itemTrack, undefined)
    assert.equal(result.bestLootedItemLevel, undefined)
  } finally {
    lua.global.close()
  }
})

test('tooltip compare suppresses comparison panes for possessed rows', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'TooltipCompare.lua'), 'utf8')
    .replace(/return TooltipCompare\s*$/, '')

  try {
    const result = await lua.doString(`
      UIParent = {}
      EQUIPPED = 'Equipped'
      NORMAL_FONT_COLOR = { GetRGB = function() return 1, 1, 1 end }

      local function createTexture()
        return {
          SetAllPoints = function() end,
          SetAtlas = function() end,
        }
      end

      local function createFontString()
        local fontString = {}
        function fontString:SetPoint() end
        function fontString:SetText(text)
          self.text = text
        end
        function fontString:SetTextColor() end
        function fontString:GetStringWidth()
          return 60
        end
        return fontString
      end

      function CreateFrame(_, name)
        local frame = { hidden = false, width = 100 }
        function frame:SetFrameStrata() end
        function frame:SetClampedToScreen() end
        function frame:SetFrameLevel() end
        function frame:GetFrameLevel() return 1 end
        function frame:SetPoint(...) self.point = { ... } end
        function frame:ClearAllPoints() self.point = nil end
        function frame:SetSize(width, height) self.width = width self.height = height end
        function frame:SetWidth(width) self.width = width end
        function frame:Hide() self.hidden = true end
        function frame:Show() self.hidden = false end
        function frame:IsShown() return not self.hidden end
        function frame:CreateTexture() return createTexture() end
        function frame:CreateFontString() return createFontString() end
        function frame:SetOwner() end
        function frame:SetHyperlink(link) self.hyperlink = link end
        function frame:GetWidth() return self.width end
        function frame:GetLeft() return 300 end
        function frame:GetRight() return 500 end
        function frame:GetPoint() return 'TOPRIGHT', UIParent, 'TOPLEFT', -4, 0 end
        if name then
          _G[name] = frame
        end
        return frame
      end

      local comparisonCalls = 0
      C_TooltipComparison = {
        GetItemComparisonInfo = function()
          comparisonCalls = comparisonCalls + 1
          return { item = { hyperlink = 'item:18832' } }
        end,
      }

      ${source}

      local tooltip = CreateFrame('GameTooltip')
      function tooltip:GetPrimaryTooltipData()
        return { hyperlink = 'item:19019' }
      end

      TooltipCompare.showComparison(tooltip, { isPossessed = true })

      return {
        comparisonCalls = comparisonCalls,
        compareHidden = LootWishListCompareTooltip1.hidden,
      }
    `)

    assert.equal(result.comparisonCalls, 0)
    assert.equal(result.compareHidden, true)
  } finally {
    lua.global.close()
  }
})

test('tooltip compare keeps comparison panes for unowned rows using the real tooltip ref', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'TooltipCompare.lua'), 'utf8')
    .replace(/return TooltipCompare\s*$/, '')

  try {
    const result = await lua.doString(`
      UIParent = {}
      EQUIPPED = 'Equipped'
      NORMAL_FONT_COLOR = { GetRGB = function() return 1, 1, 1 end }
      function GetScreenWidth() return 1920 end

      local function createTexture()
        return {
          SetAllPoints = function() end,
          SetAtlas = function() end,
        }
      end

      local function createFontString()
        local fontString = {}
        function fontString:SetPoint() end
        function fontString:SetText(text)
          self.text = text
        end
        function fontString:SetTextColor() end
        function fontString:GetStringWidth()
          return 60
        end
        return fontString
      end

      function CreateFrame(_, name)
        local frame = { hidden = false, width = 100 }
        function frame:SetFrameStrata() end
        function frame:SetClampedToScreen() end
        function frame:SetFrameLevel() end
        function frame:GetFrameLevel() return 1 end
        function frame:SetPoint(...) self.point = { ... } end
        function frame:ClearAllPoints() self.point = nil end
        function frame:SetSize(width, height) self.width = width self.height = height end
        function frame:SetWidth(width) self.width = width end
        function frame:Hide() self.hidden = true end
        function frame:Show() self.hidden = false end
        function frame:IsShown() return not self.hidden end
        function frame:CreateTexture() return createTexture() end
        function frame:CreateFontString() return createFontString() end
        function frame:SetOwner() end
        function frame:SetHyperlink(link) self.hyperlink = link end
        function frame:GetWidth() return self.width end
        function frame:GetLeft() return 300 end
        function frame:GetRight() return 500 end
        function frame:GetPoint() return 'TOPRIGHT', UIParent, 'TOPLEFT', -4, 0 end
        if name then
          _G[name] = frame
        end
        return frame
      end

      local comparisonCalls = 0
      C_TooltipComparison = {
        GetItemComparisonInfo = function(item)
          comparisonCalls = comparisonCalls + 1
          return { item = { hyperlink = item.hyperlink } }
        end,
      }

      ${source}

      local tooltip = CreateFrame('GameTooltip')
      function tooltip:GetPrimaryTooltipData()
        return { hyperlink = 'item:19019::::::::70::5:1:3524::::::' }
      end

      TooltipCompare.showComparison(tooltip, {
        isPossessed = false,
        GetLeft = function() return 100 end,
      })

      return {
        comparisonCalls = comparisonCalls,
        compareHidden = LootWishListCompareTooltip1.hidden,
        compareHyperlink = LootWishListCompareTooltip1.hyperlink,
      }
    `)

    assert.equal(result.comparisonCalls, 1)
    assert.equal(result.compareHidden, false)
    assert.equal(result.compareHyperlink, 'item:19019::::::::70::5:1:3524::::::')
  } finally {
    lua.global.close()
  }
})

test('loot events queue a normalized alert record for tracked chat loot outside combat', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootEvents.lua'), 'utf8')
    .replace(/local _, namespace = \.\.\.[\s\S]*$/, '')

  try {
    const result = await lua.doString(`
      LOOT_ITEM = "%s receives loot: %s."
      function issecretvalue(value)
        return false
      end
      function canaccessvalue(value)
        return true
      end
      function InCombatLockdown()
        return false
      end
      function UnitName(unit)
        return "Player"
      end
      function Ambiguate(name, style)
        return name
      end

      ${source}

      local queued = nil
      local namespace = {
        ItemResolver = {
          getItemIdFromLink = function(link)
            if type(link) == "string" and string.find(link, "item:19019", 1, true) then
              return 19019
            end
            return nil
          end,
        },
        IsTrackedItem = function(itemID)
          return itemID == 19019
        end,
        WasRecentSelfLoot = function(itemID)
          return false
        end,
        BuildLootAlertRecord = function(itemID, playerName, itemLink)
          return { itemID = itemID, playerName = playerName, itemLink = itemLink }
        end,
        QueueLootAlert = function(record)
          queued = record
        end,
      }

      LootEvents.HandleChatLoot(namespace, "Teammate receives loot: |Hitem:19019::::::::70:::::|h[Thunderfury]|h.", "Teammate")

      return {
        itemID = queued and queued.itemID,
        playerName = queued and queued.playerName,
        itemLink = queued and queued.itemLink,
      }
    `)

    assert.equal(result.itemID, 19019)
    assert.equal(result.playerName, 'Teammate')
    assert.equal(result.itemLink, '|Hitem:19019::::::::70:::::|h[Thunderfury]|h')
  } finally {
    lua.global.close()
  }
})

test('loot events skip inaccessible chat payloads before parsing or queueing', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootEvents.lua'), 'utf8')
    .replace(
      'local function extractItemLinkFromLootMessage(message)\n',
      'local extractCalls = 0\nlocal function extractItemLinkFromLootMessage(message)\n  extractCalls = extractCalls + 1\n'
    )
    .replace(/local _, namespace = \.\.\.[\s\S]*$/, '')

  try {
    const result = await lua.doString(`
      LOOT_ITEM = "%s receives loot: %s."
      function issecretvalue(value)
        return false
      end
      function canaccessvalue(value)
        return value ~= "blocked-payload"
      end

      ${source}

      local queueCount = 0
      local namespace = {
        ItemResolver = {
          getItemIdFromLink = function(link)
            error("should not try to resolve item link from blocked payload")
          end,
        },
        IsTrackedItem = function(itemID)
          return true
        end,
        WasRecentSelfLoot = function(itemID)
          return false
        end,
        BuildLootAlertRecord = function(itemID, playerName, itemLink)
          return { itemID = itemID, playerName = playerName, itemLink = itemLink }
        end,
        QueueLootAlert = function(record)
          queueCount = queueCount + 1
        end,
      }

      LootEvents.HandleChatLoot(namespace, "blocked-payload", "Teammate")

      return {
        queueCount = queueCount,
        extractCalls = extractCalls,
      }
    `)

    assert.equal(result.queueCount, 0)
    assert.equal(result.extractCalls, 0)
  } finally {
    lua.global.close()
  }
})

test('loot events still queue a normalized alert record during combat', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootEvents.lua'), 'utf8')
    .replace(/local _, namespace = \.\.\.[\s\S]*$/, '')

  try {
    const result = await lua.doString(`
      LOOT_ITEM = "%s receives loot: %s."
      function InCombatLockdown() return true end
      function UnitName(unit)
        return "Player"
      end
      function Ambiguate(name, style)
        return name
      end

      ${source}

      local queued = nil
      local namespace = {
        ItemResolver = {
          getItemIdFromLink = function(link)
            return 19019
          end,
        },
        IsTrackedItem = function(itemID)
          return true
        end,
        WasRecentSelfLoot = function(itemID)
          return false
        end,
        BuildLootAlertRecord = function(itemID, playerName, itemLink)
          return { itemID = itemID, playerName = playerName, itemLink = itemLink }
        end,
        QueueLootAlert = function(record)
          queued = record
        end,
      }

      LootEvents.HandleChatLoot(namespace, "Teammate receives loot: |Hitem:19019::::::::70:::::|h[Thunderfury]|h.", "Teammate")

      return {
        itemID = queued and queued.itemID,
        playerName = queued and queued.playerName,
        itemLink = queued and queued.itemLink,
      }
    `)

    assert.equal(result.itemID, 19019)
    assert.equal(result.playerName, 'Teammate')
    assert.equal(result.itemLink, '|Hitem:19019::::::::70:::::|h[Thunderfury]|h')
  } finally {
    lua.global.close()
  }
})

test('loot events suppress popup when item was recently self-looted', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootEvents.lua'), 'utf8')
    .replace(/local _, namespace = \.\.\.[\s\S]*$/, '')

  try {
    const result = await lua.doString(`
      LOOT_ITEM = "%s receives loot: %s."
      ${source}

      local queueCount = 0
      local namespace = {
        ItemResolver = {
          getItemIdFromLink = function(link)
            return 19019
          end,
        },
        IsTrackedItem = function(itemID)
          return true
        end,
        WasRecentSelfLoot = function(itemID)
          return itemID == 19019
        end,
        BuildLootAlertRecord = function(itemID, playerName)
          return { itemID = itemID, playerName = playerName }
        end,
        QueueLootAlert = function(record)
          queueCount = queueCount + 1
        end,
      }

      LootEvents.HandleChatLoot(namespace, "Teammate receives loot: |Hitem:19019::::::::70:::::|h[Thunderfury]|h.", "Teammate")

      return queueCount
    `)

    assert.equal(result, 0)
  } finally {
    lua.global.close()
  }
})

test('recent self-loot helper expires old markers', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local now = 0
      function GetTime()
        return now
      end
      local function advance(dt)
        now = now + dt
      end

      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        function frame:Hide() end
        function frame:Show() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      local namespace = {
        db = {},
        state = {},
        ItemResolver = {
          getWishlistKey = function(item)
            return "item:" .. tostring(item.itemID)
          end,
        },
      }

      (function(...)
        ${source}
      end)("Addon", namespace)

      namespace.MarkRecentSelfLoot(19019)
      local before = namespace.WasRecentSelfLoot(19019)
      advance(4)
      local after = namespace.WasRecentSelfLoot(19019)

      return { before = before, after = after }
    `)

    assert.equal(result.before, true)
    assert.equal(result.after, false)
  } finally {
    lua.global.close()
  }
})

test('build loot alert record requires the caller-provided item link', async () => {
  const factory = new LuaFactory()
  const lua = await factory.createEngine()
  const source = fs.readFileSync(path.join(process.cwd(), 'LootWishList.lua'), 'utf8')
    .replace(/--@do-not-package@[\s\S]*--@end-do-not-package@\s*$/, '')

  try {
    const result = await lua.doString(`
      local function newFrame()
        local frame = {}
        function frame:RegisterEvent() end
        function frame:SetScript() end
        return frame
      end

      function CreateFrame()
        return newFrame()
      end

      local namespace = {
        db = {},
        state = {},
        WishlistStore = {
          getExistingItemEntry = function(_, _, itemID)
            if itemID == 19019 then
              return {}
            end
            return nil
          end,
        },
      }

      function UnitName() return 'Player' end
      function GetRealmName() return 'Realm' end
      function GetItemInfo(itemID) return 'Thunderfury' end

      (function(...)
        ${source}
      end)('Addon', namespace)

      local withLink = namespace.BuildLootAlertRecord(19019, 'Teammate', '|Hitem:19019::::::::70:::::|h[Looted Thunderfury]|h')
      local withoutLink = namespace.BuildLootAlertRecord(19019, 'Teammate')

      return {
        withLink = withLink and withLink.itemLink or nil,
        withoutLink = withoutLink,
      }
    `)

    assert.equal(result.withLink, '|Hitem:19019::::::::70:::::|h[Looted Thunderfury]|h')
    assert.equal(result.withoutLink, undefined)
  } finally {
    lua.global.close()
  }
})
