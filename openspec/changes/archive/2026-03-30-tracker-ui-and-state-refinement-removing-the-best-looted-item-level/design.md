## Context

The tracker currently surfaces remembered `bestLootedItemLevel` and optional item-track text directly in the row label. That compact row suffix now conflicts with the cleaner interaction model the addon has grown into: the row itself should answer "what item is this and do I have it," while tooltip behavior should answer "what exactly is this item" and, when relevant, "how does it compare?"

At the same time, `bestLootedItemLevel` still exists in the saved-variable model and self-loot handling path. If the row no longer displays that history and the tooltip path already relies on real owned links or `selectedVariantRef`, then keeping best-looted item-level history adds state and logic without improving the user experience. The design therefore needs to simplify both the tracker presentation and the persisted model while preserving truthful tooltip behavior for owned and unowned items.

## Goals / Non-Goals

**Goals:**
- Remove best-looted item-level and item-track suffixes from tracker rows.
- Keep the green tick as the main tracker-row possession/completion signal.
- Suppress equipped comparison panes for possessed items while still showing the possessed tooltip.
- Preserve existing tooltip fidelity for unowned items through real `selectedVariantRef` and stable item fallback behavior.
- Remove `bestLootedItemLevel` from persisted wishlist entries and stop updating it on self-loot.
- Keep the current persistence version and remove obsolete `bestLootedItemLevel` fields through existing normalization / repair behavior rather than a version bump.

**Non-Goals:**
- Changing broad item tracking identity or selected-variant fallback semantics.
- Fabricating higher-item-level tooltip variants for unowned items.
- Changing tracker grouping, source footer behavior, or loot-alert dialog behavior beyond the removal of best-looted-item-level updates.
- Reworking bank/possession scanning semantics.

## Decisions

### 1. Simplify tracker rows to identity plus possession state only

Tracker item rows should no longer display remembered best-looted item level or item-track text in the row label. The row should show only the item name together with the existing possession tick behavior.

Rationale:
- The suffix mixed historical progress and variant information into a compact row surface that is better used for identity and completion state.
- The green tick already communicates the most useful at-a-glance state: whether the player currently has the item.
- Removing the suffix makes the tracker easier to scan and more Blizzard-native.

Alternatives considered:
- Keep a simplified suffix such as item level only: rejected because it still preserves the row-history hybrid that no longer fits the desired UX.
- Keep the suffix but move it to a second font string: rejected because it solves presentation mechanics but not the semantic problem.

### 2. Show compare panes only for unowned tracked items

Hovering a tracked row should continue to show the item's tooltip, but equipped comparison panes should only appear when the tracked item is not currently possessed. When the item is possessed, the player should see only the possessed tooltip for the best owned variant.

Rationale:
- Compare panes are most useful when the player is still evaluating an unowned target item.
- Once the player already has the item, the compare panes become less informative than simply showing the owned tooltip.
- This aligns the hover behavior with the tracker tick: possessed rows feel "completed" and do not ask the player to keep comparing that target.

Alternatives considered:
- Keep compare panes for all equippable rows: rejected because it preserves clutter for rows already marked complete by possession.
- Suppress tooltips entirely for possessed rows: rejected because the owned tooltip remains useful item-detail feedback.

### 3. Remove `bestLootedItemLevel` from persistence without changing the DB version

The addon should stop writing `bestLootedItemLevel`, stop updating it in self-loot handling, remove the obsolete helper functions that only read or update that field, and normalize loaded wishlist entries by removing the field when it is present. This cleanup should happen inside the current normalization / repair path rather than through a persistence-version bump.

Rationale:
- The field no longer has a clear user-facing role once the tracker row stops displaying it, so keeping helper APIs for it would preserve misleading dead surface area.
- Keeping the current persistence version avoids churn for what is effectively an obsolete-field cleanup.
- Existing repair/normalization behavior already provides a natural place to converge loaded entries to the new shape.

Alternatives considered:
- Keep the field in persistence for possible future use: rejected because it preserves complexity without an active UX need.
- Introduce a new persistence version solely to remove the field: rejected because current-version normalization is simpler and sufficient.

### 4. Keep tooltip variant fidelity based on real item references only

The change should continue to rely on real owned links, persisted `selectedVariantRef`, and stable item fallback for tooltip presentation. The addon should not fabricate higher-item-level tooltip variants for unowned items.

Rationale:
- Real item references preserve truthful tooltip behavior.
- Equipped-item comparisons should compare against actual target variants, not invented synthetic versions.
- Avoiding fabricated tooltip variants keeps the addon aligned with Blizzard-native item identity behavior.

Alternatives considered:
- Fabricate unowned tooltip variants at or above equipped item level: rejected because item level alone is not enough to safely construct a truthful item variant.

## Risks / Trade-offs

- [Players may miss the historical best-looted number after the suffix is removed] → Let the tracker focus on possession and tooltip detail; reevaluate only if real user feedback shows a strong need for history elsewhere.
- [Removing `bestLootedItemLevel` from persistence could leave stale fields on older saved entries] → Strip the field in current-version normalization/repair so mixed states converge automatically.
- [Suppressing compare panes for possessed items may hide useful upgrade context for players who own a weaker version] → Accept the simpler possession-first rule for now and revisit only if players strongly prefer upgrade-aware compare behavior.
- [Existing tests may over-assume remembered item-level behavior] → Update storage, loot-awareness, and tracker-display tests to align with the simplified model.

## Migration Plan

1. Remove tracker-row suffix generation from the model and UI paths.
2. Stop writing and updating `bestLootedItemLevel` in persistence and self-loot handling, and remove obsolete helper functions that served only that field.
3. Extend current normalization / repair behavior to remove `bestLootedItemLevel` from loaded entries without changing the persistence version.
4. Update tooltip compare logic to skip compare panes for possessed rows while preserving unowned compare behavior.
5. Update automated tests and manually validate tracker rows, owned vs unowned hover behavior, and normalized saved-variable cleanup.

Rollback plan:
- Revert the tracker-row simplification and compare suppression behavior, restore `bestLootedItemLevel` writes, and stop stripping the field during normalization. Because the persistence version is unchanged, rollback is straightforward as long as code once again tolerates missing `bestLootedItemLevel` fields.

## Open Questions

- None currently.
