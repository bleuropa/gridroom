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
- [ ] Dismissed discussion IDs stored in database (not session/local storage)
- [ ] Dismissed discussions hidden from discovery/emergence UI
- [ ] Dismissals persist across page refreshes
- [ ] Dismissals persist across bucket clearing
- [ ] Dismissals work for both anonymous (session) and authenticated users
- [ ] Anonymous user dismissals migrate to account on login (optional)
- [ ] Prevent bucketing same discussion in multiple buckets (enforce single-bucket per discussion)

## Checklist
- [ ] Design dismissal storage schema
- [ ] Create migration for dismissed_discussions table
- [ ] Add dismiss endpoint/handler
- [ ] Update discovery query to exclude dismissed
- [ ] Update emergence UI to hide dismissed
- [ ] Test persistence across refresh
- [ ] Test persistence across bucket clear

## Technical Details
### Approach
- Add `dismissed_discussions` table linking user/session to discussion IDs
- Filter dismissed IDs in discovery/emergence queries
- For anonymous users, tie to session ID

### Files to Modify
- `priv/repo/migrations/` - new migration
- `lib/gridroom/discussions/` - dismissal context
- `lib/gridroom_web/live/` - emergence/discovery LiveView
- Database queries for discovery

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
