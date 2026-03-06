## Context

`Loot WishList` is a new World of Warcraft addon with no existing implementation artifacts yet, so this change defines both the user-facing behavior and the first internal architecture for the addon. The feature crosses several WoW UI surfaces: Adventure Guide loot rows, the objective tracker, loot notifications, loot roll popups, and localization.

The core product constraint is that wishlist tracking must be character-specific, persist through saved variables, and treat Adventure Guide entries and higher item-level drops as the same tracked item. The tracker must communicate two different concepts at once: whether the user currently possesses any version of an item, and what the best item level they have looted so far is.

## Goals / Non-Goals

**Goals:**
- Provide a stable item-level-agnostic wishlist identity so one tracked entry covers Adventure Guide baseline items and higher-level drop variants.
- Keep the Adventure Guide interaction simple: checkbox checked means tracked, unchecked means not tracked.
- Render a `Loot Wishlist` section in the objective tracker that is readable during play, groups items by loot source, and supports direct removal via `Shift+Click`.
- Distinguish current possession from loot history by showing a green tick only for items currently found in bags, bank when known, or equipped, while preserving the highest looted item level in the tracker label.
- React to tracked-item loot events without creating noisy self-notifications: update state on player loot, alert only when another player loots a tracked item, and tag tracked items in loot roll frames.
- Centralize localized user-facing strings so every supported WoW locale can render the addon labels.
- Prefer Blizzard-provided UI widgets, textures, icons, and visual patterns wherever possible so the addon feels native to the game UI and minimizes custom art requirements.
- Reuse the native objective-tracker add-item animation behavior when a wishlist item is newly added to the tracker section.

**Non-Goals:**
- Account-wide or cross-character wishlist sharing.
- Automatic removal of items from the wishlist after they are looted.
- Tracking item quantities, duplicate targets, or multiple desired copies of the same item.
- Advanced loot history such as timestamps, encounter source history, or per-difficulty records.
- Synchronization with external services or other addons.

## Decisions

### 1. Use stable base item identity for wishlist entries

Wishlist entries should be keyed by the underlying item identity rather than the item level displayed in the Adventure Guide. This ensures that the checkbox state in the journal, loot-event matching, and tracker rendering all resolve to one row even when the player later sees or loots higher item-level versions.

Alternatives considered:
- Key by full item link or displayed item level: rejected because upgraded variants would create duplicate wishlist entries and break the player's mental model.
- Key by encounter/boss loot slot instead of item: rejected because the desired behavior is item-centric across multiple acquisition contexts.

### 2. Separate persisted loot memory from derived possession state

Saved variables should store only the tracked state and the best looted item level per item. The green tick should not be persisted as authoritative state; it should be derived by rescanning equipped items, bags, and bank contents when known. This allows the tracker to remove the tick when the player sells or destroys an item while still preserving the remembered best item level.

Alternatives considered:
- Persist an `owned` or `everObtained` flag: rejected because it would keep the tick visible after the player no longer possesses the item.
- Derive both ownership and best item level entirely from current inventory: rejected because the best looted item level would be lost once the item is removed.

### 3. Treat Adventure Guide UI as a thin toggle layer over the wishlist store

The checkbox in Adventure Guide loot rows should only reflect and update tracked membership. Loot ownership, best item level, and completion-like semantics must not change checkbox behavior. This keeps journal interaction predictable and avoids hidden state transitions caused by loot events.

Alternatives considered:
- Reusing the checkbox as a completion or upgrade toggle: rejected because it mixes tracking intent with current item ownership.

### 4. Build around a small set of cooperating runtime modules

The addon should be conceptually organized into:
- a wishlist store for saved-variable read/write and item-level memory,
- an item resolver that normalizes journal entries, loot events, and owned items to the same stable key,
- a source resolver that maps tracked items to dungeon/raid source groups with an `Other` fallback when no source is known,
- a tracker renderer for grouped objective-tracker output and `Shift+Click` removal,
- UI integrations for Adventure Guide checkboxes and loot roll tagging,
- an event coordinator that reacts to loot, bag, equipment, and bank changes.

This keeps UI concerns separate from persistence and allows possession recalculation to be shared across tracker refreshes and loot handling.

Grouping by source should be driven by item metadata rather than manually curated tracker state so that a tracked item naturally appears under its dungeon or raid heading whenever that source can be identified.

Alternatives considered:
- A single monolithic event script: rejected because the feature spans unrelated Blizzard UI surfaces and would become difficult to reason about.

### 5. Use best-effort bank awareness for current possession

