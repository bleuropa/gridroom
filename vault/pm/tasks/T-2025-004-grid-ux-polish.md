---
type: task
id: T-2025-004
status: in-progress
priority: p1
created: 2025-01-15
updated: 2025-01-15
---

# Task: Grid UX Polish - Camera, Fog of War, Activity Visualization

## Task Details
**Task ID**: T-2025-004
**Status**: Todo
**Priority**: P1
**Branch**: feat/T-2025-004-grid-ux-polish
**Created**: 2025-01-15

## Description
Improve the Gridroom grid experience with three interconnected enhancements:

1. **Camera Following** - Viewport should gracefully follow the player during WASD movement, so you never lose sight of your glyph
2. **Fog of War** - Unexplored areas are dimmed/hidden, visiting nodes illuminates regions, interaction intensity affects illumination
3. **Activity Visualization** - Rethink the green activity dots, better represent what activity means and how to convey it visually

## Acceptance Criteria
- [ ] Player glyph always remains visible during WASD movement
- [ ] Canvas smoothly follows player (not jarring/instant)
- [ ] Unexplored areas have reduced visibility
- [ ] Visiting a node illuminates surrounding area
- [ ] Longer/more interaction = stronger illumination
- [ ] Activity indicators are intuitive and aesthetically pleasing
- [ ] Activity levels clearly communicate node state

## Components

### 1. Camera Following
- Viewport follows player during movement
- Smooth easing/lerp for natural feel
- Optional: slight delay/lag for cinematic effect
- Manual pan should still work (temporarily disengages follow)

### 2. Fog of War
- Start with limited visibility around spawn
- Visiting nodes reveals surrounding area
- Revelation persists (stored per user session or DB)
- Consider gradient edges vs hard boundaries
- Interaction depth affects brightness

### 3. Activity Visualization Redesign
Current: Green dots (not working well)
Needed: Rethink what activity levels mean
- What are we measuring? (recency, volume, unique users, velocity)
- How to visualize? (glow, size, particles, sound?, animation speed)
- What matters to users discovering nodes?

## Technical Details
### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` - camera logic, fog rendering
- `assets/js/app.js` - smooth camera follow in JS hook
- `assets/css/app.css` - fog effects, activity styling
- `lib/gridroom/grid.ex` - activity calculation logic
- Potentially: user schema for exploration state

## Context
See [[T-2025-004-context]] for detailed planning and design decisions.

## Notes
- User feedback: "green dots" not satisfying
- Camera following should feel natural, not robotic
- Fog of war adds mystery/discovery element
