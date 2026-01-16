---
type: task
id: T-2025-006
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Node Creation System

## Task Details
**Task ID**: T-2025-006-node-creation-system
**Status**: In Progress
**Priority**: P1
**Branch**: feat/T-2025-006-node-creation-system
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
Allow users to create their own nodes on the grid. This is a core feature for user-generated content - users can plant new topic nodes where they want conversations to happen.

Key questions to resolve:
- Who can create nodes? (anyone vs auth users only)
- What limits exist? (rate limiting, proximity rules)
- What metadata is required? (title, description, category)

## Acceptance Criteria
- [ ] Auth users can create new nodes on the grid
- [ ] Node creation UI appears at chosen grid location
- [ ] Required fields: title (and optionally category/description)
- [ ] New node appears immediately for all users
- [ ] Creator is automatically placed in the new node

## Checklist
- [ ] Design node creation modal/form
- [ ] Add "create node" interaction (right-click? button?)
- [ ] Implement `Nodes.create_node/2` in context
- [ ] Broadcast new node via PubSub
- [ ] Add rate limiting (max N nodes per user per day)
- [ ] Test node creation flow

## Technical Details
### Approach
- Click or right-click on empty grid space → creation modal
- Node positioned at click coordinates
- PubSub broadcast to all connected clients
- Phoenix Presence updates immediately

### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` - add creation interaction
- `lib/gridroom/nodes.ex` - add create function
- `lib/gridroom_web/components/` - node creation form component

## Dependencies
### Blocked By
- None (can start now)

### Blocks
- [[T-2025-012-node-creation-cost-proximity]] - adds cost layer to this

## Context
See [[T-2025-006-context]] for detailed implementation notes.

## Notes
- Consider: should anonymous users be able to create nodes?
- This unlocks the "Phase 7: Creation Tools" from VISION.md
