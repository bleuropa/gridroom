---
type: task
id: T-2025-019
status: backlog
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Corridor Navigation System

## Task Details
**Task ID**: T-2025-019
**Status**: Backlog
**Priority**: P1 (High)
**Branch**: feat/T-2025-019-corridor-navigation
**Created**: 2026-01-16

## Description

Replace the current 2D canvas grid view with a Severance-inspired corridor/tunnel navigation system. Users navigate through branching hallways where doors/alcoves lead to discussion rooms (nodes). The design should feel mysterious and immersive while reusing existing node/room functionality.

Key experience goals:
- "Where does this hallway lead?" mystery
- Doors reveal discussion rooms (existing nodes)
- Murmurs/activity indicators as you approach active discussions
- Dead ends and turns create discovery moments
- Warm lighting to balance the sterile corridor aesthetic

## Acceptance Criteria
- [ ] Users can navigate through corridors using keyboard/click
- [ ] Discussions appear as doors/alcoves along corridors
- [ ] Active discussions have visual/audio cues (light, sound)
- [ ] Existing node creation flow works (creates new room/door)
- [ ] Corridor layout reflects existing nodes in meaningful way
- [ ] Mobile-friendly navigation
- [ ] Performance stays lightweight (no 3D engine required)

## Technical Details
### Approach
- Keep 2D implementation (SVG or Canvas)
- Fake perspective with CSS transforms or parallax
- Map existing nodes to corridor positions
- Reuse existing node LiveView for room interiors

### Key Design Decisions
- First-person or top-down corridor view?
- How do corridors branch? (topic-based wings?)
- How does node creation translate to corridor? (new door appears?)
- Transition animation: corridor → room

### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` → corridor_live.ex
- `assets/js/app.js` - navigation controls
- `assets/css/app.css` - corridor styling
- New: corridor rendering components

## Dependencies
### Reuses
- Node creation system
- Node chat/room interior (node_live.ex)
- Presence system
- Grok node generation

## Context
See [[T-2025-019-context]] for detailed design exploration.

## Notes
- Inspired by Severance's endless white corridors
- Should feel discoverable, not overwhelming
- Preserve "found a nook" feeling from original vision
