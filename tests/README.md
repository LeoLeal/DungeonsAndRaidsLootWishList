# Item API compatibility regression checks

Run from the addon root with Lua 5.1 or LuaJIT (no third-party libraries):

```sh
lua5.1 tests/item_api_compatibility.lua
luajit tests/item_api_compatibility.lua
```

An optional argument selects tests by a literal substring of their names:

```sh
lua5.1 tests/item_api_compatibility.lua name
```

The harness loads actual addon modules into an isolated environment with the
legacy item globals absent and `C_Item` stubs supplied. Small widget doubles
record text, color, texture, tooltip references, scripts, and visibility; they
do not simulate WoW layout, protected execution, or the live item cache.
The tests are excluded from release packages by the existing `.pkgmeta` rule.

## Regression evidence

Before the tracker fix, 5 of the initial 10 tests failed: direct name resolution,
effective-variant names, base-item name fallback, rarity color, and resolved names
in both grouping modes. The nil-data, fallback-row, and variant-priority checks
passed. After the tracker fix, all 10 passed under Lua 5.1.

Related presentation checks exercise the actual alert and tag-delete entrypoints
with widget doubles. Before their API updates, three new checks failed on icons,
base-item links, and selected-variant presentation; afterward all 14 checks passed.
Dropped/selected references, default icon/color behavior, and dismissal are covered.

Three further checks reproduced inventory-type resolution, metadata repair, and
best-owned-link ranking failures before those API updates. After the updates,
all 18 checks passed. They cover unchanged stable identity, tags and schema,
and continued possession detection when item-level data is unavailable.

Final local verification: all 18 tests pass under both Lua 5.1 and LuaJIT;
`luac5.1 -p` accepts all seven changed runtime files and the test harness;
`git diff --check` and strict OpenSpec validation pass. A scoped source search
finds no remaining bare legacy item API references in runtime Lua modules.
Live-client verification was accepted from the user's confirmation:
"test is done. Everything works." This is user-reported validation, separate
from the automated checks; no individual scenario logs were supplied.

The user's in-game diagnostics confirmed only the `GetItemInfo` incompatibility:
the global is nil while `C_Item.GetItemInfo` returns the correct item data.
Related legacy lookups are compatibility exposures found in the code, not
separate user-reported failures.

## Scoped API audit

Signatures verified against Blizzard's generated
[ItemDocumentation.lua](https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
and ID/link usage in Blizzard's
[Item.lua](https://github.com/tomrus88/BlizzardInterfaceCode/blob/master/Interface/AddOns/Blizzard_ObjectAPI/Mainline/Item.lua).

| Legacy global | Supported equivalent | Input / result used here | Affected code |
| --- | --- | --- | --- |
| `GetItemInfo` | `C_Item.GetItemInfo` | `ItemInfo` ID or item link/payload; first three results are name, link, quality | Bootstrap name helper and development commands, tracker rows, tag delete confirmation, loot alert dialog |
| `GetItemIcon` | `C_Item.GetItemIconByID` | `ItemInfo` ID or item link/payload; icon file ID or nil | Tag delete confirmation, loot alert dialog, development roll command |
| `GetItemInfoInstant` | `C_Item.GetItemInfoInstant` | `ItemInfo` ID; fourth result is inventory-type token | Item resolver, wishlist metadata repair |
| `GetDetailedItemLevelInfo` | `C_Item.GetDetailedItemLevelInfo` | `ItemInfo` owned link; first result is actual item level | Possession scanner best-owned-link ranking |
| `GetItemQualityColor` | `C_Item.GetItemQualityColor` | Item-quality enum; first three results are RGB | Tag delete confirmation, loot alert dialog, development roll command |

Do not replace ID/link icon lookups with `C_Item.GetItemIcon`: that method
requires an `ItemLocation`, not the `ItemInfo` accepted by `GetItemIconByID`.
Only equivalent lookups are in scope; no global aliases or Blizzard API writes
are introduced. Remaining bare API names in tests/documentation are intentional
descriptions or assertions that the legacy globals are absent, not runtime calls.

## Live-client checklist — user-confirmed

Local stubs cannot establish real frame appearance or taint behavior. Record
live results separately; do not mark them passed solely because the tests pass.
The following checklist is retained for future regression testing. The user
confirmed successful live testing overall, rather than supplying per-case logs.

1. Keep the existing wishlist and reload the UI. Do not reset saved variables
   or remove/re-add items as a workaround.
2. Confirm `/dump type(GetItemInfo), type(C_Item.GetItemInfo)` reports
   `"nil", "function"` on the affected client.
3. Verify this matrix using cached tracked items:

| Attachment | Grouping | Item state | Expected |
| --- | --- | --- | --- |
| Attached | Loot source | Owned | Localized name, effective owned-variant rarity color, green tick, correct tooltip |
| Attached | Loot source | Unowned | Localized name, selected/base variant rarity color, no tick, correct tooltip |
| Attached | Equipment slot | Owned | Same presentation, correct slot group |
| Attached | Equipment slot | Unowned | Same presentation, correct slot group |
| Detached | Loot source | Owned | Same presentation, independent detached frame |
| Detached | Loot source | Unowned | Same presentation, independent detached frame |
| Detached | Equipment slot | Owned | Same presentation, correct slot group |
| Detached | Equipment slot | Unowned | Same presentation, correct slot group |

4. Check tags, wishlist membership, existing source/slot metadata, group collapse,
   tooltip comparison, and tracker alignment remain unchanged. When multiple
   versions of one item are owned, verify the highest-item-level link is used.
5. Open the Adventure Guide tag popover, then attempt to delete a tag that is an
   item's sole tag. Check the confirmation's names, icons, colors, and tooltips;
   **cancel** deletion so the wishlist remains unchanged.
6. In this development checkout, run `/testalert`, hover the item, and check its
   name, icon, color, effective-variant tooltip/comparison, and OK/Escape dismissal.
   Run `/testroll` and `/testroll epic` to check roll icon/name/color and the
   wishlist badge. These commands are development-only and are not packaged.
   A real other-player loot alert is needed to validate a real dropped
   variant end-to-end; `/testalert` supplies a synthetic event record.
7. Record any script errors or taint symptoms. Missing data immediately after
   login is distinct from the confirmed missing-global defect; asynchronous
   item-data recovery is not added by this change.
