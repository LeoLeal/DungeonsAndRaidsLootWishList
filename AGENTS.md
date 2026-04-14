# Loot WishList

Loot WishList is a World of Warcraft addon that lets players track dungeon and raid loot from the Adventure Guide, surface tracked items in the Objective Tracker, react to loot events, and persist wishlist state per character.

This file is for both AI agents and human contributors. It describes the addon's architecture and the coding practices expected in this repository.

## Architecture

### System overview

The addon is organized around a folder-based module layout:

- `Core/Bootstrap.lua` - addon entry point, event registration, refresh orchestration, and top-level namespace wiring
- `Core/Shared/ItemResolver.lua` - stable item identity resolution across links, item IDs, and scaled variants
- `Core/Shared/TooltipCompare.lua` - shared tooltip comparison handling used by tracker and alert surfaces
- `Core/Shared/Locales.lua` - all user-facing string lookup
- `DataStore/WishlistStore.lua` - character-scoped saved-variable access and mutation
- `DataStore/WishlistMigration.lua` - persistence normalization and saved-variable migration helpers
- `DataStore/TrackerPreferences.lua` - persisted tracker grouping and collapse preferences
- `AdventureGuide/Feature.lua` - public Adventure Guide feature entrypoint
- `AdventureGuide/*` - Encounter Journal hooks, loot-row scanning, item-data extraction, metadata capture, and checkbox presentation
- `Tracker/Feature.lua` - public tracker feature entrypoint
- `Tracker/*` - tracker grouping, possession scanning, row styling, frame rendering, tooltip handling, and context menu behavior
- `LootAwareness/Feature.lua` - public loot-awareness feature entrypoint
- `LootAwareness/*` - loot event parsing, tracked-item matching, recent-self-loot handling, alert presentation, and roll badge behavior

### Data flow

The intended runtime flow is:

1. Adventure Guide loot rows expose a wishlist toggle.
2. Toggling updates character-specific saved variables through `DataStore/WishlistStore.lua`.
3. `Core/Bootstrap.lua` rebuilds tracker state by combining:
   - tracked items from saved variables
   - current possession state from bags / equipment / bank when known
   - source grouping from stored metadata and tracker grouping helpers
4. `Tracker/TrackerGroups.lua` produces grouped row data.
5. `Tracker/Feature.lua` renders the `Loot Wishlist` section in the Objective Tracker.
6. `LootAwareness/Feature.lua` updates or decorates UI in response to loot-related events.

### State model

Saved variables are per-character and should stay minimal.

Tracked item state is expected to capture:

- stable item identity
- tracked / untracked membership
- best looted item level when known
- lightweight metadata needed to rebuild tracker display, such as source label or item name if already known

Do not persist derived presentation state such as:

- whether a row is currently visible
- whether the tracker section is expanded or collapsed, unless explicitly designed
- whether the item is currently possessed, since that should be recomputed from game state

## Architectural rules

### Keep pure logic separate from WoW frame code

Prefer putting deterministic logic in pure modules:

- identity resolution in `Core/Shared/ItemResolver.lua`
- grouping in `Tracker/TrackerGroups.lua`
- row presentation constants in `Tracker/TrackerRowStyle.lua`

Keep Blizzard frame manipulation, event hooks, and layout behavior in UI-facing modules only.

### Prefer Blizzard-native UI patterns

When presenting tracker sections, rows, headers, checkmarks, and animations:

- reuse Blizzard templates, atlases, fonts, and interaction patterns where practical
- prefer the native Objective Tracker header / row behavior over bespoke art or custom widget language
- only introduce custom presentation when Blizzard assets cannot express the required behavior

### Stable item identity is more important than displayed item level

Adventure Guide rows often represent a baseline version of an item while actual drops can scale.

The addon should treat all item-level variants of the same underlying item as one wishlist target. Do not key tracking state off displayed item level text.

### Tracker grouping is source-first

Tracked items should group by loot source when known and fall back to `Other` only when a source cannot be resolved.

If a bug appears where items unexpectedly fall into `Other`, debug source resolution before changing tracker rendering.

### Objective Tracker behavior should be additive

The wishlist section should behave like a native tracker section without breaking or reflowing Blizzard-owned sections.

When adjusting tracker layout:

