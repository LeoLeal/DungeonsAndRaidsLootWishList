## Context

Currently, `DungeonsAndRaidsLootWishList` groups tracked items by instance name in the objective tracker. For raid instances, this can be insufficient, as players often want to know exactly which boss drops the item without reopening the Adventure Guide. The proposal requires that items tracked from raid bosses dynamically resolve and display the boss name next to the item name in the objective tracker.

## Goals / Non-Goals

**Goals:**
- Provide immediate, at-a-glance context for where raid loot comes from.
- Display the boss name in white text enclosed in parentheses after the item name and item level.
- Dynamically resolve the boss name and raid status at render time using the Encounter Journal API to keep the saved variables factual and pure.
- Ensure dungeon items continue to display normally without boss names.

**Non-Goals:**
- Do not display boss names for items originating from dungeons.
- Do not make the boss name a clickable link.
- Do not fetch the boss name at capture time (checkbox click) and permanently store it in SavedVariables.

## Decisions

- **Dynamic Resolution at Render Time (Approach 2):** Instead of resolving the boss name when the user clicks the checkbox and saving it to `SavedVariables`, the addon will capture the `encounterID` (or `bossID`) and `instanceID` at capture time and persist these factual IDs. During the tracker refresh cycle, the addon will query the `EJ` API to determine if the instance is a raid and to resolve the boss name.
  - *Rationale:* This keeps the `SavedVariables` pure and factual, relying on the game's API to provide the localized and up-to-date boss name and instance classification.
  - *Alternatives Considered:* Resolving and saving the localized boss name string directly to `SavedVariables` at capture time. This was rejected because it stores derived/localized data that could become stale or incorrect if Blizzard reclassifies an instance or changes a localization string.

- **Identifying Raid Instances:** The addon will use `EJ_GetInstanceByIndex(index, true)` (where `true` filters for raids) to scan the Encounter Journal API and build a set or check if the target `instanceID` is a raid.
  - *Rationale:* This is the most reliable way to determine if an instance is considered a raid by the Encounter Journal.
  - *Alternatives Considered:* Checking `button.shouldDisplayDifficulty` or max party size. Rejected as less robust than directly querying the EJ's raid list.

- **Display Formatting:** The boss name will be formatted as `Item Name [(ItemLevel)] [|cffffffff(BossName)|r]`. If the item level is present, it appears before the boss name.
  - *Rationale:* This provides a clean, distinct look that clearly separates the item's properties (name, ilvl) from its source (boss).

- **Data Migration:** A one-time migration step will be introduced to handle existing saved variables.
  - *Rationale:* Existing tracked items lack `encounterID` and `instanceID` metadata. To prevent structural errors and data corruption, a migration function will run upon loading saved variables. It will ensure that all existing items have properly initialized metadata structures, avoiding nil-reference crashes in the updated codebase.

## Risks / Trade-offs

- **[Risk] API Query Overhead:** Calling EJ APIs (`EJ_GetInstanceByIndex`, `EJ_GetEncounterInfo`) during the tracker refresh loop might introduce slight overhead, especially if the user is tracking many items.
  - *Mitigation:* The performance impact is expected to be negligible given the typical number of tracked items. If it becomes a concern, the results of the EJ queries could be cached in memory during the session.
- **[Risk] Missing Encounter Data:** Some items in the Adventure Guide might lack an `encounterID` or `bossID` (e.g., trash drops).
  - *Mitigation:* The design dictates that if the addon cannot determine the boss name or verify the instance is a raid, it gracefully falls back to displaying only the item name.