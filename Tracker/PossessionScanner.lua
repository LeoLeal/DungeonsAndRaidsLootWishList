local _, namespace = ...

local PossessionScanner = {}

local function getItemLevel(itemLink)
  if type(GetDetailedItemLevelInfo) == "function" and itemLink then
    return GetDetailedItemLevelInfo(itemLink)
  end

  return nil
end

local function markPossessedFromLink(runtimeNamespace, lookup, highestLevels, bestOwnedLinks, itemLink)
  local itemID = runtimeNamespace.ItemResolver.getItemIdFromLink(itemLink)
  if not itemID then
    return
  end

  local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = itemID })
  lookup[key] = true

  local itemLevel = getItemLevel(itemLink)
  if itemLevel and (not highestLevels[key] or itemLevel > highestLevels[key]) then
    highestLevels[key] = itemLevel
    bestOwnedLinks[key] = itemLink
  elseif not highestLevels[key] then
    bestOwnedLinks[key] = bestOwnedLinks[key] or itemLink
  end
end

function PossessionScanner.Refresh(runtimeNamespace)
  local previousPossessed = runtimeNamespace.state.possessed or {}
  local hasInitializedPossession = runtimeNamespace.state.hasInitializedPossession == true
  local possessed = {}
  local highestLevels = {}
  local bestOwnedLinks = {}

  for slot = INVSLOT_FIRST_EQUIPPED or 1, INVSLOT_LAST_EQUIPPED or 19 do
    markPossessedFromLink(runtimeNamespace, possessed, highestLevels, bestOwnedLinks, GetInventoryItemLink("player", slot))
  end

  if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemLink then
    for bag = BACKPACK_CONTAINER or 0, NUM_BAG_SLOTS or 4 do
      local numSlots = C_Container.GetContainerNumSlots(bag)
      for slot = 1, numSlots do
        markPossessedFromLink(runtimeNamespace, possessed, highestLevels, bestOwnedLinks, C_Container.GetContainerItemLink(bag, slot))
      end
    end

    if runtimeNamespace.state.bankKnown then
      if BANK_CONTAINER then
        local numBankSlots = C_Container.GetContainerNumSlots(BANK_CONTAINER) or 0
        for slot = 1, numBankSlots do
          markPossessedFromLink(runtimeNamespace, possessed, highestLevels, bestOwnedLinks,
            C_Container.GetContainerItemLink(BANK_CONTAINER, slot))
        end
      end

      local firstBankBag = (NUM_BAG_SLOTS or 4) + 1
      local lastBankBag = (NUM_BAG_SLOTS or 4) + (NUM_BANKBAGSLOTS or 7)
      for bag = firstBankBag, lastBankBag do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
          markPossessedFromLink(runtimeNamespace, possessed, highestLevels, bestOwnedLinks,
            C_Container.GetContainerItemLink(bag, slot))
        end
      end
    end
  end

  runtimeNamespace.state.possessed = possessed
  runtimeNamespace.state.bestOwnedLinks = bestOwnedLinks

  local trackedItems = runtimeNamespace.WishlistStore.getTrackedItems(runtimeNamespace.GetCurrentDb(), runtimeNamespace.GetCharacterKey())
  for _, item in ipairs(trackedItems) do
    local key = runtimeNamespace.ItemResolver.getWishlistKey({ itemID = item.itemID })
    if hasInitializedPossession and possessed[key] and not previousPossessed[key] then
      runtimeNamespace.MarkRecentSelfLoot(item.itemID)
    end
  end

  runtimeNamespace.state.hasInitializedPossession = true
end

if type(namespace) == "table" then
  namespace.PossessionScanner = PossessionScanner
end

return PossessionScanner
