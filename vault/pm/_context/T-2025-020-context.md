# Context: T-2025-020 Discussion Page Severance Redesign

**Task**: [[T-2025-020-discussion-page-severance-redesign]]
**Created**: 2026-01-16
**Status**: Planning

## Overview

The emergence terminal now has a cohesive Severance MDR aesthetic - Lumon-style CRT atmosphere with scanlines, vignette, phosphor glow, warm terminal colors, and deliberate animations. The discussion/node pages need to match this aesthetic so the experience feels unified.

Key goals:
1. **Visual consistency** - Same atmosphere, colors, typography
2. **Bucket persistence** - Users should always see their 6 bucket slots
3. **Immersion** - Feel like you're deeper in the terminal, not in a different app

## Design Reference

From terminal implementation:
- Background: `lumon-terminal` gradient
- Overlays: `lumon-vignette`, `lumon-scanlines`, `lumon-glow`
- Title color: `#e8e0d4` with soft text-shadow
- Secondary color: `#a8a298`
- Font: `font-mono` (JetBrains Mono)
- Easing: `--ease-lumon` cubic-bezier curves

## Key Decisions

- Bucket bar should be at bottom like in terminal view
- Messages should feel like terminal output
- User input should feel like command line entry

## Implementation Plan

1. **Apply atmosphere to node_live.ex**
   - Add lumon-terminal, vignette, scanlines, glow layers
   - Update container structure

2. **Restyle message display**
   - Terminal-style message formatting
   - Warm phosphor colors
   - Subtle text shadows

3. **Add bucket indicators**
   - Same bucket bar component from terminal
   - Always visible at bottom
   - Clicking returns to terminal with that bucket selected

4. **Update input area**
   - Terminal-style input field
   - Match aesthetic

## Open Questions

- Should messages have timestamps visible or hidden?
- How prominent should the bucket bar be vs. the conversation?

## Next Steps

1. Run `/s T-2025-020` to start work
2. Explore current node_live.ex implementation
3. Apply atmosphere layers
4. Iterate on message styling

## Auto-saved State (2026-01-16 20:48)

Recent commits:
- chore: start work on T-2025-020
- chore: create task T-2025-020
- feat: Severance MDR terminal aesthetic overhaul

**Note**: This entry was auto-generated before memory compaction.

