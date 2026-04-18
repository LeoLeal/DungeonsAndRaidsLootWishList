## Purpose

Define the Adventure Guide wishlist tag UI, including the favorite icon, live-apply popover, and destructive tag-delete confirmation flow.

## Requirements

### Requirement: Adventure Guide loot rows use a favorite icon for wishlist tags
The system SHALL replace Adventure Guide wishlist checkboxes with a favorite icon control with background ring. The control SHALL use `delves-scenario-heart-icon` with grey tint when the item has no assigned tags and white when the item has one or more assigned tags, surrounded by a background ring using `pvpqueue-rewardring-black` or `pvpqueue-rewardring` depending on state.

#### Scenario: Untracked loot row shows the off favorite icon
- **WHEN** the Adventure Guide renders a loot row for an item with no assigned wishlist tags
- **THEN** the row shows the `delves-scenario-heart-icon` atlas with black tint on a darker background ring

#### Scenario: Tagged loot row shows the on favorite icon
- **WHEN** the Adventure Guide renders a loot row for an item with one or more assigned wishlist tags
- **THEN** the row shows the `delves-scenario-heart-icon` atlas with white color on an active background ring

### Requirement: Favorite icon opens a live-apply tag popover
The system SHALL open a compact addon-owned popover near the cursor to the right of the clicked favorite icon. The popover SHALL size to its contents, use a parchment-friendly nineslice, include a close icon in the top-right corner, and dismiss when the user clicks either that close icon or outside the popover. Dismissing the popover SHALL NOT revert already applied changes.

#### Scenario: Clicking the favorite icon opens the popover near the cursor
- **WHEN** the user clicks the Adventure Guide favorite icon for a loot row
- **THEN** the system opens the tag popover near the cursor to the right of the clicked control

#### Scenario: Top-right close icon dismisses the popover
- **WHEN** the tag popover is open and the user clicks its close icon
- **THEN** the system dismisses the popover without reverting any already applied tag changes

#### Scenario: Outside click dismisses the popover
- **WHEN** the tag popover is open and the user clicks outside that popover
- **THEN** the system dismisses the popover without reverting any already applied tag changes

### Requirement: Popover manages item tag assignment with live apply
The popover SHALL list the current wishlist tags with a checkbox to the left of each label and a delete button to the right. Checking or unchecking a tag SHALL immediately assign or unassign that tag on the current item. Below the tag list, the popover SHALL provide a text input and `Create` button for creating new tags, with a "Create a new tag" label above the input, and creating a new tag SHALL NOT automatically assign it to the current item.

#### Scenario: Checking a tag immediately assigns it to the item
- **WHEN** the user checks a tag in the Adventure Guide popover for the current item
- **THEN** the system immediately assigns that tag to the item

#### Scenario: Unchecking a tag immediately removes it from the item
- **WHEN** the user unchecks a currently assigned tag in the Adventure Guide popover for the current item
- **THEN** the system immediately removes that tag from the item

#### Scenario: Adding a new tag does not assign it to the current item
- **WHEN** the user creates a new tag from the Adventure Guide popover
- **THEN** the system adds that tag to the tag catalog
- **AND** the new tag is not automatically assigned to the current item

### Requirement: Popover constrains tag deletion controls
The popover SHALL show `common-icon-delete` for deletable tags. When only one tag exists in the addon's tag catalog, that last remaining tag's delete control SHALL be disabled and SHALL use the `common-icon-delete-disable` atlas. The initial default tag MAY be deleted whenever it is not the only remaining tag.

#### Scenario: Last remaining tag shows disabled delete control
- **WHEN** only one tag exists in the addon's tag catalog
- **THEN** the popover disables that tag's delete button
- **AND** the button uses the `common-icon-delete-disable` atlas

#### Scenario: Default tag can be deleted when another tag exists
- **WHEN** the initial default tag is shown in the popover and at least one other tag also exists
- **THEN** the default tag's delete control remains enabled

### Requirement: Destructive tag deletion requires confirmation
When deleting a tag would remove one or more items from the wishlist because those items only have that tag, the system SHALL show a confirmation dialog that lists the affected items and asks `These items will be removed from the wishlist if you delete this tag. Are you sure you want to continue?` before the tag is actually deleted.

#### Scenario: Safe tag delete proceeds without confirmation
- **WHEN** the user deletes a tag that is not the sole tag on any wishlist item
- **THEN** the system deletes the tag without showing the destructive deletion confirmation dialog

#### Scenario: Destructive tag delete shows confirmation dialog
- **WHEN** the user deletes a tag that is the only assigned tag on one or more wishlist items
- **THEN** the system shows a confirmation dialog listing those items
- **AND** the dialog asks `These items will be removed from the wishlist if you delete this tag. Are you sure you want to continue?`

#### Scenario: Confirmed destructive delete removes affected items from the wishlist
- **WHEN** the destructive tag deletion confirmation dialog is shown and the user confirms the deletion
- **THEN** the system deletes the tag
- **AND** the items that had only that tag are removed from the wishlist
