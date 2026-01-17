---
type: task
id: T-2025-020
story:
epic:
status: backlog
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: Discussion Page Severance Redesign

## Task Details
**Task ID**: T-2025-020-discussion-page-severance-redesign
**Story**:
**Epic**:
**Status**: Backlog
**Priority**: P1
**Branch**: feat/T-2025-020-discussion-page-severance-redesign
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Redesign the discussion/node view pages to align with the new Lumon MDR terminal aesthetic established in the emergence terminal. The discussion pages currently clash with the new Severance-inspired design and need to be updated to match the typography, colors, CRT atmosphere effects, and overall feel.

Additionally, add persistent bucket indicators so users can see and access their saved discussions while inside a discussion room.

## Checklist
- [ ] Update discussion page background to match Lumon terminal (scanlines, vignette, glow)
- [ ] Apply Severance typography (font-mono, warm phosphor colors)
- [ ] Style message display with terminal aesthetic
- [ ] Add persistent bucket indicators visible from discussion view
- [ ] Update input/compose area styling
- [ ] Ensure smooth transitions between terminal and discussion views

## Technical Details
### Approach
- Apply same CSS atmosphere classes from terminal to discussion pages
- Use consistent color palette (#e8e0d4 title, #a8a298 secondary, etc.)
- Add bucket bar component that persists across views
- Maintain readability while achieving immersive aesthetic

### Files to Modify
- `lib/gridroom_web/live/node_live.ex`
- `assets/css/app.css` (may need additional discussion-specific styles)
- Possibly create shared bucket component

### Testing Required
- [ ] Visual review of discussion pages
- [ ] Bucket navigation works from discussion view
- [ ] Messages remain readable with new styling
- [ ] Mobile responsiveness maintained

## Dependencies
### Blocked By
- None (builds on completed terminal redesign)

### Blocks
- None

## Context
See [[T-2025-020-context]] for detailed implementation notes.

## Commits
- (pending)

## Notes
- Should feel like the same terminal environment, just deeper into a discussion
- Buckets are the user's anchor - always visible, always accessible
