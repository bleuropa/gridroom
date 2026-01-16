---
type: task
id: T-2025-014
epic: E-2025-002
status: completed
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: User Profile Sidebar & Friending

## Task Details
**Task ID**: T-2025-014-user-profile-sidebar-friending
**Epic**: [[E-2025-002-social-friends-system]]
**Status**: Completed
**Priority**: P1
**Branch**: feat/T-2025-014-user-profile-sidebar
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**: 2026-01-16

## Description
When you click on a user's diamond in the presence row, a sidebar slides in showing:
1. Their glyph and username
2. Recent nodes they've visited
3. Option to "remember" (friend) them

This creates organic social discovery - you notice someone in a conversation, click to learn more, and can choose to follow their presence on the grid.

## Acceptance Criteria
- [x] Clicking diamond in presence row opens sidebar
- [x] Sidebar shows user glyph, username, "present since" time
- [x] Sidebar shows recent nodes visited (last 5-10)
- [x] "Remember this traveler" button to add as friend
- [x] Friends table in database
- [x] Can unfriend from sidebar
- [x] Sidebar has Lumon styling

## Checklist
- [x] Create friendships/connections migration
- [x] Create Friendships context
- [x] Track user node visits (for activity history)
- [x] Build user profile sidebar component
- [x] Click handler on presence diamonds
- [x] Friend/unfriend actions
- [x] Style sidebar in Lumon aesthetic

## Additional Work Completed
- Recognition highlighting: remembered users glow amber in presence row
- Messages from remembered users have subtle amber accent
- Enhanced Lumon-style chat interface throughout
- Fixed message input clearing on submit

## Technical Details
### Database
```
connections (or friendships)
- id
- user_id (who initiated)
- friend_id (who they're following)
- created_at
- met_in_node_id (optional - where they met)

user_node_visits
- id
- user_id
- node_id
- visited_at
```

### UI
- Sidebar slides from right (like node creation)
- Shows diamond glyph large
- Username (or "Anonymous traveler" if none)
- "Here for X minutes"
- Recent activity: list of node titles
- Remember/Forget button

## Dependencies
### Blocked By
- [[T-2025-010-enhanced-node-chat-viz]] ✅ (presence diamonds)

### Blocks
- Fast travel to friends
- Friends visible on grid

## Context
See [[T-2025-014-context]] for detailed implementation notes.

## Notes
- Keep it one-way ("remembering" not mutual friendship)
- Activity should feel like discovery, not surveillance
- Fits the Severance vibe of "discovering connections"
