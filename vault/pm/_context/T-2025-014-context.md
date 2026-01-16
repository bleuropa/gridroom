# Context: T-2025-014 User Profile Sidebar & Friending

**Task**: [[T-2025-014-user-profile-sidebar-friending]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Click a user's diamond → sidebar shows their profile and activity. Option to "remember" them (one-way friend).

## Key Decisions

- One-way following ("remember") not mutual friendship
- Track node visits for activity history
- Sidebar slides from right, Lumon styling
- "Remember this traveler" / "Forget" terminology

## Implementation Plan

1. Create migrations (connections + user_node_visits)
2. Create Connections context
3. Track visits when entering nodes
4. Build sidebar component
5. Wire up click handlers
6. Add friend/unfriend actions

## Data Model

```elixir
# connections table
user_id -> users (follower)
friend_id -> users (being followed)
met_in_node_id -> nodes (optional)

# user_node_visits table
user_id -> users
node_id -> nodes
visited_at
```

## Next Steps

1. Generate migrations
2. Create Connections context module
3. Add visit tracking to NodeLive mount
