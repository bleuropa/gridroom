---
type: task
id: T-2025-011
status: backlog
priority: p2
created: 2026-01-16
updated: 2026-01-16
---

# Task: Portal System with Energy Cost

## Task Details
**Task ID**: T-2025-011-portal-system
**Status**: Backlog
**Priority**: P2
**Branch**: feat/T-2025-011-portal-system
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Users can place portals that link two locations on the grid. Portals cost "energy" to create and/or use, introducing a lightweight economy to the grid.

This adds:
- Fast navigation between distant areas
- User-created infrastructure
- A cost mechanic that prevents spam

## Acceptance Criteria
- [ ] Users can create portals between two points
- [ ] Portals have visual representation on grid
- [ ] Using a portal teleports user to destination
- [ ] Portal creation costs energy
- [ ] Energy system exists (earn/spend)

## Checklist
- [ ] Design portal mechanics (one-way? two-way?)
- [ ] Design energy system (how earned, how spent)
- [ ] Add portals table to database
- [ ] Implement portal creation flow
- [ ] Portal rendering on grid
- [ ] Portal usage (teleport animation)
- [ ] Energy tracking per user

## Technical Details
### Approach
**Portal Types**:
1. **Personal portals**: Only you can use them
2. **Public portals**: Anyone can use them (higher cost?)
3. **Temporary portals**: Expire after N uses or time

**Energy System Ideas**:
- Earn energy by: being active in nodes, receiving upvotes on messages
- Spend energy on: portals, node creation (T-2025-012), other future features
- Start users with some baseline energy

### Files to Modify
- New: `lib/gridroom/portals.ex` - portal context
- New: `lib/gridroom/economy.ex` - energy system
- `lib/gridroom/accounts/user.ex` - add energy field
- `lib/gridroom_web/live/grid_live.ex` - portal rendering, creation UI

## Dependencies
### Blocked By
- None, but pairs well with T-2025-012 (node creation cost)

### Blocks
- None

## Context
See [[T-2025-011-context]] for detailed implementation notes.

## Notes
- Energy system is foundational - design it for reuse
- Portals should feel magical, not utilitarian
- Consider: portal decay over time? Maintenance cost?
- This introduces game-like elements - keep it subtle
