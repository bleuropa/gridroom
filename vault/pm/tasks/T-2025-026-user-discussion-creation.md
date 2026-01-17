---
type: task
id: T-2025-026
story:
epic:
status: in-progress
priority: p1
created: 2026-01-17
updated: 2026-01-17
---

# Task: User Discussion Creation & Canvas Cleanup

## Task Details
**Task ID**: T-2025-026
**Story**:
**Epic**:
**Status**: In Progress
**Priority**: P1 (High)
**Branch**: feat/T-2025-026-user-discussion-creation
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**:

## Description
Clean out the old canvas frontend code and add the ability for users to create new discussion nodes. Currently pressing "n" opens the legacy canvas view which is no longer used.

**Proposed approach**: Add a 7th "bucket" slot that serves as a user-generated discussions area. This provides a dedicated space for custom topics separate from the AI-generated folder content.

## Acceptance Criteria
- [ ] Remove or disable old canvas view triggered by "n" key
- [ ] Users can create new discussion nodes
- [ ] User-created discussions appear in a dedicated area (7th bucket concept)
- [ ] New discussions integrate with existing node/messaging system
- [ ] Clean UI for creating discussion (title, optional description)

## Checklist
- [ ] Audit and remove legacy canvas code
- [ ] Design user discussion creation flow
- [ ] Implement "create discussion" UI
- [ ] Add 7th bucket slot or equivalent for user discussions
- [ ] Wire up to existing Grid.create_node
- [ ] Test discussion creation and messaging

## Technical Details
### Approach
- Remove/disable "n" key canvas trigger
- Add create discussion modal or dedicated UI
- Possibly add a "+" bucket or "My Discussions" section
- Reuse existing Grid context for node creation

### Files to Modify
- `assets/js/app.js` - Remove "n" key handler if there
- `lib/gridroom_web/live/terminal_live.ex` - Main interface
- Possibly new component for discussion creation

### Testing Required
- [ ] Discussion creation flow
- [ ] New discussions show in UI
- [ ] Messaging works in user-created discussions

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
-

## Review Checklist
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debugger statements
- [ ] Security considerations addressed

## Notes
- Consider: Should user discussions have a different visual treatment?
- Consider: Limits on how many discussions a user can create?
- Consider: Should user discussions decay like AI-generated ones?
