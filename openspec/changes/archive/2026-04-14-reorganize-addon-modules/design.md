## Context

The addon currently ships as a flat set of Lua modules loaded from the root `.toc`, with responsibilities spread across files that mix bootstrap, feature logic, shared helpers, and runtime orchestration. This is most visible in `LootWishList.lua`, which currently acts as entry point, event router, tracker-state builder, alert coordinator, and utility host.

The proposal for `reorganize-addon-modules` introduces a vertical feature organization so that each major capability owns the files required to make that capability work. The agreed target structure is:

```text
Core/
  Bootstrap.lua
  Shared/
    ItemResolver.lua
    TooltipCompare.lua
    Locales.lua

DataStore/
  WishlistStore.lua
  WishlistMigration.lua
  TrackerPreferences.lua

AdventureGuide/
  Feature.lua
  JournalHooks.lua
  LootRowScanner.lua
  LootRowItemData.lua
  WishlistCheckboxes.lua
  MetadataCapture.lua

Tracker/
  Feature.lua
  TrackerFrame.lua
  TrackerAnchoring.lua
  TrackerHeaders.lua
  TrackerRows.lua
  TrackerTooltip.lua
  TrackerContextMenu.lua
  TrackerGroups.lua
  RaidBossOrdering.lua
  PossessionScanner.lua
  TrackerRowStyle.lua

LootAwareness/
  Feature.lua
  ChatLootParser.lua
  LootMatcher.lua
  RecentSelfLoot.lua
  LootEventHandlers.lua
  Alerts/
    AlertQueue.lua
    AlertPresenter.lua
    LootAlertDialog.lua
  RollBadge/
    RollFrameLocator.lua
    RollBadgeView.lua
```

The design must preserve current behavior wherever possible, respect WoW add-on load-order constraints from the `.toc`, and avoid collapsing back into a large `Core` directory that becomes a new dumping ground.

## Goals / Non-Goals

**Goals:**
- Reorganize the addon around feature ownership instead of horizontal technical layers.
- Shrink `Core` to bootstrap plus addon-wide shared primitives only.
- Keep persistence concerns in `DataStore` instead of mixing them into feature folders.
- Make `AdventureGuide`, `Tracker`, and `LootAwareness` the primary vertical slices.
- Move alert dialog and loot roll badge behavior under `LootAwareness` so loot reactions are owned by one feature.
- Define clean feature entrypoints through `Feature.lua` files so cross-feature access does not depend on internal file knowledge.
- Preserve current user-facing behavior, tracker presentation contracts, and saved-variable compatibility unless a small compatibility adjustment is strictly required by the refactor.

**Non-Goals:**
- Introducing new wishlist functionality or changing feature scope.
- Redesigning the tracker UI or changing Blizzard integration patterns.
- Replacing the current saved-variable model with a new schema.
- Eliminating all shared code in favor of fully isolated features.
- Rewriting stable pure helpers solely for style reasons.

## Decisions

### 1. Use vertical feature folders with explicit feature entrypoints

The addon will be organized around `AdventureGuide`, `Tracker`, and `LootAwareness`, each with a `Feature.lua` public entrypoint. Internal files remain private to the feature unless explicitly surfaced through that entrypoint.

**Rationale:**
- Keeps ownership obvious: the feature folder contains what that feature needs.
- Reduces direct cross-feature coupling through arbitrary namespace lookups.
- Matches the way the addon is discussed by users and maintainers.

**Alternatives considered:**
- **Keep a flat root layout:** rejected because it preserves the current ownership ambiguity.
- **Use technical folders such as `UI`, `Models`, `Services`:** rejected because the user explicitly wants vertical slices, and technical layering would continue to spread single features across multiple directories.

### 2. Keep `Core` intentionally small and place shared primitives under `Core/Shared`

`Core` will contain `Bootstrap.lua` and a `Shared/` subfolder for addon-wide primitives used by multiple features. Initial `Core/Shared` modules are `ItemResolver.lua`, `TooltipCompare.lua`, and `Locales.lua`.

