## Context

The addon currently persists wishlist entries as a mixed model: base-item identity and loot history sit alongside locale-specific presentation data such as `itemName`, `itemLink`, `sourceLabel`, and `bossName`. That storage model leaks UI concerns into SavedVariables, creates stale data when the client locale changes, and makes it harder to reason about what the wishlist actually owns as durable state.

This refactor is cross-cutting because it changes the wishlist entry schema, the migration path for existing SavedVariables, Adventure Guide selection capture, tracker tooltip fallback, and tracker row text formatting. The repository guidance in `AGENTS.md` favors stable item identity for tracking, keeping persistence minimal, and deriving presentation from Blizzard APIs when possible. The design therefore needs to keep membership broad by base item ID while still preserving enough locale-neutral variant information to present the player-selected Adventure Guide variant when no live owned link is available.

## Goals / Non-Goals

**Goals:**
- Represent tracked membership by entry presence instead of a persisted `tracked` flag.
- Remove locale-specific fields from canonical wishlist storage.
- Preserve durable wishlist data needed for tracker grouping and remembered loot history.
- Persist a locale-neutral `selectedVariantRef` so the tracker can show the selected variant's tooltip and track when the item is not currently owned.
- Keep tracker tooltip and row-suffix behavior aligned to the same effective display variant.
- Migrate existing character data in place without losing tracked items.

**Non-Goals:**
- Making wishlist membership variant-specific.
- Changing loot-alert dialog behavior or other-player loot normalization semantics.
- Changing self-loot remembered item-level rules beyond what is required to read and write the new schema.
- Reworking tracker grouping behavior beyond replacing persisted localized labels with runtime-derived labels from stable IDs.

## Decisions

### 1. Use entry presence as the only tracked-membership signal

Wishlist entries will no longer persist `tracked = true` or tombstone-style `tracked = false` records. A tracked item exists if and only if `characters[characterKey].items[itemID]` exists. Removing an item deletes the entry entirely.

Target entry shape:

- `bestLootedItemLevel?`
- `instanceID?`
- `encounterID?`
- `inventoryType?`
- `selectedVariantRef?`

`inventoryType` remains in the persisted entry because the current tracker grouping requirements expect stable slot grouping without depending on current Encounter Journal state or item-cache timing.

Rationale:
- Presence-based membership matches how the addon conceptually behaves.
- Removing tombstones makes SavedVariables smaller and easier to migrate.
- Retaining only durable, locale-neutral fields keeps persistence aligned with the addon's architecture.

Alternatives considered:
- Keep the `tracked` flag for compatibility: rejected because it preserves redundant state and encourages tombstones.
- Remove `inventoryType` as well: deferred because slot grouping still benefits from stable persisted metadata.

### 2. Persist `selectedVariantRef` as a locale-neutral item reference payload

The selected Adventure Guide variant will be stored as a locale-neutral item-reference payload derived from the selected item link's hyperlink target rather than as a full localized chat-style link. The stored value should preserve the chosen variant identity without storing localized bracket text, color codes, or other presentation-only link decorations.

Rationale:
- This preserves the user's selected variant for later presentation while avoiding locale-specific SavedVariables.
- A locale-neutral item reference is leaner than a full link and better matches the data model's purpose.
- The value remains suitable for later tooltip and track derivation when no live owned item link is available.

Alternatives considered:
- Persist full localized item links: rejected because they are locale-sensitive and presentation-heavy.
- Persist only bonus IDs: rejected because the tracker needs a practical display fallback reference, not only partial variant metadata.
- Persist no selected variant at all: rejected because the user explicitly wants unowned rows to remember the selected Adventure Guide variant.

### 3. Resolve one effective display variant for tracker styling, tooltip, and track text

Tracker presentation will resolve a single effective display variant with this precedence:

1. best currently owned live item link
2. persisted `selectedVariantRef`
3. generic base-item fallback

The tracker row tooltip, quality styling, and item-track extraction all derive from that same effective display variant. This prevents mixed states where the tooltip shows one variant while the row suffix or styling implies another.

