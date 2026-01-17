# Context: T-2025-019 Corridor Navigation

**Task**: [[T-2025-019-corridor-navigation]]
**Created**: 2026-01-16
**Status**: Planning

## Overview

Replace the 2D canvas grid with a corridor/tunnel navigation metaphor inspired by Severance. Users walk through hallways, discovering discussion rooms behind doors. This creates a more immersive, mysterious experience while reusing all existing node functionality.

## Design Vision

### Core Experience
- Navigate through branching corridors
- Doors/alcoves lead to discussion rooms
- "What's down this hallway?" sense of mystery
- Warm lighting to balance sterile aesthetic
- Sound cues (murmurs) for active discussions

### Visual Reference
- Severance's MDR department corridors
- Clean, minimal, slightly unsettling
- But with warm light spilling from active room doorways
- Subtle environmental details (wall textures, floor patterns)

## Key Decisions

### View Perspective
Options:
1. **First-person corridor view** - Looking down the hallway, doors on sides
2. **Top-down maze view** - Bird's eye, see layout but lose immersion
3. **Side-scroller** - Walk left/right through cross-section

**Leaning toward**: First-person with simplified perspective (not full 3D)

### Corridor Structure
How do nodes map to corridors?
- **Linear**: One long hallway, rooms in order of creation/activity
- **Branching by topic**: Wings for different categories (from Grok topics)
- **Organic growth**: New rooms extend corridors naturally

### Navigation
- Arrow keys / WASD to walk
- Click on doors to enter
- Mini-map for orientation?

## Implementation Plan

### Phase 1: Basic Corridor Rendering
- [ ] Create corridor LiveView (replaces grid_live)
- [ ] Render simple corridor with perspective
- [ ] Place doors for existing nodes
- [ ] Basic walk controls

### Phase 2: Door/Room Integration
- [ ] Door visuals (open/closed, light spill)
- [ ] Click door → enter node (existing node_live)
- [ ] Exit room → return to corridor position
- [ ] Activity indicators on doors

### Phase 3: Polish & Discovery
- [ ] Corridor branching logic
- [ ] Sound cues for active rooms
- [ ] Ambient lighting effects
- [ ] Fog of war / unexplored areas
- [ ] New room creation flow

## Open Questions

1. How far can you see down a corridor? (performance vs mystery)
2. Do corridors loop or have dead ends?
3. How does presence work? (see other users in corridor?)
4. Mobile: swipe to navigate?

## Technical Notes

### Rendering Approach
- SVG with CSS transforms for perspective
- Or Canvas 2D with manual perspective math
- Avoid Three.js/WebGL - keep it lightweight

### State Management
- Current corridor position (x, y, facing direction)
- Visible doors based on position
- Corridor layout (generated from nodes)

## References
- Severance (Apple TV+) - MDR corridors
- Superliminal - perspective tricks
- Control - Oldest House architecture

## Next Steps

1. Sketch basic corridor view in Figma or on paper
2. Prototype minimal corridor rendering in LiveView
3. Test navigation feel before building full system
