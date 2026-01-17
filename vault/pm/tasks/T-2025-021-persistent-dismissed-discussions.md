---
type: task
id: T-2025-021
story:
epic:
status: completed
priority: p2
created: 2026-01-16
updated: 2026-01-17
completed: 2026-01-17
---

# Task: Persistent Dismissed Discussions

## Task Details
**Task ID**: T-2025-021
**Status**: Completed
**Priority**: P2 (Medium)
**Branch**: feat/T-2025-021-persistent-dismissed-discussions
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**: 2026-01-17

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
- [x] Test persistence across refresh
- [x] Test persistence across bucket clear

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

### Additional Work Done
- Rebranded app to "Innie Chat" with Lumon/Severance terminology
- Redesigned auth pages with terminal boot aesthetic
- Implemented 682 surreal glyph designations system
- Required account to chat (anonymous can view only)
- Fixed layout shift bugs on overlay pages
- Fixed help overlay "any key to close" functionality
- Made registration page more compact for smaller screens

### Testing Required
- [x] Dismissal persists on refresh
- [x] Dismissal persists on bucket clear
- [x] Dismissed discussion doesn't reappear
- [x] Works for anonymous users
- [x] Works for authenticated users

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-021-context]] for detailed implementation notes.

## Notes
- "Innie Chat" rebrand completed
- Bucket clearing does NOT restore dismissed discussions
- Glyph system provides 682 unique surreal designations
