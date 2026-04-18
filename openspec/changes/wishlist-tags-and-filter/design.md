## Context

The addon currently models wishlist membership as a boolean-like tracked state keyed by stable item identity. Adventure Guide loot rows expose that state through a checkbox-owned surface, tracker rendering assumes that every persisted item is visible unless hidden by grouping or collapse state, and LootAwareness surfaces only need to know whether an item is tracked.

This change introduces a cross-cutting data-model shift: an item is now considered tracked when it has one or more assigned tags. That affects multiple module boundaries at once:

- `DataStore/WishlistStore.lua` and `DataStore/WishlistMigration.lua` own persisted membership and migration rules.
- `AdventureGuide/*` owns Encounter Journal row integration and the item-facing tag management popover.
- `Tracker/*` owns header controls, filter presentation, render-data shaping, and tracker tooltip footers.
- `LootAwareness/*` owns loot roll badge and alert presentation but must remain independent from tracker-local filter state.
- `Core/Bootstrap.lua` currently exposes boolean-oriented helpers such as `SetTrackedFromItemData`, `RemoveTrackedItem`, and `IsTrackedItem`, so the change must avoid turning bootstrap into the owner of tag semantics.

The design must preserve the architectural rules already established in the repository:

- keep persistence and invariants in DataStore
- keep Encounter Journal widget logic in AdventureGuide
- keep tracker-specific presentation and filtering in Tracker
- keep loot-event reactions in LootAwareness
- keep bootstrap orchestration thin

## Goals / Non-Goals

**Goals:**
- Replace boolean wishlist membership with tag-based membership while preserving stable item identity.
- Keep tags as plain user-authored text labels stored per character.
- Seed one default localized tag once and migrate existing tracked items onto it.
- Add a live-apply Adventure Guide popover for assigning, creating, and deleting tags without moving feature ownership into DataStore or Bootstrap.
- Add tracker-local tag filtering that is presentation-only and cannot affect tracked membership, loot alerts, or loot roll badges.
- Extend tag presentation consistently across tracker tooltips, loot roll badges, and alert copy.
- Preserve existing refresh and grouping flows with minimal cross-feature bleed.

**Non-Goals:**
- Renaming tags in this change.
- Sharing tags across characters.
- Making tracker filter state authoritative for any non-tracker feature.
- Replacing existing source grouping, possession scanning, or loot matching behavior.
- Translating previously stored tag text after the user changes game locale.

## Decisions

### 1. Persist tags as plain text labels with normalized comparison helpers

**Decision**

Persist the tag catalog and item assignments using plain tag labels rather than tag identifiers. DataStore will treat the stored text as the source of truth while also using a normalization rule for comparisons: trimmed, case-insensitive label matching.

Suggested persisted shape per character:

- ordered `tags` list containing the display labels
- per-item `tags` collection containing assigned labels
- existing tracked item metadata remains on the item entry

Tracked membership becomes derived:

- item has one or more assigned tags -> tracked
- item has zero assigned tags -> remove the wishlist entry entirely

**Rationale**

The user explicitly wants tags to be text, not identifiers. The default `Best in slot` tag is only a one-time localized seed; after creation, tag text behaves like user-authored data and should not be rewritten if the locale changes.

**Alternatives considered**

- **Stable tag IDs plus localized display labels**: more robust for renaming and locale transitions, but rejected because the desired behavior is to store the visible text directly.
- **Embed tag labels only on items without a catalog**: rejected because the addon still needs a persistent ordered tag list, minimum-one-tag invariant, and tracker filter choices even when some tags are temporarily unused.

### 2. Keep tag invariants entirely DataStore-owned

**Decision**

DataStore will own all tag lifecycle invariants and helper operations:

- ensure at least one tag exists
- seed the initial default tag for new or migrated characters
- enforce case-insensitive uniqueness
- assign and unassign tags on items
- remove items whose last tag is removed
- delete a tag from the catalog and from every item that uses it
- calculate which items would be untracked by deleting a tag
- prune tracker filter selections that reference deleted or unused tags

AdventureGuide, Tracker, and LootAwareness should call intent-level helpers rather than manipulating persistence tables directly.

**Rationale**

The tag rules are data invariants, not UI rules. Centralizing them in DataStore prevents Journal UI, tracker UI, and loot surfaces from each inventing their own edge-case behavior.

**Alternatives considered**

- **AdventureGuide owns assignment semantics because the primary editor lives there**: rejected because tracker tooltips, loot alerts, and migration also depend on the same invariants.
- **Bootstrap owns tag operations behind namespace functions only**: rejected because bootstrap should orchestrate refresh, not become the domain owner of tag semantics.

### 3. Introduce a tag-domain helper layer instead of inflating existing boolean entry points

**Decision**

Keep existing namespace convenience entry points thin, but move new tag semantics behind narrow DataStore/tag helper APIs. Existing boolean-oriented helpers such as `SetTrackedFromItemData` and `RemoveTrackedItem` should either delegate to the new tag operations or remain compatibility wrappers for surfaces that still perform direct remove actions.

