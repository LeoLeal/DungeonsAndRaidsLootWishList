## Context

The addon currently crosses several taint-prone boundaries:

- `TrackerUI.lua` registers a native Objective Tracker module and renders through Blizzard's tracker update cycle.
- `TrackerUI.lua` writes addon state onto Blizzard-pooled tracker blocks and lines and uses the shared `GameTooltip` from those pooled line hooks.
- `AdventureGuideUI.lua` repeatedly scans all live frames and injects addon controls directly onto recycled Encounter Journal loot buttons.
- `LootEvents.lua` and `LootWishList.lua` defer popup work that still depends on event-derived values.
- `LootWishList.lua` performs some Encounter Journal selection work while building tracker-facing display state.

These patterns make the addon vulnerable to structural taint propagation. The visible failures already observed are consistent with this architecture: shared tooltip failures, secret-value errors inside Blizzard tooltip rendering, and combat-sensitive popup or tracker issues.

The design goal is not to redesign the addon. The design goal is to preserve the current player experience while moving rendering, tooltip ownership, and deferred alert state onto addon-owned boundaries.

```text
Current high-risk shape

Blizzard Tracker / Encounter Journal / Tooltip
                 |
                 v
        Addon logic runs inside
        Blizzard-owned frame/state

Target shape

Blizzard UI ---- post-hooks / read-only observation ----> Addon-owned surfaces
                                                          - wishlist tracker surface
                                                          - EJ checkbox overlay
                                                          - private wishlist tooltip
                                                          - sanitized alert queue
```

## Goals / Non-Goals

**Goals:**

- Preserve the current visible wishlist experience in the tracker area, Adventure Guide, loot rolls, and loot alerts.
- Remove direct dependence on Blizzard's native Objective Tracker module execution path.
- Stop storing addon-owned state on Blizzard-pooled tracker and Encounter Journal item frames.
- Isolate item tooltip ownership from the shared global `GameTooltip` when the hover originates from addon-owned wishlist UI.
- Sanitize loot-event data immediately and defer only addon-owned alert records.
- Keep module boundaries aligned with repo architecture: data/model logic stays separate from UI-facing code.

**Non-Goals:**

- Redesigning the wishlist UX or changing grouping behavior for players.
- Changing item identity rules, source grouping semantics, or persistence format unless required by the boundary refactor.
- Reworking Blizzard's own Encounter Journal tooltip behavior.
- Solving every possible taint issue in the entire WoW UI; this change is limited to surfaces directly owned by this addon.

## Decisions

### Decision 1: Replace native tracker-module participation with an addon-owned tracker sidecar

**Choice:** Replace the `ObjectiveTrackerModuleMixin`-based tracker implementation with an addon-owned frame tree that visually matches the Objective Tracker but is not registered through `ObjectiveTrackerFrame:AddModule`.

**Rationale:**

- `AddModule` is the strongest structural taint source in the addon because it inserts addon closures into Blizzard's tracker update lifecycle.
- Blizzard-pooled tracker blocks and lines are later reused by native modules, so storing addon fields and hooks on them creates contamination risk even if the hook logic is careful.
- An addon-owned sidecar keeps the same visual presentation while restoring ownership clarity.

**Design details:**

- The sidecar frame is parented to `UIParent`, not to a Blizzard tracker module.
- It is styled to match the native tracker header, blocks, and rows.
- It is positioned relative to the Objective Tracker region so it appears integrated with the tracker.
- When the native Objective Tracker is visible, the sidecar anchors below the visible tracker content.
- When the native Objective Tracker is hidden but the wishlist still has content, the sidecar anchors to the tracker region's normal origin so the wishlist remains visible in the expected location.
- Collapse/expand state for the wishlist section remains addon-owned.

**Implication for specs:**

- The player still sees a `Loot Wishlist` section in the tracker area.
- The implementation no longer requires native Objective Tracker module registration.
- Existing specs that currently require native module registration will need to be relaxed to describe visible behavior instead of internal tracker API usage.

### Decision 2: Use addon-owned row and block pools instead of writing state onto Blizzard-pooled lines

**Choice:** The tracker sidecar owns its own group-header frames, item-row frames, collapse buttons, and click/hover handlers.

**Rationale:**

- The current implementation writes fields such as `lootWishList_tooltipRef` and `lootWishList_itemID` onto Blizzard-pooled lines.
- Even with `HookScript`, that leaves addon data living on native pooled frames that secure Blizzard modules later reuse.
- Owning the row pool removes that shared-state hazard entirely.

