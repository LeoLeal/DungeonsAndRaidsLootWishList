local Locales = {}

local translations = {
  enUS = {
    LOOT_WISHLIST = "Loot Wishlist",
    WISHLIST = "Wishlist",
    WISHLIST_WITH_TAGS = "Wishlist: %s",
    REMOVE = "Remove",
    CREATE = "Create",
    CREATE_NEW_TAG = "Create a new tag",
    OTHER = "Other",
    LOOT_SOURCE = "Source",
    EQUIPMENT_SLOT = "Slot",
    DEFAULT_WISHLIST_TAG = "Best in slot",
    WISHLIST_TAGS = "Select this item's tags",
    TAG_FILTER = "Filter tags",
    TAG_DELETE_CONFIRMATION_TITLE = "Are you sure you want to continue?",
    TAG_DELETE_CONFIRMATION = "These items will be removed from the wishlist if you delete this tag.",
    TAG_DELETE_AFFECTED_ITEMS = "Affected items",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s looted an item on your Wishlist (%s)!",
  },
  deDE = {
    LOOT_WISHLIST = "Beuteliste",
    WISHLIST = "Wunschliste",
    WISHLIST_WITH_TAGS = "Wunschliste: %s",
    REMOVE = "Entfernen",
    CREATE = "Erstellen",
    CREATE_NEW_TAG = "Neuen Tag erstellen",
    OTHER = "Sonstiges",
    LOOT_SOURCE = "Quelle",
    EQUIPMENT_SLOT = "Slot",
    DEFAULT_WISHLIST_TAG = "Beste im Slot",
    WISHLIST_TAGS = "Wähle die Tags dieses Gegenstands",
    TAG_FILTER = "Tags filtern",
    TAG_DELETE_CONFIRMATION_TITLE = "Bist du sicher, dass du fortfahren möchtest?",
    TAG_DELETE_CONFIRMATION = "Diese Gegenstände werden aus der Wunschliste entfernt, wenn du diesen Tag löschst.",
    TAG_DELETE_AFFECTED_ITEMS = "Betroffene Gegenstände",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s hat einen Gegenstand von deiner Wunschliste (%s) erbeutet!",
  },
  esES = {
    LOOT_WISHLIST = "Lista de botín deseado",
    WISHLIST = "Lista de deseos",
    WISHLIST_WITH_TAGS = "Lista de deseos: %s",
    REMOVE = "Eliminar",
    CREATE = "Crear",
    CREATE_NEW_TAG = "Crear una nueva etiqueta",
    OTHER = "Otros",
    LOOT_SOURCE = "Fuente",
    EQUIPMENT_SLOT = "Ranura",
    DEFAULT_WISHLIST_TAG = "Lo mejor en la ranura",
    WISHLIST_TAGS = "Selecciona las etiquetas de este objeto",
    TAG_FILTER = "Filtrar etiquetas",
    TAG_DELETE_CONFIRMATION_TITLE = "¿Quieres continuar?",
    TAG_DELETE_CONFIRMATION = "Estos objetos se eliminarán de la lista de deseos si borras esta etiqueta.",
    TAG_DELETE_AFFECTED_ITEMS = "Objetos afectados",
    PLAYER_LOOTED_WISHLIST_ITEM = "¡%s ha saqueado un objeto de tu lista de deseos (%s)!",
  },
  frFR = {
    LOOT_WISHLIST = "Liste de butin",
    WISHLIST = "Liste de souhaits",
    WISHLIST_WITH_TAGS = "Liste de souhaits : %s",
    REMOVE = "Supprimer",
    CREATE = "Créer",
    CREATE_NEW_TAG = "Créer une nouvelle étiquette",
    OTHER = "Autre",
    LOOT_SOURCE = "Source",
    EQUIPMENT_SLOT = "Slot",
    DEFAULT_WISHLIST_TAG = "Meilleur de l'emplacement",
    WISHLIST_TAGS = "Sélectionnez les étiquettes de cet objet",
    TAG_FILTER = "Filtrer les étiquettes",
    TAG_DELETE_CONFIRMATION_TITLE = "Voulez-vous vraiment continuer ?",
    TAG_DELETE_CONFIRMATION = "Ces objets seront retirés de la liste de souhaits si vous supprimez cette étiquette.",
    TAG_DELETE_AFFECTED_ITEMS = "Objets concernés",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s a obtenu un objet de votre liste de souhaits (%s) !",
  },
  itIT = {
    LOOT_WISHLIST = "Lista bottino desiderato",
    WISHLIST = "Lista dei desideri",
    WISHLIST_WITH_TAGS = "Lista dei desideri: %s",
    REMOVE = "Rimuovi",
    CREATE = "Crea",
    CREATE_NEW_TAG = "Crea una nuova etichetta",
    OTHER = "Altro",
    LOOT_SOURCE = "Fonte",
    EQUIPMENT_SLOT = "Slot",
    DEFAULT_WISHLIST_TAG = "Migliore nello slot",
    WISHLIST_TAGS = "Seleziona i tag di questo articolo",
    TAG_FILTER = "Filtra etichette",
    TAG_DELETE_CONFIRMATION_TITLE = "Vuoi continuare?",
    TAG_DELETE_CONFIRMATION = "Questi oggetti saranno rimossi dalla lista dei desideri se elimini questa etichetta.",
    TAG_DELETE_AFFECTED_ITEMS = "Oggetti interessati",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s ha ottenuto un oggetto dalla tua lista dei desideri (%s)!",
  },
  koKR = {
    LOOT_WISHLIST = "전리품 위시리스트",
    WISHLIST = "위시리스트",
    WISHLIST_WITH_TAGS = "위시리스트: %s",
    REMOVE = "제거",
    CREATE = "생성",
    CREATE_NEW_TAG = "새 태그 만들기",
    OTHER = "기타",
    LOOT_SOURCE = "출처",
    EQUIPMENT_SLOT = "슬롯",
    DEFAULT_WISHLIST_TAG = "최고 장착",
    WISHLIST_TAGS = "이 항목의 태그를 선택하세요",
    TAG_FILTER = "태그 필터",
    TAG_DELETE_CONFIRMATION_TITLE = "계속하시겠습니까?",
    TAG_DELETE_CONFIRMATION = "이 태그를 삭제하면 이 아이템들은 위시리스트에서 제거됩니다.",
    TAG_DELETE_AFFECTED_ITEMS = "영향받는 아이템",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s님이 위시리스트 (%s)에 있는 아이템을 전리품으로 획득했습니다!",
  },
  ptBR = {
    LOOT_WISHLIST = "Lista de Saque Desejado",
    WISHLIST = "Lista de Desejos",
    WISHLIST_WITH_TAGS = "Lista de Desejos: %s",
    REMOVE = "Remover",
    CREATE = "Criar",
    CREATE_NEW_TAG = "Criar nova tag",
    OTHER = "Outros",
    LOOT_SOURCE = "Fonte",
    EQUIPMENT_SLOT = "Slot",
    DEFAULT_WISHLIST_TAG = "Melhor no encaixe",
    WISHLIST_TAGS = "Selecione as tags deste item",
    TAG_FILTER = "Filtrar tags",
    TAG_DELETE_CONFIRMATION_TITLE = "Tem certeza de que deseja continuar?",
    TAG_DELETE_CONFIRMATION = "Esses itens serão removidos da lista de desejos se você excluir esta etiqueta.",
    TAG_DELETE_AFFECTED_ITEMS = "Itens afetados",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s saqueou um item da sua Lista de Desejos (%s)!",
  },
  ruRU = {
    LOOT_WISHLIST = "Список желаемой добычи",
    WISHLIST = "Список желаний",
    WISHLIST_WITH_TAGS = "Список желаний: %s",
    REMOVE = "Удалить",
    CREATE = "Создать",
    CREATE_NEW_TAG = "Создать новый тег",
    OTHER = "Другое",
    LOOT_SOURCE = "Источник",
    EQUIPMENT_SLOT = "Слот",
    DEFAULT_WISHLIST_TAG = "Лучшее в слоте",
    WISHLIST_TAGS = "Выберите теги этого предмета",
    TAG_FILTER = "Фильтр тегов",
    TAG_DELETE_CONFIRMATION_TITLE = "Вы уверены, что хотите продолжить?",
    TAG_DELETE_CONFIRMATION = "Эти предметы будут удалены из списка желаний, если Вы удалите этот тег.",
    TAG_DELETE_AFFECTED_ITEMS = "Затронутые предметы",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s получил(а) предмет из Вашего списка желаний (%s)!",
  },
  zhCN = {
    LOOT_WISHLIST = "战利品心愿单",
    WISHLIST = "心愿单",
    WISHLIST_WITH_TAGS = "心愿单: %s",
    REMOVE = "移除",
    CREATE = "创建",
    CREATE_NEW_TAG = "创建新标签",
    OTHER = "其他",
    LOOT_SOURCE = "来源",
    EQUIPMENT_SLOT = "栏位",
    DEFAULT_WISHLIST_TAG = "最佳部位",
    WISHLIST_TAGS = "选择此商品的标签",
    TAG_FILTER = "筛选标签",
    TAG_DELETE_CONFIRMATION_TITLE = "确定要继续吗？",
    TAG_DELETE_CONFIRMATION = "如果删除此标签，这些物品将从心愿单中移除。",
    TAG_DELETE_AFFECTED_ITEMS = "受影响物品",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s 拾取了您愿望清单(%s)上的一件物品！",
  },
  zhTW = {
    LOOT_WISHLIST = "戰利品願望清單",
    WISHLIST = "願望清單",
    WISHLIST_WITH_TAGS = "願望清單: %s",
    REMOVE = "移除",
    CREATE = "建立",
    CREATE_NEW_TAG = "建立新標籤",
    OTHER = "其他",
    LOOT_SOURCE = "來源",
    EQUIPMENT_SLOT = "欄位",
    DEFAULT_WISHLIST_TAG = "最佳欄位",
    WISHLIST_TAGS = "選擇此物品的標籤",
    TAG_FILTER = "篩選標籤",
    TAG_DELETE_CONFIRMATION_TITLE = "確定要繼續嗎？",
    TAG_DELETE_CONFIRMATION = "如果刪除此標籤，這些物品將從願望清單中移除。",
    TAG_DELETE_AFFECTED_ITEMS = "受影響物品",
    PLAYER_LOOTED_WISHLIST_ITEM = "%s 拾取了您願望清單(%s)上的一件物品！",
  },
}

translations.enGB = translations.enUS
translations.esMX = translations.esES

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
