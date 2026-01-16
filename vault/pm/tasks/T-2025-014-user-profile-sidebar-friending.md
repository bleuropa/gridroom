---
type: task
id: T-2025-014
epic: E-2025-002
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Task: User Profile Sidebar & Friending

## Task Details
**Task ID**: T-2025-014-user-profile-sidebar-friending
**Epic**: [[E-2025-002-social-friends-system]]
**Status**: In Progress
**Priority**: P1
**Branch**: feat/T-2025-014-user-profile-sidebar
**Created**: 2026-01-16
**Started**: 2026-01-16
**Completed**:

## Description
When you click on a user's diamond in the presence row, a sidebar slides in showing:
1. Their glyph and username
2. Recent nodes they've visited
3. Option to "remember" (friend) them

This creates organic social discovery - you notice someone in a conversation, click to learn more, and can choose to follow their presence on the grid.

## Acceptance Criteria
- [ ] Clicking diamond in presence row opens sidebar
- [ ] Sidebar shows user glyph, username, "present since" time
- [ ] Sidebar shows recent nodes visited (last 5-10)
- [ ] "Remember this traveler" button to add as friend
- [ ] Friends table in database
- [ ] Can unfriend from sidebar
- [ ] Sidebar has Lumon styling

## Checklist
- [ ] Create friendships/connections migration
- [ ] Create Friendships context
- [ ] Track user node visits (for activity history)
- [ ] Build user profile sidebar component
- [ ] Click handler on presence diamonds
- [ ] Friend/unfriend actions
- [ ] Style sidebar in Lumon aesthetic

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
