# Context: T-2025-026 User Discussion Creation

**Task**: [[T-2025-026-user-discussion-creation]]
**Created**: 2026-01-17
**Status**: Planning

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
