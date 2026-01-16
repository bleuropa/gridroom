# Context: T-2025-016 Grid Canvas Navigation

**Task**: [[T-2025-016-grid-canvas-navigation]]
**Created**: 2026-01-16
**Status**: Planning

## Overview

The current grid interaction is too "instant" - clicking a node immediately navigates to the chat view. This breaks the sense of exploration and spatial traversal that makes the liminal space concept compelling.

The goal is to make the grid feel like a place you're *in*, not a menu you're clicking through.

## Current Behavior

1. User sees grid with nodes
2. Clicking any node → immediate navigation to `/node/{id}`
3. No ability to zoom out and see the whole landscape
4. No preview of what's in a node before entering

## Desired Behavior

1. User can zoom out to see entire node landscape
2. Clicking a node *selects* it (highlight, show preview)
3. Preview shows: title, description, activity level, who's there
4. Double-click or "Enter" button to actually navigate into node
5. Smoother pan/zoom that feels like traversing space

## Key Decisions

- **Click = Select, Double-click or Enter = Navigate**
- Preview panel placement: right sidebar or floating near node?
- Zoom limits: how far out? Far enough to see all nodes

## Implementation Plan

### Phase 1: Selection State
1. Add `selected_node_id` to socket assigns
2. Change click handler to select rather than navigate
3. Add visual selection indicator (ring, highlight)
4. Add double-click handler for navigation

### Phase 2: Preview Panel
1. Create preview component (title, description, activity, presence)
2. Position panel (floating or sidebar)
3. Add "Enter" button
4. Style in Lumon aesthetic

### Phase 3: Zoom Improvements
1. Adjust zoom bounds (allow zooming out further)
2. Smooth zoom transitions
3. Zoom to fit all nodes option
4. Consider zoom controls UI

## Open Questions

- Should there be a minimap?
- Keyboard navigation? (Arrow keys to move between nodes, Enter to enter)
- Animation when entering a node? (zoom in effect?)

## Next Steps

1. Review plan with user
2. Run `/s T-2025-016` to start work