- prefer anchoring and spacing that follow Blizzard module geometry
- avoid hard-coded screen-space conversions when a parent-relative anchor is available
- treat alignment and stacking regressions as architecture issues, not just cosmetic issues

## Coding practices

### File ownership and responsibilities

When changing behavior, edit the narrowest responsible file first.

- persistence bugs -> `DataStore/WishlistStore.lua`, `DataStore/WishlistMigration.lua`, or `DataStore/TrackerPreferences.lua`
- item matching bugs -> `Core/Shared/ItemResolver.lua`
- source grouping / tracker grouping bugs -> `Tracker/TrackerGroups.lua`
- spacing / atlas / row visual bugs -> `Tracker/TrackerRowStyle.lua` or `Tracker/TrackerRows.lua`
- Objective Tracker layout / frame bugs -> `Tracker/Feature.lua`, `Tracker/TrackerFrame.lua`, or `Tracker/TrackerAnchoring.lua`
- Encounter Journal checkbox bugs -> `AdventureGuide/WishlistCheckboxes.lua`
- Adventure Guide row scanning / metadata bugs -> `AdventureGuide/LootRowScanner.lua`, `AdventureGuide/LootRowItemData.lua`, or `AdventureGuide/MetadataCapture.lua`
- loot chat / loot-roll behavior bugs -> `LootAwareness/LootEventHandlers.lua`, `LootAwareness/ChatLootParser.lua`, or `LootAwareness/LootMatcher.lua`
- alert dialog / queue bugs -> `LootAwareness/Alerts/*`
- orchestration or refresh sequencing bugs -> `Core/Bootstrap.lua`

Avoid placing unrelated logic into `Core/Bootstrap.lua` just because it is the entry point.

### Localization-first strings

All user-facing strings must come from `Core/Shared/Locales.lua`.

Do not introduce hard-coded UI text in runtime modules unless it is temporary debugging code that will be removed before completion.

### Minimize hidden coupling

Do not rely on implicit globals or cross-file state when a dependency can be passed explicitly.

In particular:

- pass addon namespace state deliberately into helper functions that need it
- avoid reading visual constants directly from unrelated modules when a local helper or explicit reference is clearer
- keep row-style constants centralized instead of scattering offsets and texture choices across multiple files

### Preserve testable seams

If a behavior can be expressed as pure data transformation, keep it outside WoW-only frame APIs so it remains easy to verify with local tests when test coverage is added or restored.

Good candidates for tests:

- stable item key generation
- source fallback behavior
- grouped tracker row formatting
- row-style contracts such as check atlas and padding

Poor candidates for local tests:

- exact Blizzard frame hierarchy assumptions
- live Encounter Journal widget names that only exist in the game client
- runtime animation appearance

### Debugging approach

When a UI bug appears:

1. identify whether it is a data bug, a layout bug, or a Blizzard integration bug
2. trace which module owns that responsibility
3. fix the root cause in that module instead of layering compensating offsets elsewhere

Do not patch tracker alignment issues by stacking more offsets on top of uncertain anchors.

### Keep changes small and reversible

When modifying UI presentation:

- prefer changing a constant or a narrowly scoped helper before refactoring a whole module
- separate style fixes from behavior fixes when possible
- avoid bundling unrelated cleanups with bug fixes

## Working expectations for agents and contributors

### Before changing code

- read the relevant module end-to-end
- identify whether the issue belongs to data, model, UI, or event handling
- if tests exist for the affected pure logic, update or add a failing test first

### When adding new behavior

- preserve the module boundaries listed above
- update tests for pure logic changes
- keep Blizzard integration code defensive, since frame availability and widget structure can vary by client state

### When adjusting UI styling

- favor `Tracker/TrackerRowStyle.lua` for row-level constants
- favor Blizzard templates / atlases / fonts over custom assets
- verify that a visual tweak does not unintentionally break stacking, alignment, or visibility

### When unsure

- prefer a small, local change over a broad refactor
- prefer explicit data flow over implicit coupling
- prefer matching Blizzard's tracker patterns over inventing new ones

### When debugging and coding

- Refer to wow-addon-taint.md to understand taint and how to avoid it
- Refer to the Blizzard UI Source code at https://github.com/tomrus88/BlizzardInterfaceCode/tree/master/Interface/AddOns when needed
