# Context: T-2025-026 User Discussion Creation

**Task**: [[T-2025-026-user-discussion-creation]]
**Created**: 2026-01-17
**Status**: In Progress

## Overview

Currently the app has no way for users to create their own discussion topics. The "n" key opens a legacy canvas view that's no longer part of the UI. We need to:

1. Remove/disable the old canvas code
2. Add a way for users to create discussion nodes
3. Provide a dedicated space for user-created discussions (7th bucket concept)

## Current State

- Pressing "n" opens old canvas view (legacy code)
- Discussions come from AI-generated folder content (Sports, Gossip, Tech, etc.)
- Users can only join existing discussions, not create new ones
- 6 bucket slots currently available

## Proposed Design

### 7th Bucket Concept
Instead of mixing user discussions with AI-generated ones, create a dedicated "My Topics" or "+" bucket:
- Always visible as 7th slot
- Shows user-created discussions
- Could also show discussions the user has created across the app

### Alternative: Inline Creation
- Add a "+" button in the terminal interface
- Opens modal to create new discussion
- New discussion gets added to user's buckets automatically

## Key Decisions

- **7th bucket vs inline creation**: TBD - need to explore current UI
- **User discussion decay**: Should they decay like AI-generated ones?
- **Creation limits**: Any limits on number of discussions per user?

## Open Questions

1. Where should "create discussion" UI live?
2. Should user discussions appear in folders or be separate?
3. What metadata do user discussions need? (just title? description?)
4. Should there be categories for user discussions?

## Implementation Plan

### Phase 1: Audit & Cleanup
1. Find and understand the "n" key handler and canvas code
2. Identify what can be removed vs repurposed
3. Clean out legacy code

### Phase 2: Create Discussion UI
1. Add create discussion modal/form
2. Wire to Grid.create_node
3. Auto-add to user's buckets

### Phase 3: User Discussions Space
1. Implement 7th bucket or equivalent
2. Show user's created discussions
3. Polish UI

## Next Steps

1. Review plan with user
2. Run `/s T-2025-026` to start work

## Auto-saved State (2026-01-17 16:44)

Recent commits:
- chore: start work on T-2025-026
- chore: create task T-2025-026
- fix: Allow inviting any user to pod by username

**Note**: This entry was auto-generated before memory compaction.

## Completion Notes

**Completed**: 2026-01-18
**Outcome**: Implemented dedicated user discussion slots (7-8) with creation modal, plus "Peer Contributions" community folder for discovering other users' discussions.

### What Was Built
1. **Slots 7-8**: Dedicated amber/gold styled slots for user-created discussions (max 2)
2. **Create Discussion Modal**: "n" key opens modal with title/description fields
3. **Peer Contributions Folder**: Community folder showing other users' discussions
   - 4 random from recent (48h) + 4 weighted by engagement
   - Refreshes 3x daily (every 8 hours)
   - Excludes viewer's own discussions

### Key Design Decisions
- Slots 1-6 remain for AI-generated/discovered discussions (sage green)
- Slots 7-8 for user's own creations only (amber/gold)
- User discussions decay same as AI-generated ones
- No resonance cost for now (could add later)

All acceptance criteria met. Task closed.

