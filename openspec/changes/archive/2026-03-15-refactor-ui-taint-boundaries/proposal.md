## Why

The addon currently reaches into several Blizzard-owned UI systems through taint-prone integration points, especially the Objective Tracker update path, recycled Encounter Journal loot buttons, shared tooltip objects, and deferred loot-alert popups. These boundaries have already produced tooltip failures, secret-value errors, and combat-sensitive UI breakage.

This change is needed to keep the current wishlist experience while moving the implementation onto safer UI ownership boundaries. The goal is to preserve how the addon looks and behaves to players without continuing to contaminate Blizzard tracker, tooltip, Encounter Journal, or popup execution paths.

## What Changes

- Refactor tracker rendering so the wishlist continues to appear visually integrated with the Objective Tracker without requiring direct participation in Blizzard's native tracker module update path.
- Replace taint-prone mutations of Blizzard-owned pooled frames with addon-owned state and narrower integration points, especially for tracker rows and Encounter Journal loot rows.
- Preserve current hover, click, collapse, source-group, and loot-roll behaviors while isolating tooltip ownership and row interactions from shared Blizzard frame state.
- Refactor loot alert handling so tracked-loot notifications preserve the same user-facing dialog behavior while avoiding deferred use of tainted event payloads and insecure popup execution paths.
- Audit Encounter Journal, tracker, and loot-event flows so source resolution, tracking toggles, and alerts continue to work without depending on unsafe frame scanning or global UI state mutation where a safer boundary exists.

## Capabilities

### New Capabilities
_None._

### Modified Capabilities
- `wishlist-tracker-display`: Change tracker requirements so the wishlist section keeps its current appearance and interactions without requiring direct native Objective Tracker module registration or taint-prone ownership of Blizzard pooled tracker lines.
- `tracker-item-tooltips`: Clarify tooltip requirements so wishlist row hover preserves Blizzard-native item tooltip behavior without relying on taint-prone shared tooltip ownership patterns.
- `wishlist-loot-awareness`: Clarify loot-event requirements so tracked-item reactions preserve current roll-tag and alert behavior even when alert display must be deferred until a safe UI state.
- `loot-alert-dialog`: Clarify alert-dialog requirements so the same visible popup behavior is preserved when dialog content must be reconstructed from addon-owned state instead of raw event payloads.

## Impact

- **Primary systems affected**: `TrackerUI.lua`, `AdventureGuideUI.lua`, `LootEvents.lua`, `LootWishList.lua`
- **Supporting systems affected**: `TrackerModel.lua`, `ItemResolver.lua`, `WishlistStore.lua`, existing OpenSpec specs covering tracker display, tooltips, loot awareness, and alert dialogs
- **User-facing intent**: preserve the existing wishlist UI points, including tracker grouping, row interactions, Adventure Guide toggles, loot roll tags, and loot alerts
- **Risk reduction**: reduce or eliminate structural taint propagation into Blizzard tracker, tooltip, Encounter Journal, and popup flows
