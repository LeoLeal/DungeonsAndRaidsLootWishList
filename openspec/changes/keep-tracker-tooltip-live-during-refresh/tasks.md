## 1. Capture live hover target during tracker refresh

- [x] 1.1 Inspect the tracker refresh path in `TrackerUI.lua` and identify where hover state can be sampled before and after row rebinding without suppressing refresh triggers.
- [x] 1.2 Add tracker-owned hover reconciliation state that can determine which visible tracker row is currently under the cursor after a refresh.

## 2. Reconcile tooltip lifecycle after row updates

- [x] 2.1 Replace unconditional tooltip teardown at the start of tracker refresh with post-render hover reconciliation that re-shows the tooltip for the current valid hovered row.
- [x] 2.2 Ensure that if the row under the cursor is rebound to a different tracked item during refresh, the tracker tooltip switches to that row's current item instead of disappearing.
- [x] 2.3 Ensure that group headers, boss headers, hidden rows, collapsed tracker states, and empty hover targets fully hide the primary tooltip and compare panes.

## 3. Verify resilient hover behavior

- [x] 3.1 Confirm that normal hover enter/leave behavior still works for tracker item rows and that compare panes remain coupled to the primary tooltip.
- [ ] 3.2 Manually verify tooltip stability during frequent city refresh traffic, quiet dungeon conditions, group collapse changes, and item removal while hovering the tracker.
