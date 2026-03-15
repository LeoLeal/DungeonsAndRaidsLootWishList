local Locales = {}

local translations = {
  enUS = {
    LOOT_WISHLIST = "Loot Wishlist",
    WISHLIST = "Wishlist",
    OTHER = "Other",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s looted an item on your Wishlist!",
  },
  enGB = {
    LOOT_WISHLIST = "Loot Wishlist",
    WISHLIST = "Wishlist",
    OTHER = "Other",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s looted an item on your Wishlist!",
  },
  deDE = {
    LOOT_WISHLIST = "Beuteliste",
    WISHLIST = "Wunschliste",
    OTHER = "Sonstiges",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s hat einen Gegenstand von deiner Wunschliste erbeutet!",
  },
  esES = {
    LOOT_WISHLIST = "Lista de botin deseado",
    WISHLIST = "Lista de deseos",
    OTHER = "Otros",
    PLAYER_LOOTED_WISHLIST_ITEM = "¡%s ha saqueado un objeto de tu lista de deseos!",
  },
  esMX = {
    LOOT_WISHLIST = "Lista de botin deseado",
    WISHLIST = "Lista de deseos",
    OTHER = "Otros",
    PLAYER_LOOTED_WISHLIST_ITEM = "¡%s ha saqueado un objeto de tu lista de deseos!",
  },
  frFR = {
    LOOT_WISHLIST = "Liste de butin",
    WISHLIST = "Liste de souhaits",
    OTHER = "Autre",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s a obtenu un objet de votre liste de souhaits !",
  },
  itIT = {
    LOOT_WISHLIST = "Lista bottino desiderato",
    WISHLIST = "Lista dei desideri",
    OTHER = "Altro",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s ha ottenuto un oggetto dalla tua lista dei desideri!",
  },
  koKR = {
    LOOT_WISHLIST = "전리품 위시리스트",
    WISHLIST = "위시리스트",
    OTHER = "기타",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s님이 위시리스트에 있는 아이템을 전리품으로 획득했습니다!",
  },
  ptBR = {
    LOOT_WISHLIST = "Lista de Saque Desejado",
    WISHLIST = "Lista de Desejos",
    OTHER = "Outros",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s saqueou um item da sua Lista de Desejos!",
  },
  ruRU = {
    LOOT_WISHLIST = "Список желаемой добычи",
    WISHLIST = "Список желаний",
    OTHER = "Другое",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s получил(а) предмет из Вашего списка желаний!",
  },
  zhCN = {
    LOOT_WISHLIST = "战利品心愿单",
    WISHLIST = "心愿单",
    OTHER = "其他",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s 拾取了您愿望清单上的一件物品！",
  },
  zhTW = {
    LOOT_WISHLIST = "戰利品願望清單",
    WISHLIST = "願望清單",
    OTHER = "其他",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s 拾取了您願望清單上的一件物品！",
  },
}

function Locales.getSupportedLocales()
  local localeIds = {}

  for localeId in pairs(translations) do
    table.insert(localeIds, localeId)
  end

  table.sort(localeIds)

  return localeIds
end

function Locales.getLocale(localeId)
  return translations[localeId] or translations.enUS
end

function Locales.getString(localeId, key, ...)
  local locale = Locales.getLocale(localeId)
  local value = locale[key] or translations.enUS[key] or key

  if select("#", ...) > 0 then
    return string.format(value, ...)
  end

  return value
end

local _, namespace = ...
if type(namespace) == "table" then
  namespace.Locales = Locales
end

return Locales