The tracker should count bank items toward the green tick when the game has exposed bank state during the session. If bank contents are not currently known, possession falls back to equipped items and bags rather than inventing stale persisted bank ownership.

Alternatives considered:
- Requiring strict live bank accuracy before rendering any ownership state: rejected because it would hide useful possession state too often.
- Persisting last-known bank state across sessions: rejected because stale ownership would mislead players.

### 6. Group tracker entries by loot source with an `Other` fallback

The objective tracker should present tracked items under source headings corresponding to the dungeon or raid they drop from. If the addon cannot confidently determine a loot source for a tracked item, it should place the item under an `Other` group instead of omitting it or creating an unstable label. This keeps the tracker more browsable during play and aligns with how players mentally farm content.

Alternatives considered:
- Rendering one flat list of tracked items: rejected because wishlist growth would make the tracker harder to scan.
- Grouping only by coarse source type such as `Dungeon` or `Raid`: rejected because the player needs to know the specific farm target.
- Hiding items with unknown sources: rejected because players would lose access to tracked items whenever source metadata is incomplete.

### 7. Split notifications into informational and state-updating paths

When the player loots a tracked item, the addon should update best item level and trigger a tracker refresh without showing a popup. When another player loots a tracked item, the addon should show an alert popup naming the player and item but must not alter the local character's ownership state or best-looted item level. Loot roll frame tagging is purely visual and should not change saved state.

Alternatives considered:
- Showing the same popup for self and others: rejected to avoid notification noise during normal play.
- Updating best-looted item level based on another player's loot: rejected because the wishlist is character-specific.

### 8. Treat localization as a first-class data surface

All visible strings, including tracker section labels, popup text, checkbox tooltips or labels if used, and loot roll tags, should come from a localization table rather than inline string literals. Because the addon starts from scratch, it is cheaper to enforce this at the architecture level than to retrofit later.

Alternatives considered:
- English-first strings with later backfill: rejected because the v1 requirement explicitly includes all available game languages.

### 9. Prefer native Blizzard UI assets over custom visual components

The addon should reuse in-game UI assets and established Blizzard visual patterns wherever practical, including checkbox styles, tracker visuals, loot-roll decorations, and item/icon presentation. This reduces art and maintenance overhead, keeps the addon visually consistent with World of Warcraft, and lowers the risk of custom UI clashing with existing frames.

This also applies to motion: when a newly tracked item appears in the objective tracker, the addon should reuse the same style of add-to-tracker animation players already see when tracking a new quest, rather than introducing a bespoke animation language.

Alternatives considered:
- Creating custom textures and bespoke widget styling for the addon: rejected for v1 because it increases implementation complexity and produces a less native-feeling experience.
- Mixing native and custom visuals opportunistically without a guiding rule: rejected because it tends to create an inconsistent user experience.

## Risks / Trade-offs

- [Adventure Guide row rendering can be recycled or updated dynamically] -> Isolate checkbox injection from wishlist state and make UI refresh idempotent.
- [Stable item identity may be awkward to recover across journal rows, loot events, and owned-item scans] -> Centralize item normalization behind one resolver so mismatches are fixed in one place.
- [Bank state may be incomplete until the player visits the bank] -> Use best-effort bank possession and avoid persisting guessed bank ownership.
- [Item source metadata may be unavailable or ambiguous for some entries] -> Resolve source names through a dedicated mapping layer and fall back to `Other` instead of inventing labels.
- [Objective tracker rows have limited space and interaction affordances] -> Keep row formatting compact: tick, item name, and optional item level only.
- [Some Blizzard assets may not perfectly fit every desired interaction] -> Prefer native assets by default, and only introduce custom visuals where a native pattern cannot express the requirement.
- [Loot event coverage differs for self loot, other-player loot, and loot rolls] -> Define separate event paths and validate each path independently during implementation.
- [Full locale coverage increases maintenance cost] -> Keep strings minimal and organized in one localization surface.

## Migration Plan

Because the addon has no previous persisted schema, the initial rollout can introduce the character-specific saved-variable structure directly. During development, state migration is only needed if the internal key format for tracked items changes before release.

If a later revision changes wishlist identity or stored fields, the addon should prefer additive migration on load: read old fields, normalize them into the new structure, and then write the new format.

## Open Questions

- Which exact Blizzard events and APIs provide the most reliable signal for detecting another player's tracked-item loot in the intended play contexts?
- How should the tracker behave if item information is temporarily unavailable and only resolves asynchronously from the item API?
- Should the tracker display item links with quality coloring, or plain localized item names, in its first implementation?
