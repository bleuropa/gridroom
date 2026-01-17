---
type: task
id: T-2025-019
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Lumon Terminal Stream Interface

## Task Details
**Task ID**: T-2025-019
**Status**: In Progress
**Priority**: P1 (High)
**Branch**: feat/T-2025-019-corridor-navigation
**Created**: 2026-01-16

## Description

Replace the current 2D canvas grid view with a Severance-inspired terminal interface. Discussions appear as scrolling text streams with varying font sizes based on activity. Users "bucket" discussions they want to follow and can quickly toggle between the stream view and active discussions.

Key experience goals:
- Lumon terminal aesthetic (scrolling text, green-on-dark vibes)
- Activity-driven discovery (font size = activity level)
- Bucket system for queuing discussions (like browser tabs)
- Seamless toggling between stream and discussion views
- Always-on awareness of activity even when in a discussion

## Acceptance Criteria
- [ ] Scrolling text stream showing all discussions
- [ ] Font size reflects discussion activity level
- [ ] Bucket slots at bottom (6 max) to save discussions
- [ ] Click discussion in stream to add to bucket
- [ ] Keybinds 1-6 to jump to bucketed discussions
- [ ] Spacebar toggles stream view ↔ current discussion
- [ ] Stream remains visible/updating when in discussion
- [ ] Existing node creation flow works
- [ ] Mobile-friendly (tap to bucket, swipe to toggle)

## Technical Details
### Approach
- Replace grid_live.ex with terminal_live.ex
- CSS for terminal aesthetic (monospace, subtle glow, scrolling)
- LiveView for real-time stream updates
- JS hooks for keybinds and smooth scrolling

### Key Design Decisions
- Stream scrolls automatically, pauses on hover
- Buckets persist in session (localStorage backup)
- Discussion overlay vs split view when active
- Font size ranges: small (quiet) → large (active)

### Files to Modify
- `lib/gridroom_web/live/grid_live.ex` → terminal_live.ex
- `assets/js/app.js` - keybinds, scroll behavior
- `assets/css/app.css` - terminal styling
- Modify node_live.ex for overlay/toggle integration

## Dependencies
### Reuses
- Node creation system
- Node chat/room interior (node_live.ex)
- Presence system
- Grok node generation

## Context
See [[T-2025-019-context]] for detailed design exploration.

## Notes
- Inspired by Severance's Lumon terminals
- Text-centric, activity-driven discovery
- Buckets = personal queue of interesting discussions