**Design details:**

- `TrackerModel.lua` remains the source of grouped display data.
- `TrackerUI.lua` consumes the same data model but renders it through addon-owned pooled frames.
- `TrackerRowStyle.lua` remains the source of row offsets, tick atlas, and visual constants.
- Source-group header clicks, shift-click remove, and collapse buttons are implemented only on addon-owned frames.

### Decision 3: Use a private tooltip for addon-owned wishlist tracker rows

**Choice:** For tracker hover originating from addon-owned wishlist rows, use a private tooltip frame created by the addon with `GameTooltipTemplate` rather than the shared global `GameTooltip`.

**Rationale:**

- The shared `GameTooltip` is a cross-system object used by Blizzard tracker, Encounter Journal, and many other native flows.
- Once the tracker becomes addon-owned, there is no benefit to continuing to share hover tooltip ownership with Blizzard systems.
- A private tooltip preserves native item rendering while containing ownership and line-processing state to an addon-owned object.

**Safety note:**

- A private tooltip built with `GameTooltipTemplate` is expected to be safer than reusing the shared `GameTooltip` because the frame itself is addon-owned.
- The safety depends on two conditions:
  - the tooltip is populated only from clean, normalized item references
  - the tooltip is anchored to addon-owned frames or `UIParent`, not to Blizzard-pooled secure rows

**Design details:**

- The tooltip frame is created once and reused.
- The tooltip is owned by `UIParent` or the addon-owned row, depending on which proves cleaner under taint logging.
- The content remains Blizzard-native item tooltip content only; no addon-specific lines are added.
- Encounter Journal native tooltip behavior is left alone; this private tooltip is only for addon-owned tracker UI.

### Decision 4: Replace Encounter Journal frame enumeration with a narrow loot-surface adapter

**Choice:** Stop using `EnumerateFrames()` to discover candidate loot buttons. Instead, attach wishlist controls through a narrow Encounter Journal integration that tracks only visible loot-row elements.

**Rationale:**

- Full-frame enumeration is broad, repeated, and hard to reason about.
- It increases the chance of touching unrelated Blizzard buttons or stale recycled frames.
- The addon needs to integrate only with Encounter Journal loot rows, not the entire frame graph.

**Design details:**

- Post-hook the Encounter Journal loot update path that already refreshes visible loot elements.
- Resolve visible loot-row frames from the loot scroll surface only, not from the global frame list.
- Prefer an addon-owned checkbox overlay pool positioned over visible loot rows instead of storing addon state directly on Blizzard loot buttons.
- If a direct child checkbox must still be used for layout reasons, addon state is kept in an external lookup keyed by frame identity rather than written onto the Blizzard button itself.
- The adapter updates only while Encounter Journal loot UI is visible.

**Preferred direction:**

- Use addon-owned overlay checkboxes if practical, because this matches the same ownership rule as the tracker sidecar.
- Fall back to child controls only if overlay positioning proves too unstable across patches.

### Decision 5: Sanitize loot-event payloads immediately and queue only normalized alert records

**Choice:** Treat `CHAT_MSG_LOOT` and related loot events as parse-only boundaries. Extract the minimum clean alert record immediately and defer only that record.

**Rationale:**

- Delaying work is not the same as removing taint.
- Carrying raw `message` strings or raw event-derived links into later popup work preserves contamination across the boundary.
- The queue should hold addon-owned normalized data, not original event payloads.

**Normalized alert record:**

```text
alertRecord = {
  itemID,
  playerName,
  sourceType,
  tracked = true,
}
```

Optional derived fields may be included only if they are reconstructed from addon-owned state rather than retained from the original event payload.

**Design details:**

- Parse the event immediately.
- Resolve stable item identity immediately.
- Normalize the looter name immediately.
- Decide whether the event is relevant immediately.
- Queue only the normalized alert record.
- Reconstruct display text and item presentation at flush time from addon-owned state, item APIs, or stored metadata.

### Decision 6: Preserve the alert-dialog UX, but decouple it from raw event payloads

**Choice:** Keep the existing loot alert dialog experience as the primary UX target, but make the dialog renderer consume normalized alert records instead of raw chat-event strings or links.

**Rationale:**

