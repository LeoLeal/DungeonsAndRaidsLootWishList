## 1. Tracker sidecar foundation

- [x] 1.1 Read the current `TrackerUI.lua` end-to-end and inventory every user-facing behavior that must be preserved in the refactor, including shift-click removal, source-group collapse, collapsed counts, source-header navigation, raid boss subheaders, row styling, and tooltip behavior
- [x] 1.2 Create an addon-owned tracker container in `TrackerUI.lua` that is no longer registered through `ObjectiveTrackerFrame:AddModule`
- [x] 1.3 Define the sidecar frame's header, content container, and row/block pools using addon-owned frames only

## 2. Tracker-area positioning and collapse integration

- [x] 2.1 Implement tracker-area anchoring so the wishlist section appears immediately beneath the last visible native Objective Tracker section with no unintended blank gap
- [x] 2.2 Implement fallback positioning so the wishlist appears at the tracker area's normal top position when it is the only visible tracker-area content
- [x] 2.3 Mirror native Objective Tracker collapse state so collapsing all objectives also hides the wishlist section and expanding restores it
- [x] 2.4 Remove the existing native Objective Tracker module registration and any code that depends on Blizzard-owned module/block/line lifecycle

## 3. Tracker content rendering and preserved interactions

- [x] 3.1 Port source-group rendering from Blizzard-owned tracker blocks to addon-owned group header frames
- [x] 3.2 Port item-row rendering to addon-owned row frames while preserving `TrackerRowStyle.lua` offsets, tick atlas, and quality-color behavior
- [x] 3.3 Preserve shift-click removal from tracker rows using addon-owned row handlers
- [x] 3.4 Preserve source-group collapse and expand behavior, including item counts while collapsed
- [x] 3.5 Preserve raid boss subheadings and boss-order grouping behavior in the addon-owned tracker surface
- [x] 3.6 Preserve source-group header click behavior so valid dungeon and raid groups open the Adventure Guide in loot context while collapse-button clicks remain separate

## 4. Tracker tooltip isolation

- [x] 4.1 Create a tracker-dedicated private tooltip using `GameTooltipTemplate` for addon-owned wishlist rows
- [x] 4.2 Update tracker hover behavior to use only the private tooltip with Blizzard-native item content and no addon-specific lines
- [x] 4.3 Verify the private tooltip anchor matches the spec requirement: top-right aligned to row top-left with a 4px horizontal gap
- [x] 4.4 Remove tracker hover dependence on the shared global `GameTooltip` for wishlist row rendering

## 5. Encounter Journal integration hardening

- [x] 5.1 Replace `EnumerateFrames()`-based loot-button discovery in `AdventureGuideUI.lua` with a narrower loot-surface adapter scoped to visible Encounter Journal loot rows
- [x] 5.2 Move Adventure Guide wishlist-toggle state out of Blizzard loot-button fields into addon-owned state or an external lookup keyed by visible row identity
- [x] 5.3 Preserve the current Adventure Guide checkbox UX for dungeon and raid loot rows while avoiding broad frame scanning
- [x] 5.4 Keep explicit user-triggered Adventure Guide navigation behavior while removing passive Encounter Journal mutation from tracker-render paths

## 6. Loot alert data sanitization and safe dialog display

- [x] 6.1 Refactor `LootEvents.lua` so loot-event handlers parse incoming event data immediately and queue only normalized addon-owned alert records
- [x] 6.2 Refactor loot alert display so the dialog is built from normalized alert records rather than raw deferred chat-event payloads
- [x] 6.3 Preserve the current loot alert dialog appearance, item presentation, and dismissal behavior when shown immediately or after a safe-state deferral
- [x] 6.4 Replace or wrap the current popup path if needed so deferred alert display no longer taints Blizzard popup or tooltip flows

## 7. Encounter and source metadata cleanup

- [x] 7.1 Identify tracker refresh paths that currently call `EJ_SelectInstance`, `EJ_SelectEncounter`, or other Encounter Journal selection-mutating APIs during passive rendering
- [x] 7.2 Move passive source-enrichment and encounter-order work behind a cache or explicit resolver boundary so tracker refresh does not mutate live Encounter Journal selection state
- [x] 7.3 Leave bounded explicit navigation flows intact where the user intentionally opens the Adventure Guide from wishlist UI

## 8. Verification and taint validation

- [x] 8.1 Enable taint logging and reproduce the prior tracker, tooltip, Encounter Journal, and loot-alert scenarios
- [x] 8.2 Verify the wishlist tracker remains visible in the tracker area with and without native tracker content, with no unintended blank gap beneath native sections
- [x] 8.3 Verify collapsing all objectives hides the wishlist section and expanding restores it
- [x] 8.4 Verify tracker row hover shows the expected item tooltip and does not break later Blizzard-owned tooltips such as Encounter Journal loot tooltips
- [x] 8.5 Verify shift-click removal, source-group collapse/expand, collapsed counts, raid boss subheaders, and source-header Adventure Guide navigation still work
- [x] 8.6 Verify Adventure Guide wishlist toggles still work on visible dungeon and raid loot rows without introducing taint errors
- [x] 8.7 Verify tracked-item alert dialogs still appear correctly for other-player loot, including safe-state deferral behavior
