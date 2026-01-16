---
type: task
id: T-2025-012
status: backlog
priority: p2
created: 2026-01-16
updated: 2026-01-16
---

# Task: Node Creation Cost by Proximity

## Task Details
**Task ID**: T-2025-012-node-creation-cost-proximity
**Status**: Backlog
**Priority**: P2
**Branch**: feat/T-2025-012-node-creation-cost-proximity
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Creating nodes costs more in "busy" areas (near active nodes) and less in empty areas. This creates organic incentives:
- Spread out to explore new territory (cheap)
- Pay premium to be near the action (expensive)
- Prevents clustering without hard limits

## Acceptance Criteria
- [ ] Node creation has energy cost
- [ ] Cost increases near active/popular nodes
- [ ] Cost decreases in empty grid areas
- [ ] User sees cost before confirming creation
- [ ] Cost formula is balanced and intuitive

## Checklist
- [ ] Define cost formula (distance-based? activity-based?)
- [ ] Integrate with energy system (T-2025-011)
- [ ] Calculate cost in node creation flow
- [ ] Display cost in creation UI
- [ ] Test cost variations across grid

## Technical Details
### Approach
**Cost Factors**:
1. Distance to nearest N nodes
2. Activity level of nearby nodes (messages/day)
3. Base cost + multiplier

**Formula Sketch**:
```elixir
base_cost = 10
nearby_nodes = Nodes.within_radius(x, y, 100)
activity_factor = Enum.sum(nearby_nodes, & &1.message_count_24h) / 100
distance_factor = min(1, closest_distance / 50)

cost = base_cost * (1 + activity_factor) * (2 - distance_factor)
```

**Example**:
- Empty area: 10 energy (base)
- Moderately busy area: 20-30 energy
- Right next to hot node: 50+ energy

### Files to Modify
- `lib/gridroom/nodes.ex` - add cost calculation
- `lib/gridroom_web/live/grid_live.ex` - display cost in creation UI
- Requires energy system from T-2025-011

## Dependencies
### Blocked By
- [[T-2025-006-node-creation-system]] - basic creation first
- [[T-2025-011-portal-system]] - energy system

### Blocks
- None

## Context
See [[T-2025-012-context]] for detailed implementation notes.

## Notes
- This is a "game design" task - needs balancing and testing
- Start with simple formula, tune based on behavior
- Consider: show "cost heatmap" overlay on grid?
