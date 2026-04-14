## Why

The addon has grown around several horizontal modules, which makes ownership boundaries less clear and increases coupling between UI, orchestration, and feature-specific behavior. Reorganizing the code into vertical feature folders will make responsibilities easier to understand and maintain now, while preserving the current addon behavior during future changes.

## What Changes

- Reorganize the addon into a small `Core` area that contains bootstrap code plus `Core/Shared` primitives used across features.
- Keep persistence in a separate `DataStore` area rather than folding saved-variable concerns into feature folders.
- Move Adventure Guide integration into a dedicated `AdventureGuide` feature folder.
- Move Objective Tracker logic into a dedicated `Tracker` feature folder.
- Move loot event reactions into a dedicated `LootAwareness` feature folder.
- Clarify that `LootAwareness` owns its alert and roll badge behavior internally instead of splitting those responsibilities across unrelated modules.
- Move shared, reusable primitives into `Core/Shared` so cross-feature dependencies stay explicit and minimal.
- Remove the no-longer-useful local test suite as part of the refactor cleanup instead of carrying it forward under the new module layout.
- Clean up module responsibilities as part of the reorganization without intentionally changing user-facing behavior beyond what is necessary to complete the refactor.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `adventure-guide-wishlist-toggle`: Clarify that journal-facing wishlist toggle behavior and metadata capture are owned by the AdventureGuide feature.
- `wishlist-tracker-display`: Clarify that tracker rendering, grouping, interaction, and possession-driven presentation are owned by the Tracker feature.
- `tracker-item-tooltips`: Clarify that tracker tooltip behavior is owned by the Tracker feature while shared tooltip primitives remain in `Core/Shared`.
- `tracker-grouping-preferences`: Clarify that persisted grouping and collapse preferences remain DataStore-owned while Tracker consumes them through feature boundaries.
- `wishlist-storage-model`: Clarify that persistence, migration, and tracker preferences are owned by DataStore and remain separate from feature UI concerns.
- `wishlist-loot-awareness`: Clarify that loot-event parsing, wishlist matching, and self-loot suppression are owned by the LootAwareness feature.
- `loot-alert-dialog`: Clarify that alert queueing and presentation live under LootAwareness as part of loot reaction behavior.
- `wishlist-localization`: Clarify that addon-wide localization primitives remain shared under `Core/Shared` and are consumed by features rather than duplicated per feature.

## Impact

- Affected code: addon bootstrap/orchestration, shared helpers, persistence access, Adventure Guide integration, tracker UI/model code, and loot-awareness UI/event handling.
- Affected systems: module layout, file ownership, dependency boundaries, internal responsibility assignment, and local test assets.
- APIs/dependencies: no intended external API or saved-variable format change beyond what is required to support the refactor.
- User-facing behavior: expected to remain functionally equivalent, with this change focused on structural cleanup rather than feature changes.
