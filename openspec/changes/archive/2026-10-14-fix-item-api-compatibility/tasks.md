# Tasks

## 1. Tracker name and rarity compatibility

- [x] 1.1 Add a lightweight local Lua regression harness covering absent legacy globals, successful namespaced name lookup, base-item name fallback, effective-variant quality, and genuinely unavailable data; verify the reported name/color cases fail against the current code and the harness requires no third-party libraries.
- [x] 1.2 Update `namespace.GetItemInfoName` in `Core/Bootstrap.lua` to defensively use `C_Item.GetItemInfo`; verify the name-helper and tracked-group regressions pass with global `GetItemInfo` absent and preserve variant-then-base lookup order.
- [x] 1.3 Update `Tracker/TrackerRows.lua` rarity lookup to use supported namespaced item data for the existing effective display reference; verify row doubles receive the expected name, variant-specific RGB color, default color for missing quality, unchanged possession indicator, and unchanged tooltip reference.
- [x] 1.4 Document the harness command and tracker manual-check matrix beside the tests; verify the documented command runs successfully and the matrix covers owned/unowned items, source/slot grouping, and attached/detached presentation.

## 2. Related item API compatibility review

- [x] 2.1 Audit the proposal's related files and development-only bootstrap commands against current Blizzard item API documentation; record the verified ID/link signatures and affected calls in the test documentation, distinguishing confirmed name-API failure from other compatibility exposures.
- [x] 2.2 Add focused checks and replace equivalent legacy name, link, icon, and quality-color calls in `AdventureGuide/WishlistTagPopover.lua` and `LootAwareness/Alerts/LootAlertDialog.lua`; verify namespaced-only stubs preserve selected/dropped-variant inputs and existing missing-data fallbacks.
- [x] 2.3 Add focused checks and replace equivalent legacy inventory-type and detailed-item-level calls in `Core/Shared/ItemResolver.lua`, `DataStore/WishlistMigration.lua`, and `Tracker/PossessionScanner.lua`; verify slot metadata resolution and highest-item-level owned-link selection while possession stays keyed by stable item identity.
- [x] 2.4 Update equivalent calls in development-only `/testroll` and `/testalert` code without redesigning the commands; verify Lua syntax and a scoped search show no remaining callable legacy item APIs covered by this change, and document any intentionally retained references.

## 3. Integration verification

- [x] 3.1 Run all focused regression checks and Lua syntax checks for changed files; verify successful results and inspect the diff for unintended saved-variable schema changes, layout changes, global aliases, or writes to Blizzard API tables.
- [x] 3.2 Validate the addon in the affected Retail client after reload without resetting or re-tracking wishlist items; record observed restored names/colors across the documented tracker matrix and unchanged tooltips, ticks, grouping, and tags, leaving this task pending if live-client access is unavailable.
- [x] 3.3 Smoke-test tag popovers and a development-triggered alert/roll in game; verify item names, icons, colors, dropped-variant tooltip selection, and dismissal behavior, recording actual observations separately from local stub results.

Live verification accepted from the user's confirmation: "test is done. Everything works."
This is user-reported in-game validation, not agent-observed testing; separate per-case logs were not supplied.
