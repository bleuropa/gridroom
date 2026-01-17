---
type: task
id: T-2025-021
story:
epic:
status: in-progress
priority: p2
created: 2026-01-16
updated: 2026-01-16
---

# Task: Persistent Dismissed Discussions

## Task Details
**Task ID**: T-2025-021
**Status**: In Progress
**Priority**: P2 (Medium)
**Branch**: feat/T-2025-021-persistent-dismissed-discussions
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
When users dismiss a discussion by clicking X, that dismissal should persist permanently. Currently dismissals are lost on page refresh or when buckets are cleared. Users should never see a discussion they've explicitly dismissed, regardless of session state.

## Acceptance Criteria
- [x] Dismissed discussion IDs stored in database (not session/local storage)
- [x] Dismissed discussions hidden from discovery/emergence UI
- [x] Dismissals persist across page refreshes
- [x] Dismissals persist across bucket clearing
- [x] Dismissals work for both anonymous (session) and authenticated users
- [ ] Anonymous user dismissals migrate to account on login (optional - future)
- [x] Prevent bucketing same discussion in multiple buckets (enforce single-bucket per discussion)

## Checklist
- [x] Design dismissal storage schema
- [x] Create migration for user_dismissed_nodes table
- [x] Add dismiss context functions
- [x] Update discovery query to exclude dismissed
- [x] Update emergence UI to hide dismissed
- [ ] Test persistence across refresh
- [ ] Test persistence across bucket clear

## Technical Details
### Approach
- Added `user_dismissed_nodes` table linking user to dismissed node IDs
- Filter dismissed IDs in emergence queue on mount
- Anonymous users tracked via their user record (created from session_id)
- Single-bucket enforcement via `cond` check in `add_to_buckets`

### Files Modified
- `priv/repo/migrations/20260117020919_add_user_dismissed_nodes.exs` - new table
- `lib/gridroom/accounts/user_dismissed_node.ex` - schema
- `lib/gridroom/accounts.ex` - dismissal context functions + single-bucket check
- `lib/gridroom_web/live/terminal_live.ex` - exclude dismissed from queue, persist on X

### Testing Required
- [ ] Dismissal persists on refresh
- [ ] Dismissal persists on bucket clear
- [ ] Dismissed discussion doesn't reappear
- [ ] Works for anonymous users
- [ ] Works for authenticated users

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-021-context]] for detailed implementation notes.

## Notes
- "Innie Chat" rebrand mentioned - may want to update app name separately
- Bucket clearing should NOT restore dismissed discussions
