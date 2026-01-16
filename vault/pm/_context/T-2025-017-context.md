# Context: T-2025-017 Resonance Presence & Node Decay

**Task**: [[T-2025-017-resonance-presence-node-decay]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Two related features to make the grid feel more alive:
1. Make resonance ever-present so users always know their standing
2. Make nodes decay so the grid stays fresh and active

## Part 1: Persistent Resonance

### Resonance Meter on Grid
- Small meter in bottom-left or top-right corner
- Shows current resonance level visually (bar or arc)
- Color changes based on level (red = depleted, amber = normal, gold = radiant)
- State text: "unstable", "wavering", "steady", "strong", "radiant"

### Change Toasts
- When resonance changes, show a toast notification
- "+2 Someone affirmed you" (green/gold tint)
- "-3 Someone dismissed you" (red tint)
- Auto-dismiss after 3 seconds
- Stack if multiple changes happen

### Player Glyph Effects
- Your own glyph on the grid reflects resonance
- Depleted: dim, slight red tinge
- Normal: standard brightness
- Elevated: subtle glow
- Radiant: golden aura

### State Whispers (Optional)
- Every few minutes, subtle message about state
- "Your resonance feels steady"
- Only when not in a node conversation

## Part 2: Node Decay

### Decay Rules
- Track `last_activity_at` on nodes (message sent or user visit)
- **Fresh**: Activity within 24 hours - full visibility
- **Quiet**: Activity 1-7 days ago - slightly faded
- **Fading**: Activity 7-14 days ago - significantly faded, "(fading)" label
- **Gone**: No activity 14+ days - removed from grid

### Visual Treatment
- Quiet nodes: 80% opacity
- Fading nodes: 50% opacity, desaturated colors, dashed border
- Show "(fading)" or "disappearing soon" on hover

### Cleanup
- On grid load, filter out nodes past decay threshold
- Or: background job that runs daily to delete dead nodes

## Implementation Order

1. Resonance meter on grid (quick win)
2. Change toasts with PubSub
3. Node decay fields + migration
4. Decay visual treatment
5. Player glyph effects
6. Optional: state whispers, cleanup job

## Open Questions

- Should node creators get a warning before their node decays?
- Can a node be "revived" with activity, or once fading always fading?
- Should system/seed nodes be exempt from decay?
