---
type: task
id: T-2025-007
status: backlog
priority: p2
created: 2026-01-16
updated: 2026-01-16
---

# Task: Grid Territories & Node Classification

## Task Details
**Task ID**: T-2025-007-grid-territories-classification
**Status**: Backlog
**Priority**: P2
**Branch**: feat/T-2025-007-grid-territories-classification
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Introduce regions/zones on the grid with different rules or themes. Certain areas might only allow specific types of nodes, or have different visual treatment. This adds structure to the infinite grid and encourages exploration.

Concepts to explore:
- **Themed zones**: "Tech Corner", "Creative Quarter", "Quiet Zone"
- **Rules by territory**: Some areas only allow certain node types
- **Visual differentiation**: Subtle color shifts or patterns by region
- **Emergent territories**: Formed by node clustering vs predefined

## Acceptance Criteria
- [ ] Grid has defined regions/territories
- [ ] Territories have visual differentiation (subtle)
- [ ] Node creation respects territory rules (if applicable)
- [ ] Users can discover territory boundaries

## Checklist
- [ ] Design territory system (predefined vs emergent)
- [ ] Add territory schema to database
- [ ] Visual rendering of territory boundaries
- [ ] Territory-aware node creation rules
- [ ] Territory discovery UI (hover for name?)

## Technical Details
### Approach
Options:
1. **Predefined quadrants**: Simple, divide grid into sections
2. **Voronoi regions**: Territory forms around seed nodes
3. **Emergent clustering**: Analyze node types, auto-classify regions

### Files to Modify
- `lib/gridroom/territories.ex` - new context
- `lib/gridroom_web/live/grid_live.ex` - territory rendering
- Database migration for territories

## Dependencies
### Blocked By
- [[T-2025-006-node-creation-system]] - should have node creation first

### Blocks
- None

## Context
See [[T-2025-007-context]] for detailed implementation notes.

## Notes
- This aligns with "Phase 4: The Map Evolves" from VISION.md
- Start simple (predefined) before getting fancy (emergent)
- Territories should feel mysterious, not bureaucratic