**Rationale:**
- `Core` remains meaningful as addon foundation rather than a miscellaneous bucket.
- Shared primitives remain easy to discover and clearly separate from feature-owned logic.
- The chosen modules are genuinely cross-feature and are not naturally owned by a single feature.

**Alternatives considered:**
- **Separate top-level `Shared/` directory:** acceptable, but rejected because the team explicitly prefers shared primitives to live under `Core` as addon-wide foundational parts.
- **Move shared helpers into one feature:** rejected because it would create artificial ownership and hidden dependencies.

### 3. Keep persistence in a dedicated `DataStore` area

Saved-variable access, migration, normalization, and tracker preference persistence will live under `DataStore` rather than being folded into feature directories.

**Rationale:**
- Persistence supports multiple features and is not itself a player-facing capability.
- A dedicated persistence area makes schema evolution and migration easier to reason about.
- It prevents features from each inventing their own storage conventions.

**Alternatives considered:**
- **Embed persistence inside each feature:** rejected because the current saved-variable model is shared across tracker, Adventure Guide, and loot-awareness behavior.
- **Leave all persistence in a single monolithic `WishlistStore.lua`:** partially acceptable as an intermediate step, but rejected as the target because migration and preference ownership should be clearer.

### 4. Treat `LootAwareness` as the full loot-reaction feature

`LootAwareness` will own loot-event parsing, wishlist matching, self-loot suppression, alert queue/presentation, and loot roll badge behavior. Alert-specific files will live under `LootAwareness/Alerts`, and loot roll decoration files will live under `LootAwareness/RollBadge`.

**Rationale:**
- The dialog and roll badge only exist because loot awareness detects relevant wishlist events.
- Grouping all loot reactions under one feature better reflects actual runtime flow.
- This avoids splitting one conceptual feature across multiple sibling folders.

**Alternatives considered:**
- **Separate `LootDialog` and `LootRollBadge` top-level features:** rejected because both are reaction surfaces owned by loot-awareness logic.
- **Keep alert queue/orchestration in `Core`:** rejected because it would pull feature-specific runtime behavior back into the foundation layer.

### 5. Treat tracker-derived computation as tracker-owned behavior

`Tracker` will own not only tracker frame rendering, but also tracker grouping, raid boss ordering, possession scanning, row styling, tooltip behavior, and tracker-specific presentation helpers.

**Rationale:**
- Those computations only exist to support tracker presentation and interaction.
- This keeps the tracker feature self-contained and reduces logic hidden in bootstrap code.
- It preserves testable seams by allowing pure tracker transformations to remain in tracker-owned modules.

**Alternatives considered:**
- **Leave grouping and ordering helpers outside the tracker feature:** rejected because it weakens feature ownership and makes tracker behavior harder to trace.

### 6. Move Adventure Guide metadata capture into the Adventure Guide feature

Anything derived from Encounter Journal row structure, visible loot-row state, or journal-facing metadata capture belongs to `AdventureGuide`, even if the resulting data is later persisted through `DataStore`.

**Rationale:**
- Encounter Journal widget knowledge is feature-specific, not persistence-specific.
- It keeps `DataStore` free from direct Blizzard UI crawling responsibilities.
- It aligns ownership with the source of truth for that metadata.

**Alternatives considered:**
- **Keep Encounter Journal scanning inside `WishlistStore`:** rejected because it mixes persistence with live Blizzard integration.

### 7. Preserve behavior through staged migration rather than a single rewrite

The refactor will proceed in stages: establish folders and load order, extract files by feature ownership, then tighten boundaries and internal naming. Each stage should keep the addon behaviorally stable.

**Rationale:**
- Reduces risk in a codebase with WoW runtime constraints and UI-sensitive behavior.
- Makes regressions easier to localize.
- Aligns with the repository guidance to keep changes small and reversible.

**Alternatives considered:**
- **Big-bang rewrite into the final structure:** rejected due to high regression risk and poor debuggability.

### 8. Keep persistence and preference concerns as separate `DataStore` files

`WishlistMigration.lua` and `TrackerPreferences.lua` will be real standalone files in the refactor rather than remaining as internal sections of `WishlistStore.lua`.

