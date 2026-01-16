# Context: T-2025-010 Enhanced Node Chat Room Visualization

**Task**: [[T-2025-010-enhanced-node-chat-viz]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Make node chat rooms feel like places, not chat apps. Key features:
- Diamond avatar presence row at bottom showing who's here
- Messages that feel spatial
- Activity indicators (typing, active/idle)

## Key Decisions

- Presence row: fixed at bottom, diamond glyphs
- Messages: keep list format but add spatial styling
- Use Phoenix Presence for real-time user tracking in nodes

## Implementation Notes

- Need to add Presence tracking to node rooms
- Each user's diamond pulses when they send a message
- Typing indicator broadcasts via PubSub

## Next Steps

1. Add Presence tracking to NodeLive
2. Build presence row component (diamonds at bottom)
3. Enhance message styling
4. Add typing indicator
