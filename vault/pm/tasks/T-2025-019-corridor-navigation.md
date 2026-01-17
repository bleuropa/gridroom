---
type: task
id: T-2025-019
status: completed
priority: p1
created: 2026-01-16
updated: 2026-01-17
completed: 2026-01-17
---

# Task: Lumon Terminal Emergence Interface

## Task Details
**Task ID**: T-2025-019
**Status**: Completed
**Priority**: P1 (High)
**Branch**: feat/T-2025-019-corridor-navigation
**Created**: 2026-01-16
**Completed**: 2026-01-17

## Description

Replace the current 2D canvas grid view with a Severance-inspired terminal interface.

**Design Pivot**: Originally planned as a scrolling text stream, the design evolved into an "emergence" interface where discussions appear one at a time from the void. Users curate through rejection - keeping what interests them, dismissing what doesn't.

Key experience:
- Lumon terminal aesthetic (eerie, deliberate, minimal)
- Emergence-style discovery (one discussion at a time, fading in from void)
- Bucket system for saving discussions (max 6)
- Keybind-driven interaction
- Heavy, smooth animations with blur effects

## Acceptance Criteria
- [x] Emergence-style discovery (discussions appear one at a time)
- [x] Lumon aesthetic with subtle glow and heavy animations
- [x] Bucket slots at bottom (6 max) to save discussions
- [x] Space to keep current discussion, X to skip
- [x] Keybinds 1-6 to enter bucketed discussions directly
- [x] C to clear all buckets
- [x] H for help overlay
- [x] DB-backed bucket persistence (survives refresh)
- [x] Decay filtering (gone discussions auto-removed from buckets)
- [x] Empty state message when all topics reviewed
- [x] Existing node creation accessible via N key

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
