# Design

## Context

See `proposal.md` for the confirmed runtime failure and scope. The addon targets Retail (`Interface: 120100`), not Classic or legacy clients.

`Core/Bootstrap.lua` exposes `namespace.GetItemInfoName`, but its availability guard and lookup inspect only the global `GetItemInfo`. `Tracker/TrackerRenderData.lua` tries that helper with the effective variant and then the stable item ID before producing an item-ID label. `Tracker/TrackerRows.lua` separately uses global `GetItemInfo` for rarity color. Tooltip rendering uses frame item methods, and possession detection extracts stable IDs from inventory links; neither requires the name lookup to succeed.

Related modules contain legacy item-info, icon, inventory-type, detailed-item-level, and quality-color lookups. Missing aliases can quietly disable these enrichments too. There is no existing local test suite in the current repository.

## Goals / Non-Goals

**Goals:**

- Correct the API dependency at each responsible lookup rather than compensate in grouping, persistence, or frame layout.
- Preserve return-value handling, effective variant references, and safe nil-data behavior.
- Make the confirmed missing-global environment reproducible with small stubbed Lua regression checks.

**Non-Goals:**

- Introduce a general compatibility framework, a shared-namespace refactor, or support for Classic clients.
- Restore deprecated globals, modify Blizzard API tables, or alter Objective Tracker integration.
- Add item-data caches, asynchronous load requests, or new item-data event subscriptions. Those address a separate unconfirmed cache-timing issue.
- Change the saved-variable schema, persist item names, add suffixes, redesign alerts, or alter tracker geometry.

## Decisions

### 1. Use supported namespaced APIs in existing responsible helpers

Update the existing name helper to check and call `C_Item.GetItemInfo`, and update tracker row quality lookup to use that API for the effective display reference. Preserve the helper's nil/empty-name handling and the renderer's default-color fallback. Check the namespace and function defensively without treating the absence of a legacy alias as missing data.

This keeps the tracker fix local while automatically restoring name resolution for consumers of `namespace.GetItemInfoName`. Do not move presentation logic into `ItemResolver` or grow bootstrap orchestration.

**Alternatives considered:** A global alias shim is rejected because it mutates shared Blizzard state and hides remaining outdated dependencies. A new adapter module is unnecessary for straightforward namespaced replacements. Legacy-global fallback support is unnecessary for this Retail-targeted change.

### 2. Preserve the existing display reference and data flow

Keep effective-reference priority in `Tracker/TrackerRenderData.lua`: best owned link, persisted selected variant, then stable base item. Keep the two-stage name lookup and use effective-variant data for quality. Do not derive row names from tooltip text or persisted links' display labels.

**Alternative considered:** Parsing names and colors out of links would fail for normalized `item:` payloads and would duplicate the game's localized item data resolution.

### 3. Bound related updates to equivalent item API replacements

Audit the related files listed in the proposal, including development-only commands in bootstrap. Verify signatures against current Blizzard API documentation before replacing calls. Expected mappings are:

| Existing global | Namespaced equivalent |
| --- | --- |
| `GetItemInfo` | `C_Item.GetItemInfo` |
| `GetItemInfoInstant` | `C_Item.GetItemInfoInstant` |
| `GetItemIcon` | `C_Item.GetItemIconByID` |
| `GetDetailedItemLevelInfo` | `C_Item.GetDetailedItemLevelInfo` |
| `GetItemQualityColor` | `C_Item.GetItemQualityColor` |

Use APIs accepting IDs or links for existing ID/link inputs; do not substitute location-only methods such as `C_Item.GetItemIcon` without an item location. Retain existing fallback icons, colors, and nil results. Keep alert dropped-link selection and possession best-owned-link ranking intact.

**Alternative considered:** Only changing the tracker would resolve the reported symptom but leave directly related unsupported calls in other existing item surfaces. Broader UI or event refactoring is rejected as unrelated.

### 4. Validate with focused stubs and in-game checks

Add a lightweight local Lua regression harness, without external dependencies or a WoW-frame simulation framework. Exercise the name helper with minimal bootstrap stubs, group construction with dependency stubs, and item-row rendering with small row/font-string doubles. Set legacy globals to nil while providing `C_Item` stubs. Cover successful resolution, base-item name fallback, missing data, and effective-variant quality selection. Include distinct variant qualities and item levels so tests detect accidentally replacing variant references with base IDs or losing best-owned selection.

Manual checks remain necessary for real frame presentation, rarity colors, and tooltip behavior. Record those separately from automated results; do not claim live checks completed from local stubs.

## Risks / Trade-offs

- [Namespaced methods with similar names accept different input types] → Verify ID/link signatures, particularly the icon mapping, before changing related consumers.
- [Item data can still be unavailable immediately after login] → Preserve current fallback behavior and distinguish that separate condition from the confirmed missing-global failure; defer asynchronous recovery design.
- [A missing item-level alias can degrade best-owned-link selection without removing possession ticks] → Include possession-scanner ranking checks when migrating that lookup.
- [Local stubs cannot prove live rendering or secure integration] → Validate in game with the legacy globals absent, using tracked owned and unowned items, both grouping modes, and both attachment modes.
- [The existing unrelated shared-namespace change could overlap helper wiring later] → Keep this change local and do not modify that change's artifacts or combine its refactor with the compatibility fix.

## Migration Plan

1. Implement and run local regression checks, verify syntax, and audit remaining scoped legacy calls.
2. Reload the addon in the affected Retail client and perform the manual checks. Existing wishlist entries must recover names and colors without re-tracking items.
3. Release through the existing packaging process; no saved-variable migration or reset is required.
4. If a regression occurs, roll back only this change's code and reload the UI. Saved wishlist state remains compatible, although the original missing-global display defect would return.