**Rationale:**
- Makes persistence responsibilities visible at the file-system level.
- Prevents `WishlistStore.lua` from remaining a hidden monolith after the folder move.
- Aligns the refactor with the goal of ownership clarity, not just path changes.

**Alternatives considered:**
- **Keep migration and tracker preferences inside `WishlistStore.lua` for the first pass:** rejected because it preserves too much structural ambiguity in a change whose main goal is clearer responsibility boundaries.

### 9. Structure `LootAwareness` with internal `Alerts/` and `RollBadge/` groupings

`LootAwareness` will keep event detection and matching logic at the feature root, while alert presentation and roll-badge presentation will live in dedicated internal subfolders.

**Rationale:**
- Preserves `LootAwareness` as one vertical feature while acknowledging two distinct outward reaction surfaces.
- Keeps feature internals easier to navigate as the extraction proceeds.
- Avoids promoting alert and roll-badge behavior into separate top-level features.

**Alternatives considered:**
- **Keep `LootAwareness` completely flat:** rejected because the feature already has two different presentation tracks that benefit from internal grouping.

### 10. Remove the obsolete local test suite during the refactor

The existing local Node + Wasmoon tests will be removed as part of this refactor instead of being carried forward. They are not providing useful verification for the current addon behavior, and keeping stale tests aligned with the new folder structure would add maintenance cost without enough value.

**Rationale:**
- Avoids spending refactor effort on test assets that are intentionally being retired.
- Keeps the structural change focused on code ownership and runtime wiring rather than rebuilding a low-value test harness.
- Matches the current repository direction where no local automated test suite is being maintained.

**Alternatives considered:**
- **Refactor the existing tests to match the new module boundaries:** rejected because the current tests are intentionally being removed rather than modernized.

## Risks / Trade-offs

- **[Risk] Load-order regressions from moved files** → Mitigation: explicitly redesign `.toc` order so shared primitives load first, persistence loads before features that consume it, and `Core/Bootstrap.lua` loads last.
- **[Risk] Folder moves without real responsibility cleanup** → Mitigation: move logic according to ownership, not just filenames; use `Feature.lua` entrypoints to prevent old implicit dependencies from remaining hidden.
- **[Risk] `Core` regrows into a dumping ground** → Mitigation: define `Core` as bootstrap plus `Core/Shared` only; feature-specific runtime behavior must stay in feature folders.
- **[Risk] `DataStore` retains Blizzard UI responsibilities** → Mitigation: extract Encounter Journal metadata capture into `AdventureGuide` and keep `DataStore` focused on reads, writes, preferences, and migrations.
- **[Risk] Cross-feature coupling remains through namespace internals** → Mitigation: expose only minimal public feature APIs and treat internal files as private implementation details.
- **[Risk] Refactor changes user-visible behavior unintentionally** → Mitigation: preserve existing specs and user-facing behavior, and treat any necessary behavior difference as a bug to resolve during the refactor rather than a design goal.

## Migration Plan

1. Create the target folder layout and identify the final `.toc` load-order groups.
2. Move existing shared primitives into `Core/Shared` without changing behavior.
3. Extract `DataStore` responsibilities from the current monolithic store into focused persistence modules while preserving the existing saved-variable model.
4. Split `AdventureGuideUI.lua` into `AdventureGuide` modules around hooks, row discovery, item-data capture, and checkbox behavior.
5. Split tracker-owned code into `Tracker` modules, including tracker grouping and possession scanning currently hosted elsewhere.
6. Move loot event handling, recent-self-loot state, alerts, and roll badge logic into `LootAwareness` and its internal subfolders.
7. Reduce `LootWishList.lua` to `Core/Bootstrap.lua`, leaving only addon bootstrap and top-level wiring.
8. Update `.toc` to the new file paths and verify the addon loads in the intended order.
9. Remove the obsolete local test files and related package assets so the repository state matches the intentional no-tests direction.

Rollback strategy: because the refactor is structural and staged, rollback can occur by restoring the previous file layout and `.toc` ordering if a stage introduces regressions that cannot be isolated quickly.

## Open Questions

- None at this time.