- The player-facing requirement is the visible alert experience, not the specific internal path by which `StaticPopup_Show` receives its arguments.
- If a clean record plus safe timing is enough, the existing `LOOT_WISHLIST_ALERT` pattern can remain.
- If `StaticPopup_Show` still proves taint-prone even with clean input, the addon must be free to replace it with an addon-owned dialog that preserves the same visible experience.

**Design details:**

- Primary path: show `LOOT_WISHLIST_ALERT` from normalized data after combat / safe UI state.
- Fallback path: if taint logging still implicates popup execution, replace the popup implementation with an addon-owned alert frame styled to match the current dialog, including item presentation.
- The spec should describe the visible dialog behavior, not require a particular Blizzard popup API.

### Decision 7: Remove Encounter Journal global-selection mutation from normal tracker render paths

**Choice:** Do not call `EJ_SelectInstance`, `EJ_SelectEncounter`, or similar selection-mutating APIs during normal tracker rendering or group-model construction.

**Rationale:**

- Tracker rendering should be a pure-ish display pass over already-known data.
- The current render path performs Encounter Journal selection work to compute encounter order and source metadata, which creates unnecessary coupling to a live Blizzard UI system.
- This increases the chance that unrelated tracker refreshes mutate global Encounter Journal state.

**Design details:**

- Source metadata needed for tracker grouping should come from stored metadata or from an explicit resolver/cache layer.
- Any heavy EJ scanning should run in a bounded, explicit enrichment pass, not during tracker refresh.
- If encounter ordering data is needed for raid grouping, cache it separately and refresh it on safe lifecycle boundaries.

## Risks / Trade-offs

- **Risk: Sidecar positioning may drift from Blizzard tracker changes.**  
  **Mitigation:** Anchor to a small number of stable tracker-region reference points and refresh position only through narrow post-hooks or layout observation.

- **Risk: A private tooltip may behave slightly differently from the shared global tooltip.**  
  **Mitigation:** Keep content Blizzard-native, keep anchor rules simple, and validate compare / item rendering behavior under taint logging.

- **Risk: Encounter Journal overlay positioning may be more complex than child-frame injection.**  
  **Mitigation:** Scope the adapter to visible loot rows only and keep the fallback option of child controls with externalized state.

- **Risk: The wishlist can no longer literally keep `ObjectiveTrackerFrame` itself visible if the implementation stops using native module registration.**  
  **Mitigation:** Preserve the player-visible outcome instead: the wishlist section remains visible in the tracker area whenever it has content.

- **Risk: Deferred alert reconstruction may temporarily lack a rich item link.**  
  **Mitigation:** Build alerts from stable item identity first, then enrich with cached or API-resolved item presentation when available.

## Migration Plan

### Phase 1: Establish clean ownership boundaries

- Introduce addon-owned tracker container and row pool.
- Introduce private wishlist tooltip.
- Introduce normalized alert-record queue.

### Phase 2: Move tracker behavior off Blizzard module state

- Replace native tracker module registration.
- Reimplement source-group headers, rows, collapse controls, and click handlers on addon-owned frames.
- Keep `TrackerModel.lua` and `TrackerRowStyle.lua` as the stable model/style seam.

### Phase 3: Narrow Encounter Journal integration

- Replace global frame enumeration with a loot-surface adapter.
- Move wishlist-toggle state out of Blizzard button fields.
- Restrict update work to visible Encounter Journal loot rows.

### Phase 4: Remove live EJ selection from display paths

- Move encounter-order and source enrichment behind an explicit cache/resolver boundary.
- Keep tracker refresh free of Encounter Journal global selection mutation.

### Phase 5: Validate with taint logging

- Reproduce previous tracker, tooltip, Encounter Journal, and loot-alert scenarios with `/console taintLog 1` and `/console taintLog 2`.
- Verify no addon-owned tracker hover causes downstream Blizzard tooltip or MoneyFrame failures.
- Verify tracker-area visibility, collapse behavior, loot roll tags, Adventure Guide toggles, and alert dialogs remain intact.

## Open Questions

- For the private tracker tooltip, is `SetHyperlink` on a private `GameTooltipTemplate` frame sufficient for all desired item rendering cases, or do some cases require a fallback to item-ID-based population?
- In Encounter Journal, will an addon-owned overlay be stable enough across visible loot-row layouts, or will a child-control approach with externalized state be the more durable compromise?
- Does the final spec need to preserve the exact use of `StaticPopupDialogs`, or only the visible modal-alert behavior with item presentation and dismissal controls?
