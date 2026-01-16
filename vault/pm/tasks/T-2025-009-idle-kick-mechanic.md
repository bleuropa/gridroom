---
type: task
id: T-2025-009
status: backlog
priority: p2
created: 2026-01-16
updated: 2026-01-16
---

# Task: Idle Kick Mechanic

## Task Details
**Task ID**: T-2025-009-idle-kick-mechanic
**Status**: Backlog
**Priority**: P2
**Branch**: feat/T-2025-009-idle-kick-mechanic
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Users get removed from a node room if they're idle for too long. This keeps rooms feeling active and prevents ghost users from cluttering presence displays.

Questions to resolve:
- What constitutes "idle"? (no messages? no mouse movement? tab backgrounded?)
- How long before kick? (5 min? 15 min?)
- Where do kicked users go? (back to grid at node location?)
- Any warning before kick?

## Acceptance Criteria
- [ ] Idle detection works reliably
- [ ] Users are removed from node after idle timeout
- [ ] User sees a warning before being kicked
- [ ] Kicked user returns to grid (not disconnected entirely)
- [ ] Returning to node is easy (re-click)

## Checklist
- [ ] Define idle detection criteria
- [ ] Implement client-side activity tracking
- [ ] Server-side idle timeout logic
- [ ] Warning UI before kick (30s warning?)
- [ ] Graceful removal from node room
- [ ] Test idle flow end-to-end

## Technical Details
### Approach
- Client sends heartbeat with last activity timestamp
- Server tracks last activity per user per node
- GenServer or scheduled task checks for idle users
- PubSub broadcast when user is kicked

### Idle Criteria Options
1. **Strict**: No messages sent in X minutes
2. **Moderate**: No mouse/scroll activity in X minutes
3. **Lenient**: Tab/window not visible in X minutes

Recommend: Start with "no messages in 10 minutes" as baseline.

### Files to Modify
- `lib/gridroom_web/live/node_live.ex` - activity tracking, warning UI
- `lib/gridroom/rooms.ex` - idle check logic
- JS hooks for activity detection

## Dependencies
### Blocked By
- None (can start now)

### Blocks
- None

## Context
See [[T-2025-009-context]] for detailed implementation notes.

## Notes
- Balance: Don't be annoying, but don't let rooms fill with ghosts
- Consider: VIP/auth users get longer timeout?
- This encourages active participation