The important domain operations are:

- get catalog tags in display order
- get assigned tags for an item in display order
- assign tag to item
- unassign tag from item
- create tag
- validate uniqueness
- delete tag with impact preview
- get used tags across tracked items

**Rationale**

This change is larger than a simple `tracked/untracked` toggle. A tag-focused helper seam keeps Bootstrap small and prevents Tracker or AdventureGuide from owning persistence details.

**Alternatives considered**

- **Expand `SetTrackedFromItemData(item, true/false)` to accept optional tags**: rejected because it keeps a boolean mental model at the API boundary and makes call sites ambiguous.
- **Let every feature read and mutate `WishlistStore` tables directly**: rejected because it would spread deletion, uniqueness, and migration rules across modules.

### 4. Keep Adventure Guide as a live-apply item editor

**Decision**

Replace the checkbox presentation in Adventure Guide with a favorite icon that reflects whether the item currently has at least one tag. Clicking the icon opens a small addon-owned popover near the cursor using a parchment-friendly nineslice. The popover is live apply:

- checking a tag assigns it immediately
- unchecking a tag unassigns it immediately
- creating a tag adds it immediately to the catalog only
- deleting a tag deletes it immediately after any required confirmation
- top-right close icon dismisses only
- clicking outside dismisses only

The popover should size to its content rather than reserving a large fixed panel.

**Rationale**

The user explicitly wants an editing popover, not a draft form. Live apply keeps the UI small and avoids a second confirmation layer for ordinary assignment changes.

**Alternatives considered**

- **Draft selection with Save/Cancel**: rejected because the requested interaction model is live apply with dismiss-only close behavior.
- **Reuse Blizzard dropdown/context menu systems**: rejected because the existing tracker context menu already demonstrates the addon's preference for isolated addon-owned popup surfaces.

### 5. Use a dedicated confirmation dialog for destructive tag deletion

**Decision**

When deleting a tag would leave one or more items with zero tags, AdventureGuide will present an addon-owned confirmation dialog listing those items and using the requested confirmation copy. The confirmation surface should remain specific to tag deletion rather than reusing loot alert presentation.

If deleting a tag would not untrack any item, deletion can proceed immediately.

**Rationale**

The confirmation is part of tag-management semantics, not loot-awareness. Reusing the loot alert dialog would create feature bleed and make the alert surface responsible for unrelated confirmation behavior.

**Alternatives considered**

- **Always show confirmation for any tag delete**: simpler, but rejected because the user only asked for confirmation when wishlist membership would be affected.
- **Reuse `LootAwareness/Alerts/LootAlertDialog.lua`**: rejected because it couples an unrelated alert feature to Adventure Guide tag management.

### 6. Make tracker filtering presentation-only and self-healing

**Decision**

Tracker will own a filter button positioned between attach/detach and grouping controls. The filter menu will only offer tags currently used by at least one tracked item. Selected tags use OR semantics. No selection means show all items.

Tracker filter state is tracker-local presentation state. It must not change persisted membership, loot matching, alert triggers, or badge presence. Whenever tags are deleted or become unused, the filter selection must be pruned automatically against the current used-tag set. If pruning removes every selected tag, the result is an empty selection which shows all items.

**Rationale**

This satisfies the user's requirement that zero-match dead states should not persist and that tracker filtering must never leak into non-tracker features.

**Alternatives considered**

- **Persist filter selections in DataStore immediately**: possible future enhancement, but rejected for now because filter state is presentation-only and does not need to survive reloads to satisfy the change.
- **Offer all catalog tags in the filter menu, including unused tags**: rejected because the user wants only currently used tags to appear.

### 7. Filter after loading tracked items but before grouping/rendering

**Decision**

Tracker render data should continue to start from the full tracked item list from DataStore. Tag filtering should then be applied in Tracker-owned render-data shaping before grouping is computed. Grouping, collapse behavior, and tooltip data should operate on the filtered subset.

Each tracker render item should carry ordered assigned tags so the tracker can:

- evaluate filter matches
- build the tooltip tags footer line
- expose tag text for row-owned surfaces without re-querying storage repeatedly

**Rationale**

This preserves the existing source/slot grouping flow and keeps filtering as a tracker concern rather than teaching DataStore a tracker-specific visibility concept.

**Alternatives considered**

- **Filter in DataStore when returning tracked items**: rejected because it would leak tracker presentation concerns into the persistence layer.
- **Filter after grouping**: rejected because empty groups and group counts would become harder to reason about.

### 8. Upgrade tracker tooltips from a single footer string to ordered footer lines

**Decision**

Tracker tooltip rendering should move from a single optional footer string to ordered addon-owned footer lines. For this change:

- source-grouped mode appends one line: favorite atlas + comma-separated tags
- slot-grouped mode appends two lines in order:
  1. favorite atlas + comma-separated tags
  2. existing source footer line

Comparison tooltips should remain unchanged; addon footer lines belong only on the primary tracker tooltip.

