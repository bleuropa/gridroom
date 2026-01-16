---
type: task
id: T-2025-016
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Grid Canvas Navigation Improvements

## Task Details
**Task ID**: T-2025-016-grid-canvas-navigation
**Status**: In Progress
**Priority**: P1
**Branch**: feat/T-2025-016-grid-canvas-navigation
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
Improve the canvas/grid experience to feel more like genuine spatial traversal. Currently clicking a node immediately opens the chat view, which breaks the sense of exploration. The goal is to create a more immersive navigation experience where:

1. Users can zoom out to see all nodes at once (bird's eye view)
2. Clicking a node doesn't immediately open chat - instead provides preview/selection
3. Movement across the canvas feels more deliberate and exploratory
4. The transition into a node chat is a conscious "entering" action

## Checklist
- [ ] Implement zoom out functionality to see full grid
- [ ] Change node click behavior from "enter" to "select/preview"
- [ ] Add node preview panel showing title, description, activity
- [ ] Create explicit "Enter" action to open node chat
- [ ] Improve pan/zoom feel for canvas traversal
- [ ] Add visual feedback for selected vs unselected nodes
- [ ] Consider minimap or navigation aids

## Technical Details
### Approach
- Modify GridLive click handler to select rather than navigate
- Add selected node state and preview component
- Implement zoom controls (scroll wheel, pinch, buttons)
- Adjust viewport bounds to allow zooming out further
- Add "Enter node" button or double-click to enter

### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` - Node selection, preview panel
- `assets/js/hooks/grid_canvas.js` - Zoom/pan improvements
- `assets/css/app.css` - Preview panel styling, selection states

### Testing Required
- [ ] Manual testing of zoom levels
- [ ] Test node selection vs entry flow
- [ ] Test preview panel displays correct info
- [ ] Verify smooth canvas navigation

## Context
See [[T-2025-016-context]] for detailed implementation notes.

## Notes
- This changes a core interaction pattern - clicking nodes
- May want keyboard shortcuts (Enter to enter selected node)
- Consider mobile touch gestures
