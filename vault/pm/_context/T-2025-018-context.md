# Context: T-2025-018 Grok API Trend-Based Node Creation

**Task**: [[T-2025-018-grok-api-trend-nodes]]
**Created**: 2026-01-16
**Status**: Planning

## Overview

Integrate xAI's Grok API to automatically discover trending topics and create nodes on the grid. This keeps the conversation landscape fresh and relevant without manual curation.

## Grok API Details

Reference: https://docs.x.ai/docs/guides/tools/search-tools

The Grok API provides search tools that can:
- Query real-time trending topics
- Search for specific subjects with live data
- Return structured results suitable for parsing

## Key Decisions

- **Naming**: System-generated nodes should feel "Lumon-like" - mysterious but inviting
- **Frequency**: How often to check for trends? (hourly? every 4 hours?)
- **Filtering**: What makes a trend "conversation-worthy"?
- **Positioning**: Where on the grid do auto-nodes appear?

## Implementation Plan

### Phase 1: API Client Setup
1. Add API key to runtime config
2. Create HTTP client module for Grok
3. Test basic connectivity

### Phase 2: Trend Fetching
1. Implement search query for trends
2. Parse response into structured data
3. Filter for conversation-worthy topics

### Phase 3: Node Generation
1. Transform trend into node title/description
2. Calculate grid position (avoid overlaps)
3. Create node via Grid context
4. Optionally tag as "trending" or "system-generated"

### Phase 4: Scheduling
1. GenServer or Oban job for periodic runs
2. Admin toggle to enable/disable
3. Rate limiting to prevent flood

## Open Questions

1. How to position auto-generated nodes? Random within bounds? Cluster near similar topics?
2. Should trend nodes have a different visual treatment?
3. How long should trend nodes live? Faster decay than user-created?
4. Should users be able to "pin" a trend node to prevent decay?

## Next Steps

1. Review plan with user
2. Fetch and review Grok API docs
3. Run `/s T-2025-018` to start work
