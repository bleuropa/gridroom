---
type: task
id: T-2025-018
status: backlog
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Grok API Integration for Trend-Based Node Creation

## Task Details
**Task ID**: T-2025-018-grok-api-trend-nodes
**Status**: Backlog
**Priority**: P1
**Branch**: feat/T-2025-018-grok-api-trend-nodes
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Integrate the Grok API (xAI) to automatically discover trending topics and seed new nodes on the grid. This keeps the grid fresh with relevant, timely conversation starters without requiring manual node creation.

Uses Grok's search/live tools to:
- Query current trending topics
- Filter for conversation-worthy subjects
- Automatically create nodes with relevant titles and descriptions
- Position new nodes strategically on the grid

## Acceptance Criteria
- [ ] Grok API client configured and authenticated
- [ ] Trending topics fetched successfully via search tools
- [ ] New nodes created automatically with trend-based content
- [ ] Nodes positioned appropriately on the grid (not overlapping)
- [ ] Rate limiting to avoid spam-creating nodes
- [ ] Scheduling mechanism for periodic trend checks

## Checklist
- [ ] Set up Grok API credentials and configuration
- [ ] Create Grok API client module
- [ ] Implement trend fetching with search tools
- [ ] Build node generation logic from trend data
- [ ] Add positioning algorithm for new nodes
- [ ] Implement rate limiting / cooldown
- [ ] Create scheduled job (GenServer or Oban)
- [ ] Add admin controls to enable/disable
- [ ] Test with live API

## Technical Details
### Approach
- Use Grok's search tools API to find trending topics
- Parse and filter results for conversation-worthy topics
- Generate node title/description from trend data
- Use Grid context to create nodes programmatically
- Schedule via GenServer with `:timer.send_interval` or Oban

### API Reference
- Docs: https://docs.x.ai/docs/guides/tools/search-tools
- Need: API key configuration in runtime config
- Endpoint: Search/live tools for real-time trends

### Files to Create/Modify
- `lib/gridroom/grok/client.ex` - API client
- `lib/gridroom/grok/trend_fetcher.ex` - Trend parsing logic
- `lib/gridroom/grok/node_generator.ex` - Node creation from trends
- `lib/gridroom/grok/scheduler.ex` - Periodic job
- `config/runtime.exs` - API key config

### Testing Required
- [ ] Mock API responses for unit tests
- [ ] Integration test with real API (manual)
- [ ] Verify node creation doesn't overlap existing

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-018-context]] for detailed implementation notes.

## Notes
- Not for image generation - purely text/trend discovery
- Consider: node categories based on trend type
- Consider: expiration for trend-based nodes (auto-decay faster?)
- Lumon aesthetic for system-generated node descriptions