Rationale:
- Owned items should always prefer the exact live variant the player currently has.
- Unowned items should still present the variant the player selected in the Adventure Guide.
- A single display-variant pipeline is easier to reason about and test than separate tooltip, styling, and track sources.

Alternatives considered:
- Always prefer the selected Adventure Guide variant even when a better owned link exists: rejected because the tracker is already possession-aware and should prefer the live owned variant when available.
- Derive track text from selected variant but tooltip from owned link: rejected because it creates contradictory UI.

### 4. Replace persisted localized labels with runtime enrichment from stable IDs

Wishlist storage will stop persisting `itemName`, `sourceLabel`, and `bossName`. Tracker and other UI paths that need those values will derive them at runtime from the effective display variant, `itemID`, `instanceID`, and `encounterID` using Blizzard item and Encounter Journal APIs. When a runtime label cannot be resolved, the addon continues to use existing localized fallback strings such as `Other`.

Rationale:
- These values are presentation data and should follow the active client locale.
- Stable source identifiers already exist for the important tracker-grouping and drop-source cases.
- This keeps SavedVariables focused on durable state rather than stale display caches.

Alternatives considered:
- Keep localized labels as a display cache: rejected because it reintroduces stale locale-specific data.
- Force tracker rendering to depend on live Encounter Journal selection: rejected because the existing tracker requirements explicitly avoid that dependency.

### 5. Derive localized item track from structured tooltip data, not rendered tooltip scraping

When the addon needs a localized track label for the effective display variant, it will query `C_TooltipInfo.GetHyperlink(effectiveVariantRef)` and inspect the returned tooltip data for `Enum.TooltipDataLineType.ItemUpgradeLevel`. Numeric item level continues to come from remembered loot history, with `C_Item.GetDetailedItemLevelInfo` remaining available as a non-persisted enrichment source when needed. If tooltip data for the effective variant is initially unavailable, the addon will omit item-track text for that render, register a bounded follow-up refresh trigger using the tooltip-data update path for that addon-owned variant reference, and re-render the tracker when the tooltip data becomes available. The addon will not mutate a live tooltip frame or attempt to parse fragile localized strings.

Rationale:
- Warcraft Wiki documents `C_TooltipInfo.GetHyperlink` as returning structured tooltip lines, including the typed `ItemUpgradeLevel` line, which is the strongest available documented source for Blizzard-localized track text.
- Reading structured tooltip data avoids scraping text from rendered tooltip frames or persisting localized track labels.
- Using addon-owned variant refs with `C_TooltipInfo` keeps track derivation separate from the shared tooltip ownership paths that have previously caused taint problems in this addon.
- A follow-up refresh trigger lets rows converge toward the correct localized track text without blocking the initial tracker render on cache timing.

Alternatives considered:
- Scrape the track from a rendered `GameTooltip` or addon tooltip frame: rejected because it broadens tooltip-state coupling and increases taint risk.
- Persist track text directly: rejected because track text should be derived from the effective display variant and active locale.

### 6. Change tracker suffix formatting to append item level and track together

When the effective display variant exposes both a remembered item level and a localized track label, the tracker suffix will render as `(<ITEM LEVEL> <ITEM TRACK>)`. When only item level is known, the suffix remains `(<ITEM LEVEL>)`. When item level is unknown, no suffix is appended. Item track is never shown by itself without item level.

Rationale:
- The user wants track information only as an extension of the existing item-level progress suffix.
- Omitting track when item level is unknown avoids awkward suffixes that imply remembered progress without an actual remembered level.
- Keeping the formatting rules narrow makes tracker rows consistent and predictable.

Alternatives considered:
- Show item track by itself when item level is unknown: rejected because it changes the semantics of the existing suffix from remembered loot history to general variant labeling.

### 7. Keep runtime enrichment and track derivation on addon-owned, read-only paths

