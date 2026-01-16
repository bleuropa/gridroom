---
type: task
id: T-2025-017
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Resonance Presence & Node Decay

## Task Details
**Task ID**: T-2025-017-resonance-presence-node-decay
**Status**: In Progress
**Priority**: P1
**Branch**: feat/T-2025-017-resonance-presence-node-decay
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
Make resonance ever-present in the user's experience and add node decay to keep the grid alive.

### Part 1: Persistent Resonance
- Always show resonance meter in corner of grid screen
- Toast notifications when resonance changes ("+2 affirmed", "-3 dismissed")
- Visual feedback on your own glyph based on resonance level
- State whispers: periodic subtle messages about resonance state
- Low resonance warning with visual treatment

### Part 2: Node Decay
- Nodes with no activity slowly fade over time
- Dormant nodes (0 messages in 7 days) become "fading"
- Fading nodes (0 messages in 14 days) disappear
- Active nodes stay vibrant
- Visual treatment for fading nodes (transparency, desaturation)

## Checklist
- [ ] Add persistent resonance meter to grid view
- [ ] Implement resonance change toast notifications
- [ ] Add resonance-based effects to player glyph
- [ ] Add periodic state whispers
- [ ] Implement low resonance warning
- [ ] Add decay tracking to nodes (last_activity_at field)
- [ ] Create decay calculation logic
- [ ] Visual treatment for fading nodes
- [ ] Background job or check to clean up dead nodes

## Technical Details
### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` - Resonance meter, toasts
- `lib/gridroom/grid/node.ex` - Decay fields
- `lib/gridroom/grid.ex` - Decay logic
- `assets/css/app.css` - Toast animations, fading node styles
- Migration for decay tracking

## Context
See [[T-2025-017-context]] for detailed implementation notes.
