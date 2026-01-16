---
type: task
id: T-2025-010
status: completed
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Enhanced Node Chat Room Visualization

## Task Details
**Task ID**: T-2025-010-enhanced-node-chat-viz
**Status**: Completed
**Priority**: P1
**Branch**: feat/T-2025-010-enhanced-node-chat-viz
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**: 2026-01-16

## Description
Improve the visual experience of node chat rooms. Key enhancements:

1. **Diamond avatars at bottom**: Row of user glyphs showing who's present
2. **Better message presentation**: Not a traditional chat box
3. **Spatial feeling**: Messages appear in space, not a list
4. **Activity indicators**: See who's typing, who's active

This is about making the room feel like a *place*, not a chat app.

## Acceptance Criteria
- [x] Presence display shows all users in room (diamond/glyph row at bottom)
- [x] Messages styled to feel spatial (Lumon aesthetic, option 3)
- [x] Active users have visual indicator (glow, pulse, resonance-based opacity)
- [x] Typing indicator works
- [x] Overall vibe matches Gridroom aesthetic

## Checklist
- [x] Design presence row (diamond avatars)
- [x] Implement presence row component
- [x] Redesign message display (styled list with spatial feel)
- [x] Add typing indicator
- [x] Add active/idle visual states for users (resonance-based)
- [x] Animation and polish pass

## Technical Details
### Approach
**Presence Row**:
- Fixed position at bottom of node room
- Each user = diamond shape with their glyph color
- Click to see user info (activity sidebar later)
- Glow/pulse when user sends message

**Message Display Options**:
1. Floating messages that fade (ephemeral feel)
2. Messages positioned near user who sent them
3. Classic list but styled to feel spatial

**Activity Indicators**:
- Typing: small animation on user's diamond
- Active: bright, sharp edges
- Idle: faded, soft edges

### Files to Modify
- `lib/gridroom_web/live/node_live.ex` - presence display, message rendering
- `lib/gridroom_web/components/` - new presence row component
- CSS/Tailwind for animations

## Dependencies
### Blocked By
- None (can start now)

### Blocks
- [[E-2025-002-social-friends-system]] - presence row is foundation for friend features

## Context
See [[T-2025-010-context]] for detailed implementation notes.

## Notes
- MVP from VISION.md: "Messages appear in the space, not a traditional chat box"
- The presence row (diamonds) is the foundation for social features
- This task has high visual impact - prioritize aesthetic
