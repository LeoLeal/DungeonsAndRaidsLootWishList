## Purpose

Define the per-character persisted preferences that control whether the wishlist tracker is attached or detached, where detached mode appears, and whether detached mode is locked against movement.

## Requirements

### Requirement: Wishlist tracker attachment mode persists per character

The addon SHALL persist whether the `Loot Wishlist` tracker is attached to the Objective Tracker or detached as a movable frame per character. Characters without a saved tracker attachment preference SHALL default to the attached tracker presentation.

#### Scenario: Tracker defaults to attached mode

- **WHEN** the active character has tracked wishlist items and no saved tracker attachment preference
- **THEN** the `Loot Wishlist` tracker appears attached to the Objective Tracker

#### Scenario: Detached mode is restored after reload

- **WHEN** the player detaches the `Loot Wishlist` tracker and reloads the UI or logs back in on the same character
- **THEN** that character's `Loot Wishlist` tracker returns in detached mode

#### Scenario: Reattached mode is restored after reload

- **WHEN** the player detaches the `Loot Wishlist` tracker, reattaches it, and reloads the UI or logs back in on the same character
- **THEN** that character's `Loot Wishlist` tracker returns attached to the Objective Tracker

#### Scenario: Attachment preference stays isolated per character

- **WHEN** one character changes the `Loot Wishlist` tracker between attached and detached mode
- **THEN** another character's tracker attachment mode is unaffected until that character changes its own preference

### Requirement: Detached tracker position persists per character

The addon SHALL persist the last moved screen position of the detached `Loot Wishlist` tracker per character using stable UI-relative anchor data. When the tracker is detached again after having been reattached, the addon SHALL restore that same character's last detached position instead of recomputing placement from the Objective Tracker.

#### Scenario: Reload preserves detached position

- **WHEN** the player moves the detached `Loot Wishlist` tracker and reloads the UI or logs back in on the same character while it remains detached
- **THEN** the detached `Loot Wishlist` tracker returns at the same screen position

#### Scenario: Redetaching restores the last detached position

- **WHEN** the player detaches the `Loot Wishlist` tracker, moves it, reattaches it, and later detaches it again on the same character
- **THEN** the tracker reappears at the last saved detached position rather than at a newly computed Objective Tracker-relative position

#### Scenario: Detached position stays isolated per character

- **WHEN** one character moves the detached `Loot Wishlist` tracker to a new screen position
- **THEN** another character's detached tracker position is unaffected until that character moves its own detached tracker

### Requirement: Detached tracker lock state persists per character

The addon SHALL persist whether the detached `Loot Wishlist` tracker is locked against movement per character. Characters without a saved detached lock preference SHALL default to an unlocked detached tracker the first time they enter detached mode. The persisted lock state SHALL be restored when the same character reloads, relogs, reattaches, and later detaches again.

#### Scenario: First detached tracker defaults to unlocked

- **WHEN** the active character detaches the `Loot Wishlist` tracker and has no saved detached lock preference
- **THEN** the detached tracker starts unlocked and movable

#### Scenario: Locked detached state is restored after reload

- **WHEN** the player locks the detached `Loot Wishlist` tracker and reloads the UI or logs back in on the same character while it remains detached
- **THEN** that character's detached `Loot Wishlist` tracker returns locked against movement

#### Scenario: Lock state is restored when detaching again

- **WHEN** the player detaches the `Loot Wishlist` tracker, changes its lock state, reattaches it, and later detaches it again on the same character
- **THEN** the detached tracker returns with the same saved lock state it had before being reattached

#### Scenario: Detached lock state stays isolated per character

- **WHEN** one character changes the detached `Loot Wishlist` tracker between locked and unlocked state
- **THEN** another character's detached lock state is unaffected until that character changes its own setting
