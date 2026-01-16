---
type: task
id: T-2025-003
status: backlog
priority: high
created: 2025-01-15
updated: 2025-01-15
---

# Task: Build Gridroom MVP

## Task Details
**Task ID**: T-2025-003-gridroom-mvp
**Status**: Backlog
**Priority**: High
**Branch**: feat/T-2025-003-gridroom-mvp
**Created**: 2025-01-15
**Started**:
**Completed**:

## Description
Build the Gridroom MVP - an infinite pannable grid canvas where users appear as abstract glyphs, can explore topic nodes, and have conversations in rooms that emerge around those nodes.

## Acceptance Criteria
- [ ] Infinite 2D grid canvas with smooth pan/zoom
- [ ] Users represented as geometric glyphs (session-based)
- [ ] Real-time presence - see other users on the grid
- [ ] Topic nodes visible on the grid with labels
- [ ] Click node to enter conversation room
- [ ] Chat within rooms with message persistence
- [ ] Severance-meets-tavern aesthetic from day one

## Checklist
- [ ] Set up LiveView with canvas/SVG grid
- [ ] Implement pan and zoom controls
- [ ] Create user session with glyph assignment
- [ ] Add Phoenix Presence for real-time tracking
- [ ] Build topic node schema and display
- [ ] Create room/conversation system
- [ ] Style with mysterious, warm aesthetic

## Technical Details
### Stack
- Phoenix LiveView for real-time
- Canvas API or SVG for grid rendering
- Phoenix Presence for user tracking
- PostgreSQL for persistence
- Tailwind CSS for styling

### Key Components
1. GridLive - main LiveView for the infinite canvas
2. Presence - track users and their positions
3. Node - topic markers on the grid
4. Room - conversation space within nodes
5. Message - chat messages in rooms

## Context
See [[T-2025-003-context]] for implementation details.

## Notes
- Aesthetic is critical - must feel right from first load
- Anonymous/session-based to start
- See VISION.md for full design direction
