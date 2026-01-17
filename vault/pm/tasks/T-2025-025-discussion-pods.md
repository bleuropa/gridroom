---
type: task
id: T-2025-025
story:
epic:
status: in-progress
priority: p1
created: 2026-01-17
updated: 2026-01-17
---

# Task: Discussion Pods - Private Group Messaging

## Task Details
**Task ID**: T-2025-025
**Story**:
**Epic**:
**Status**: In Progress
**Priority**: P1 (High)
**Branch**: feat/T-2025-025-discussion-pods
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**:

## Description
Add "Pods" - private groups within discussions. Users can invite each other to pods, and when viewing a discussion, they can toggle between the general discussion view and their pod view(s). Messages entered in a pod pane are only visible to other pod members.

Key behaviors:
- Each discussion has a general view (existing behavior) and optional pod views
- Users can create pods and invite other users to them
- Messages in pods are private to pod members only
- General discussion messages are NOT shown in pod panes by default
- Pod members can forward messages from general discussion into their pod

## Acceptance Criteria
- [ ] Users can create a pod within a discussion
- [ ] Users can invite other users to their pods
- [ ] Pod view shows only messages from pod members
- [ ] General discussion remains separate from pod views
- [ ] Users can toggle between general and pod views in a discussion
- [ ] Users can forward general messages to a pod
- [ ] Pod membership is persisted and managed

## Checklist
- [ ] Design pod data model (schema)
- [ ] Create pod membership/invitation system
- [ ] Build pod message scoping (visibility)
- [ ] Add UI for pod view toggle
- [ ] Add UI for creating pods
- [ ] Add UI for inviting users
- [ ] Add message forwarding from general to pod
- [ ] Write tests

## Technical Details
### Approach
- New `pods` and `pod_memberships` schemas
- Messages gain optional `pod_id` field (null = general)
- LiveView component for pod selector/toggle
- Invitation system (accept/decline flow)

### Files to Modify
- New: `lib/gridroom/pods.ex` (context)
- New: `lib/gridroom/pods/pod.ex` (schema)
- New: `lib/gridroom/pods/pod_membership.ex` (schema)
- Modify: `lib/gridroom/grid/message.ex` (add pod_id)
- Modify: `lib/gridroom_web/live/node_live.ex` (pod UI)
- New migration for pods tables

### Testing Required
- [ ] Pod creation and membership
- [ ] Message visibility scoping
- [ ] Invitation flow
- [ ] Forwarding messages

### Documentation Updates
- Update any existing discussion docs

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-025-context]] for detailed implementation notes.

## Commits
-

## Review Checklist
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debugger statements
- [ ] Security considerations addressed

## Notes
- Consider: Should forwarded messages show original author or forwarder?
- Consider: Can users leave pods? What happens to their messages?
- Consider: Pod naming/theming to match Severance aesthetic
