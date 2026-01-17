---
type: task
id: T-2025-024
status: in-progress
priority: p2
created: 2026-01-17
updated: 2026-01-17
---

# Task: Streaming Messages with Lazy Loading

## Task Details
**Task ID**: T-2025-024
**Status**: In Progress
**Priority**: P2 (Medium)
**Branch**: feat/T-2025-024-streaming-messages-pagination
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**:

## Description
Implement efficient message loading for discussions with many messages. Instead of loading all messages at once (which won't scale for 1k+ messages), load the most recent messages first and lazy-load older messages as the user scrolls up.

This leverages Phoenix LiveView's streaming capabilities (streams) for efficient DOM updates and memory management.

## Checklist
- [ ] Research Phoenix LiveView streams for infinite scroll
- [ ] Update message queries to support cursor-based pagination
- [ ] Implement initial load (most recent N messages)
- [ ] Add scroll-up detection in client JS
- [ ] Implement `stream_insert` for prepending older messages
- [ ] Handle edge cases (no more messages, loading states)
- [ ] Test with large message counts

## Technical Details
### Approach
- Use LiveView `stream/3` for message list (efficient DOM patching)
- Cursor-based pagination using message timestamps or IDs
- Load ~50 messages initially, fetch ~25 more on scroll
- Reverse chronological order (newest at bottom)
- `phx-viewport-top` hook to detect scroll to top

### Key LiveView Features
- `stream/3` - Efficient collection rendering
- `stream_insert/3` with `at: 0` - Prepend older messages
- `phx-viewport-top` / `phx-viewport-bottom` - Scroll detection
- Async loading to avoid blocking UI

### Files to Modify
- `lib/gridroom_web/live/node_live.ex` - Message streaming logic
- `lib/gridroom/grid.ex` - Paginated message queries
- `assets/js/app.js` - Scroll detection hooks

### Testing Required
- [ ] Manual testing with 1k+ messages
- [ ] Verify scroll position maintained after load
- [ ] Test rapid scrolling edge cases

## Dependencies
### Blocked By
- None

### Blocks
- None

## Context
See [[T-2025-024-context]] for detailed implementation notes.

## Commits
-

## Review Checklist
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debugger statements
- [ ] Security considerations addressed

## Notes
- Chris McCord has demoed this pattern for infinite scroll in LiveView
- Key is maintaining scroll position when prepending content
- Consider debouncing scroll events to avoid excessive server calls
