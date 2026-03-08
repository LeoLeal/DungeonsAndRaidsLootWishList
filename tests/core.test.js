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
    close() {
      lua.global.close()
    },
  }
}

test('wishlist store persists tracked items and best looted item levels per character', async () => {
  const { module: store, close } = await loadLuaModule('WishlistStore.lua')
  const db = {}

  try {
    store.ensureCharacter(db, 'Player-Realm')
    store.setTracked(db, 'Player-Realm', 19019, true)
    store.updateBestLootedItemLevel(db, 'Player-Realm', 19019, 262)

    assert.equal(store.isTracked(db, 'Player-Realm', 19019), true)
    assert.equal(store.getBestLootedItemLevel(db, 'Player-Realm', 19019), 262)
    assert.deepEqual(db.characters['Player-Realm'].items[19019], {
      tracked: true,
      bestLootedItemLevel: 262,
    })
  } finally {
    close()
  }
})

test('item resolver collapses higher item level variants to the same wishlist key', async () => {
  const { module: resolver, close } = await loadLuaModule('ItemResolver.lua')

  try {
    assert.equal(resolver.getWishlistKey({ itemID: 19019, itemLink: '|Hitem:19019::::::::70:::::|h[Thunderfury]|h' }), 'item:19019')
    assert.equal(resolver.getWishlistKey({ itemID: 19019, itemLink: '|Hitem:19019::::::::70:66::5:5:7982:10355:6652:1507:8767:1:28:1279:::::|h[Thunderfury]|h' }), 'item:19019')
  } finally {
    close()
  }
})

test('source resolver groups items by source and falls back to Other', async () => {
  const { module: sourceResolver, close } = await loadLuaModule('SourceResolver.lua')

  try {
    assert.equal(sourceResolver.getGroupLabel({ itemID: 19019, instanceName: 'Blackwing Lair' }), 'Blackwing Lair')
    assert.equal(sourceResolver.getGroupLabel({ itemID: 19019 }), 'Other')
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

test('tracker model groups rows by source and keeps best ilvl separate from possession', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { itemID: 1, itemName: 'Stormlash Dagger', groupLabel: 'Operation: Floodgate', isPossessed: false, bestLootedItemLevel: 262 },
      { itemID: 2, itemName: 'Circuit Breaker', groupLabel: 'Operation: Floodgate', isPossessed: true },
      { itemID: 3, itemName: 'Unknown Relic', groupLabel: 'Other', isPossessed: false },
    ])

    assert.equal(grouped.length, 2)
    assert.equal(grouped[0].label, 'Operation: Floodgate')
    assert.equal(grouped[0].items[0].displayText, '- Stormlash Dagger (262)')
    assert.equal(grouped[0].items[0].showTick, false)
    assert.equal(grouped[0].items[1].displayText, 'Circuit Breaker')
    assert.equal(grouped[0].items[1].showTick, true)
    assert.equal(grouped[1].items[0].displayText, '- Unknown Relic')
    assert.equal(grouped[1].label, 'Other')
  } finally {
    close()
  }
})

test('tracker model keeps the localized fallback group at the end', async () => {
  const { module: trackerModel, close } = await loadLuaModule('TrackerModel.lua')

  try {
    const grouped = trackerModel.buildGroups([
      { itemID: 1, itemName: 'Unknown Relic', groupLabel: 'Autre', isPossessed: false },
      { itemID: 2, itemName: 'Stormlash Dagger', groupLabel: "Zul'Gurub", isPossessed: false },
    ], 'Autre')

    assert.equal(grouped[0].label, "Zul'Gurub")
    assert.equal(grouped[1].label, 'Autre')
  } finally {
    close()
  }
})

test('localization contains required wishlist keys for all supported locales', async () => {
  const { module: locales, close } = await loadLuaModule('Locales.lua')

  try {
    const requiredKeys = ['LOOT_WISHLIST', 'WISHLIST', 'OTHER', 'PLAYER_LOOTED_WISHLIST_ITEM']
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

test('tracker row style uses quest-style check atlas and row padding', async () => {
  const { module: trackerRowStyle, close } = await loadLuaModule('TrackerRowStyle.lua')

  try {
    const incomplete = trackerRowStyle.getRowLayout(false)
    const complete = trackerRowStyle.getRowLayout(true)

    assert.equal(trackerRowStyle.CHECK_ATLAS, 'ui-questtracker-tracker-check')
    assert.equal(trackerRowStyle.CHECK_SIZE, 16)
    assert.equal(incomplete.textLeftOffset, 20)
    assert.equal(complete.textLeftOffset, 24)
    assert.equal(complete.checkLeftOffset, 8)
  } finally {
    close()
  }
})

test('item resolver getTooltipRef prefers saved item link over stable identity fallback', async () => {
  const { module: resolver, close } = await loadLuaModule('ItemResolver.lua')

  try {
    const link = '|Hitem:19019::::::::70:::::|h[Thunderfury]|h'
    assert.equal(
      resolver.getTooltipRef({ itemID: 19019, itemLink: link }),
      link,
      'should return the saved item link when present'
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
