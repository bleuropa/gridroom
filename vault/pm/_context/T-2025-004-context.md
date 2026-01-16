# Context: T-2025-004 Grid UX Polish

**Task**: [[T-2025-004-grid-ux-polish]]
**Created**: 2025-01-15
**Status**: Planning

## Overview

Three interconnected improvements to make the grid feel more immersive and discoverable:
1. Camera that follows the player
2. Fog of war for mystery/exploration
3. Better activity visualization

---

## 1. Camera Following

### Current Behavior
- WASD moves the player glyph in world space
- Viewport stays put unless manually panned
- Player can walk off-screen and become invisible

### Desired Behavior
- Viewport gracefully follows player during WASD movement
- Smooth interpolation (not instant snap)
- Manual pan (drag) temporarily disengages follow
- Pressing Space/C re-centers (already exists)

### Implementation Options

**Option A: Viewport follows player directly**
- Every move event also updates viewport to center on player
- Simple but might feel too rigid

**Option B: Viewport lerps toward player**
- Viewport has target = player position
- Each frame, viewport moves X% toward target
- Creates smooth, cinematic feel
- Needs JS-side animation loop

**Option C: Dead zone / follow box**
- Player can move freely within center region
- Viewport only moves when player approaches edge
- More "game-like" feel

### Open Questions
- How fast should camera follow? (immediate vs lazy)
- Should panning temporarily disable follow?
- Should zoom affect follow behavior?

---

## 2. Fog of War

### Concept
The grid starts mostly obscured. As you explore, you reveal areas. This creates:
- Mystery and discovery
- Reason to explore
- Visual reward for engagement

### Design Questions

**What triggers revelation?**
- Proximity to player (radius around glyph)
- Visiting a node (reveals node + surrounding area)
- Interacting in a node (stronger/permanent reveal)

**How does revelation work visually?**
- Gradient from visible to fog
- Hard boundary with soft edge
- Nodes glow through fog as beacons?

**Persistence?**
- Session only (resets on refresh)
- Stored in DB per user
- Shared across all users (collective exploration)

**Fog appearance?**
- Dark overlay with alpha gradient
- Blur effect on unexplored areas
- Desaturation + darkness
- Actual fog/mist particles (expensive)

### Technical Approach Ideas

**SVG Mask Approach**
- Create a `<mask>` element
- Add revealed circles for each explored area
- Apply mask to the entire grid content
- Performant, works well with SVG

**Canvas Overlay Approach**
- Separate canvas layer on top
- Draw fog with revealed holes
- More flexible but separate render layer

**CSS Filter Approach**
- Apply blur/darkness via CSS
- Use clip-path for revealed areas
- Simpler but less control

---

## 3. Activity Visualization Redesign

### Current Problems
- Green dots feel disconnected from the aesthetic
- Unclear what "activity" means
- Doesn't integrate with the warm/mysterious vibe

### What Should Activity Communicate?

**Possible metrics:**
1. **Recency** - When was the last message?
2. **Volume** - How many messages recently?
3. **Velocity** - How fast are messages coming?
4. **Unique users** - How many people participated?
5. **Your participation** - Have you been there?

**What matters to users?**
- "Is anyone here right now?" → Presence/live activity
- "Is this a popular topic?" → Historical engagement
- "Will someone respond if I speak?" → Recent activity

### Visual Ideas

**Instead of dots:**
- **Glow intensity** - More active = brighter glow
- **Animation speed** - Faster pulse = more active
- **Size/scale** - Active nodes slightly larger
- **Particle effects** - Subtle particles emanating from active nodes
- **Ring ripples** - Like the dwell indicator, ongoing ripples
- **Color temperature** - Warmer = more active, cooler = dormant
- **Sound cues** - Subtle ambient sounds for very active nodes (optional)

### Activity Levels (Proposed)

| Level | Meaning | Visual Treatment |
|-------|---------|------------------|
| **Dormant** | No activity in 24h | Dim, slow/no animation, cool tint |
| **Quiet** | Activity in last 24h | Normal brightness, gentle pulse |
| **Active** | Activity in last hour | Warm glow, visible pulse |
| **Live** | Activity in last 5min | Bright glow, fast pulse, subtle ripples |
| **Buzzing** | Multiple people active now | Intense glow, particles, warm color |

### Integration with Fog of War
- Active nodes could glow through the fog as beacons
- Helps users find interesting nodes even in unexplored areas
- Creates "pull" toward engagement

---

## Implementation Plan

### Phase 1: Camera Following
1. Add camera follow state (enabled/disabled)
2. Implement smooth lerp in JS
3. Viewport follows player position with delay
4. Pan temporarily disables, Space re-enables

### Phase 2: Activity Visualization v2
1. Define activity levels and thresholds
2. Replace green dots with glow-based system
3. Add animation speed variation
4. Test visibility and aesthetics

### Phase 3: Fog of War
1. Start with simple SVG mask approach
2. Track explored areas (in-memory first)
3. Reveal on proximity and node visit
4. Add persistence later (DB)

---

## Open Questions

1. **Camera follow speed** - How fast/slow feels right?
2. **Fog persistence** - Session vs permanent?
3. **Activity thresholds** - What defines "active"?
4. **Fog + activity interaction** - Can you see activity through fog?

---

## Next Steps

1. Discuss and refine design decisions
2. Start with camera following (most immediate pain point)
3. Iterate on activity visualization
4. Add fog of war as final layer