**Rationale**

The current tooltip contract cannot express both the new tags footer and the existing slot-mode source footer. Ordered footer lines keep the new requirement explicit and extensible without pushing formatting back into the tooltip module.

**Alternatives considered**

- **Concatenate both concepts into one long footer string**: rejected because it makes layout and future extension harder and obscures the required tags-above-source ordering.
- **Show tags only in slot mode**: rejected because the user explicitly wants source mode to show the tags line too.

### 9. Standardize tag text formatting across Tracker and LootAwareness

**Decision**

Use one shared formatting rule for ordered tags across surfaces:

- display tags in catalog order
- join with `, `
- prefix only when the surface requires it

Surface-specific output:

- tracker tooltip: favorite atlas + `tag1, tag2, tag3`
- loot roll badge: `Wishlist: tag1, tag2, tag3`
- loot alert message: `<player> looted an item on your Wishlist(tag1, tag2, tag3)!`

LootAwareness should read assigned tags from the tracked item entry or a shared formatter helper, never from tracker visibility state.

**Rationale**

Consistent ordering and formatting keeps the same item looking the same across addon surfaces and avoids Tracker becoming the source of truth for tag presentation.

**Alternatives considered**

- **Alphabetize tags per surface**: rejected because the catalog order is already meaningful and user-controlled.
- **Let each feature format tags independently**: rejected because punctuation and ordering would drift over time.

### 10. Perform one migration that seeds the initial tag and upgrades legacy tracked items

**Decision**

Migration will upgrade existing per-character wishlist data as follows:

1. ensure the tag catalog exists
2. create the initial localized `Best in slot` tag if the character has no tags yet
3. scan existing tracked items
4. assign the default tag to any item that predates tag assignments
5. normalize item entries so tag-based membership is authoritative

Migration must be idempotent so repeated login or repair paths do not duplicate the default tag or duplicate assignments.

**Rationale**

This preserves existing user intent while moving the storage model to the new invariant that tracked items always have at least one tag.

**Alternatives considered**

- **Lazy migration only when an item is edited in the Journal**: rejected because loot alerts, tracker rendering, and roll badges all need coherent tag assignments immediately.
- **Create the default tag only when the user first opens the popover**: rejected because existing tracked items need tags before any UI interaction.

## Risks / Trade-offs

- **[Risk] Tag text collisions caused by case-only differences or stray whitespace** -> **Mitigation:** normalize labels for validation and comparisons while preserving the user's chosen display casing.
- **[Risk] Live-apply unassignment can unexpectedly remove an item from the wishlist when its last tag is unchecked** -> **Mitigation:** make the favorite icon and popover state update immediately so the removal is visible, and keep the semantics explicit in specs and UI behavior.
- **[Risk] Tracker-local filter state can become stale after tag deletion or reassignment** -> **Mitigation:** prune selections against the used-tag set whenever tracker state rebuilds.
- **[Risk] Tooltip code that expects a single footer string could produce duplicated or misordered footer text** -> **Mitigation:** move to an ordered footer-lines contract and have the tooltip module render lines generically.
- **[Risk] Tag deletion confirmation can grow too large if many items are affected** -> **Mitigation:** keep the confirmation addon-owned and list only the item set relevant to the deleted tag, with the dialog sized for a concise scrollable list if needed.
- **[Risk] Cross-feature formatting drift between tracker, badge, and alert surfaces** -> **Mitigation:** centralize ordered tag-string formatting in shared logic and keep each feature responsible only for its own surrounding presentation.
- **[Risk] Overloading Bootstrap with tag logic during transition** -> **Mitigation:** add narrow delegation helpers only where needed and keep mutation rules in DataStore-owned helpers.

## Migration Plan

1. Extend DataStore migration to create the per-character tag catalog and seed the default localized tag when absent.
2. Upgrade legacy tracked items so each existing wishlist item receives the default tag.
3. Update DataStore read helpers so tag-based membership becomes the authoritative definition of tracked state.
4. Update Adventure Guide to use the favorite icon and live-apply popover instead of the checkbox toggle.
5. Update Tracker render data, filtering, header controls, and tooltip footer rendering to consume ordered tag data.
6. Update LootAwareness badge and alert presentation to include ordered tag text while keeping tracked-item matching unchanged.
7. Verify that deleting or unassigning tags prunes tracker filter state and never suppresses alerts or badges.

Rollback strategy:

- Before shipping, keep migration scoped and versioned so the addon can still ignore tag-specific UI if needed while preserving old item metadata.
- After shipping, rolling back code without a reverse migration would strand tag-based entries in a shape older code does not understand, so the practical rollback path is to ship a compatibility migration or forward fix rather than revert to pre-tag code blindly.

## Open Questions

- Which exact Blizzard nineslice layout should be used for the Adventure Guide popover to best match the parchment journal background while remaining compact?
- Should the tag-deletion confirmation dialog use a simple fixed-height list or a scrollable list from the start for long affected-item sets?
