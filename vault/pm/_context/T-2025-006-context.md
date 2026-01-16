# Context: T-2025-006 Node Creation System

**Task**: [[T-2025-006-node-creation-system]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Allow authenticated users to create new topic nodes on the grid. This enables user-generated content and conversation starters.

## Key Decisions

- **UI Approach**: Modal or sidebar (user preference: modal or sidebar - to be decided)
- **Who can create**: Auth users only (for now)
- **Required fields**: Title only, optional description
- **Rate limiting**: TBD (start without, add if needed)

## Implementation Notes

### UI Options
1. **Modal** - Appears centered over grid, blocks interaction
   - Pros: Focused, clear call-to-action
   - Cons: Breaks spatial context

2. **Sidebar** - Slides in from right, grid remains visible
   - Pros: Maintains spatial awareness, can see where node will go
   - Cons: Takes more screen space

### Trigger Mechanism
- Right-click on empty grid space
- Or: Floating "+" button that appears when zoomed in enough

## Next Steps

1. Explore existing grid code to understand interaction patterns
2. Decide on modal vs sidebar
3. Implement the creation form
4. Wire up to backend
5. Broadcast via PubSub
