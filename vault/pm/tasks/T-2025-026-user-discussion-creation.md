---
type: task
id: T-2025-026
story:
epic:
status: completed
priority: p1
created: 2026-01-17
updated: 2026-01-18
completed: 2026-01-18
---

# Task: User Discussion Creation & Canvas Cleanup

## Task Details
**Task ID**: T-2025-026
**Story**:
**Epic**:
**Status**: Completed
**Priority**: P1 (High)
**Branch**: feat/T-2025-026-user-discussion-creation
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**: 2026-01-18

## Description
Clean out the old canvas frontend code and add the ability for users to create new discussion nodes. Currently pressing "n" opens the legacy canvas view which is no longer used.

**Implemented approach**: Added dedicated slots 7-8 for user-created discussions (max 2), plus a "Peer Contributions" community folder for discovering other users' discussions.

## Acceptance Criteria
- [x] Remove or disable old canvas view triggered by "n" key
- [x] Users can create new discussion nodes
- [x] User-created discussions appear in a dedicated area (slots 7-8)
- [x] New discussions integrate with existing node/messaging system
- [x] Clean UI for creating discussion (title, optional description)

## Checklist
- [x] Audit and remove legacy canvas code
- [x] Design user discussion creation flow
- [x] Implement "create discussion" UI
- [x] Add slots 7-8 for user discussions
- [x] Wire up to existing Grid.create_node
- [x] Test discussion creation and messaging

## Technical Details
### Implementation Summary
1. **Database**: Added `created_node_ids` field to users table (max 2)
2. **Accounts**: Added functions for managing created nodes (add/remove)
3. **Terminal Live**:
   - Repurposed "n" key to open create discussion modal
   - Added slots 7-8 display with amber/gold styling
   - Keys 7-8 navigate to user's created discussions
   - "+" button only shows if < 2 created discussions
4. **Node Live**: Shows slots 7-8 in bucket indicator row
5. **Peer Contributions Folder**: Community folder with:
   - 4 random selections from recent (48h) discussions
   - 4 weighted by engagement (message count)
   - Refreshes every 8 hours
   - Excludes user's own discussions from their view

### Files Modified
- `priv/repo/migrations/20260117215934_add_created_node_ids_to_users.exs`
- `priv/repo/migrations/20260118000624_add_community_folder_support.exs`
- `priv/repo/migrations/20260118000909_make_system_prompt_nullable.exs`
- `lib/gridroom/accounts/user.ex`
- `lib/gridroom/accounts.ex`
- `lib/gridroom/folders/folder.ex`
- `lib/gridroom/folders/community_node_selection.ex` (new)
- `lib/gridroom/folders.ex`
- `lib/gridroom_web/live/terminal_live.ex`
- `lib/gridroom_web/live/node_live.ex`
- `priv/repo/seeds.exs`

### Testing Required
- [x] Discussion creation flow
- [x] New discussions show in UI (slots 7-8)
- [x] Messaging works in user-created discussions
- [x] Peer Contributions folder shows other users' discussions

### Documentation Updates
- None required

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-026-context]] for detailed implementation notes.

## Commits
- chore: start work on T-2025-026
- feat: Add dedicated user discussion slots (7-8) and Peer Contributions folder

## Review Checklist
- [x] Code review completed
- [x] Tests written and passing
- [x] Documentation updated
- [x] No debugger statements
- [x] Security considerations addressed

## Notes
- User discussions decay same as AI-generated (1-3d quiet, 3-5d fading, 5d+ vaulted/gone)
- Limit: max 2 user-created discussions at a time (slots 7-8)
- Future: Could add resonance cost for discussion creation
