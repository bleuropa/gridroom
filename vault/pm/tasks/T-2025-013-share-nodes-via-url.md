---
type: task
id: T-2025-013
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Share Nodes via URL

## Task Details
**Task ID**: T-2025-013-share-nodes-via-url
**Status**: In Progress
**Priority**: P1
**Branch**: feat/T-2025-013-share-nodes-via-url
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
Users can share a direct URL to a node. Clicking the link takes you directly into that node's room. This is critical for viral growth and "join this conversation" sharing.

From VISION.md Viral Mechanics:
> "Share a link to a specific node ('join this conversation')"

## Acceptance Criteria
- [ ] Each node has a shareable URL
- [ ] URL can be copied easily (share button)
- [ ] Visiting URL takes user directly to node room
- [ ] Works for new visitors (creates session, then enters node)
- [ ] Good social preview (OG tags) when shared

## Checklist
- [ ] Generate URL-friendly node slugs/IDs
- [ ] Add share button to node room UI
- [ ] Implement direct node access route
- [ ] Handle new users landing on node URL
- [ ] Add OG meta tags for social sharing
- [ ] Test sharing flow end-to-end

## Technical Details
### Approach
**URL Structure Options**:
1. `/n/:slug` - e.g., `/n/the-ai-hiring-question`
2. `/node/:id` - e.g., `/node/abc123`
3. `/:slug` - e.g., `/the-ai-hiring-question` (cleanest but conflicts with other routes)

Recommend: `/n/:slug` for clarity and uniqueness.

**Share Flow**:
1. User in node room clicks "share" button
2. URL copied to clipboard
3. Toast confirms copy

**Landing Flow**:
1. New visitor hits `/n/the-ai-hiring-question`
2. Session created (glyph assigned)
3. Redirected into node room
4. Grid loads in background

**Social Preview**:
```html
<meta property="og:title" content="The AI Hiring Question - Gridroom">
<meta property="og:description" content="Join the conversation at Gridroom">
<meta property="og:image" content="/og/nodes/the-ai-hiring-question.png">
```

### Files to Modify
- `lib/gridroom_web/router.ex` - add `/n/:slug` route
- `lib/gridroom_web/live/node_live.ex` - direct access handling
- `lib/gridroom_web/controllers/page_controller.ex` - OG tag generation
- New: share button component

## Dependencies
### Blocked By
- None (can start now)

### Blocks
- None

## Context
See [[T-2025-013-context]] for detailed implementation notes.

## Notes
- This is MVP priority - sharing is how we grow
- Consider: can you share your current grid position too?
- OG images could be AI-generated for extra appeal