The implementation of this design must not reopen the taint boundaries that earlier tracker and tooltip work removed. Runtime enrichment should use addon-owned values and read-only Blizzard APIs only. In particular:

- no tracker rebuild path should call `EncounterJournal_OpenJournal`, `EJ_SelectInstance`, or otherwise drive live Encounter Journal navigation
- no track-derivation path should mutate `GameTooltip` or reuse Blizzard's shared tooltip ownership as a data source
- `C_TooltipInfo.GetHyperlink` should only be called with addon-owned effective variant refs such as owned item links or persisted `selectedVariantRef`, never with raw unreadable chat payloads or other secret-value sources

Rationale:
- This addon has a documented history of tracker, tooltip, and Encounter Journal taint regressions.
- The design only needs read-only enrichment; it does not need secure or shared-UI control paths.
- Making these boundaries explicit keeps the refactor aligned with prior taint-hardening changes.

Alternatives considered:
- Reuse shared tooltip frames as a convenient source of localized text: rejected because shared tooltip ownership has already been a taint-sensitive area in this addon.
- Requery live Encounter Journal selection during tracker rebuild for richer source text: rejected because prior changes identified tracker-driven journal interaction as a taint source.

### 8. Perform an in-place SavedVariables migration on load

The addon will migrate legacy wishlist entries during initialization before normal reads and writes depend on the new schema. The migration will:

- remove untracked tombstones (`tracked ~= true`)
- preserve durable fields such as `bestLootedItemLevel`, `instanceID`, `encounterID`, and `inventoryType`
- derive `selectedVariantRef` from legacy `itemLink` when possible
- delete locale-specific fields such as `tracked`, `itemName`, `itemLink`, `sourceLabel`, and `bossName`

The migration should be idempotent so repeated loads do not damage already-upgraded entries.

Rationale:
- Existing users must keep their wishlists without manual cleanup.
- In-place migration keeps the upgrade localized to `WishlistStore.lua`, which already owns persistence repair behavior.
- Idempotence lowers risk during partial migrations, reloads, and test coverage.

Alternatives considered:
- Lazy migration on each entry read: rejected because it spreads schema branching throughout runtime code.
- Drop legacy variant information entirely: rejected because the selected variant fallback is part of the user-visible goal.

## Risks / Trade-offs

- [Legacy `itemLink` values may not always yield a clean locale-neutral `selectedVariantRef`] → Preserve the tracked entry, drop invalid localized fields, and fall back to base-item display behavior when variant extraction fails.
- [Runtime label derivation or tooltip-data enrichment may temporarily lack cached item data] → Keep base-item fallback behavior defensive, omit unresolved track text, and avoid blocking tracker rendering on cache availability.
- [Persisted `inventoryType` may remain stale for unusual items] → Retain existing metadata-repair behavior and use stable item APIs to backfill missing values where possible.
- [Proposal/spec contract could drift if unrelated loot-alert behavior is folded into the refactor] → Keep the design scoped to storage, Adventure Guide selection capture, tracker tooltip fallback, and tracker row formatting only.
- [A convenience implementation could reintroduce taint by scraping shared tooltip frames or driving Encounter Journal state] → Keep enrichment on addon-owned, read-only APIs and validate with `taint.log` around tracker hover, Adventure Guide selection, and post-migration refresh.

## Migration Plan

1. Introduce the new schema version and run migration before normal wishlist reads.
2. Convert each character's tracked items in place:
   - delete tombstones and malformed empty entries
   - preserve durable fields
   - derive `selectedVariantRef` from legacy `itemLink` when possible
   - remove localized fields and the legacy `tracked` flag
3. Continue existing metadata repair for missing stable fields such as `inventoryType` where needed.
4. Rebuild tracker state from the migrated entries and runtime API enrichment.

Rollback plan:
- Revert the new schema reader and migration logic before shipping the change. Because the migration removes legacy localized fields, rollback after a released migration would require either restoring from backup or teaching the old reader to tolerate the normalized schema, so rollout should be validated carefully before release.

## Open Questions

- None currently.
