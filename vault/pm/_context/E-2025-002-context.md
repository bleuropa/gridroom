# Context: E-2025-002 Social & Friends System

**Epic**: [[E-2025-002-social-friends-system]]
**Created**: 2026-01-16
**Status**: Planning

## Overview

Building a social layer that enhances Gridroom's mysterious, tavern-like atmosphere. The goal is "regulars have their corners" - people recognize each other, can find each other, but it's not a traditional social network.

## Design Philosophy

### The Tavern Analogy
- You notice the same shapes at your favorite nodes
- Over time, you recognize them before knowing names
- You can nod across the room (fast travel to say hi)
- The bartender (system) remembers who talks to who

### What This Is NOT
- Not a social network with profiles
- Not a follower count game
- Not about building public reputation
- Not about DMs or private chat

## Data Model Sketch

```elixir
# Connections table
connections
- id
- user_id (who initiated)
- friend_id (the other user)
- formed_in_node_id (where they met)
- created_at

# User activity (for sidebar)
user_node_visits
- id
- user_id
- node_id
- visited_at
- duration_seconds (optional)
```

## UX Concepts

### Adding a Friend (in-node)
- Click on a user's glyph in the node room
- Option appears: "Remember this traveler"
- They appear in your "known travelers" list
- Subtle - not a big friend request flow

### Seeing Friends on Grid
- Friends have a subtle glow or different outline
- Maybe a faint "connection line" to you if nearby
- Don't clutter the grid - only show closest N friends

### Fast Travel
- Keyboard shortcut or button: "Warp to friend"
- Select from nearby friends or list
- Smooth camera pan to their location
- Costs nothing (or minimal "energy" if we add economy)

### Activity Sidebar
- Click any user glyph → sidebar slides in
- Shows: their glyph, recent nodes visited
- "This traveler was recently at: [Node A], [Node B]"
- Maybe: shared nodes (places you both visited)

### Presence in Node Room
- Bottom of node room: row of diamond avatars
- Each diamond = a user present in this node
- Glows/pulses when they're actively chatting
- Click to see their activity sidebar

## Implementation Order

1. **T-2025-010**: Node room presence display (diamonds) - Visual foundation
2. **T-2025-006**: Friends from discussions - Core relationship system
3. **T-2025-009**: User activity sidebar - Discovery feature
4. **T-2025-008**: Friends visible on grid - Grid enhancement
5. **T-2025-007**: Fast travel to friends - Navigation feature

## Open Questions

1. **Mutual vs one-way?**
   - One-way: "I'm watching this person" (simpler, can be creepy)
   - Mutual: Both must connect (more friction, but clearer relationship)
   - Leaning: One-way but call it "remember" not "follow"

2. **Privacy controls?**
   - Can you hide your location from friends?
   - Can you go invisible entirely?
   - Block specific users?

3. **Activity privacy?**
   - Does everyone see where you've been?
   - Or only people you've explicitly connected with?

## Next Steps

1. Pick first task to implement
2. Design database schema
3. Mock up the node room presence UI
