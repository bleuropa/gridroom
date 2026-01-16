# Context: T-2025-003 Gridroom MVP

**Task**: [[T-2025-003-gridroom-mvp]]
**Created**: 2025-01-15
**Status**: Planning

## Overview

Build the core Gridroom experience - an infinite canvas where users explore as abstract shapes, discover topic nodes, and have conversations.

## Implementation Plan

### Phase 1: The Grid
1. Create `GridLive` LiveView as the main experience
2. Implement SVG-based infinite grid (simpler than Canvas for LiveView integration)
3. Add pan controls (mouse drag, touch)
4. Add zoom controls (scroll wheel, pinch)
5. Render subtle grid lines that extend infinitely

### Phase 2: User Presence
1. Session-based identity (assign glyph on first visit)
2. Store in session: shape type, color, session_id
3. Phoenix Presence to track all connected users
4. Broadcast position updates via PubSub
5. Render other users as glyphs on the grid

### Phase 3: Topic Nodes
1. Create Node schema (id, title, x, y, type, description)
2. Seed initial nodes for testing
3. Render nodes on grid as larger labeled shapes
4. Nodes are clickable - opens room view

### Phase 4: Conversation Rooms
1. Create Room schema (belongs_to Node)
2. Create Message schema (belongs_to Room, User)
3. Room view shows who's present + chat
4. Messages persist and load on room entry
5. Real-time message updates via PubSub

### Phase 5: The Vibe
1. Color palette: muted base, warm accents
2. Typography: clean, slightly retro
3. Animations: subtle breathing, smooth transitions
4. Empty states that feel pregnant, not lonely

## Key Files to Create

```
lib/gridroom_web/live/
├── grid_live.ex          # Main infinite grid experience
├── grid_live.html.heex   # Grid template
└── room_live.ex          # Conversation room view

lib/gridroom/
├── grid/
│   ├── node.ex           # Topic node schema
│   ├── room.ex           # Conversation room schema
│   └── message.ex        # Chat message schema
├── presence.ex           # Phoenix Presence wrapper
└── accounts/
    └── user.ex           # Session-based user

assets/
├── js/
│   └── hooks/
│       └── grid.js       # Pan/zoom/interaction hooks
└── css/
    └── grid.css          # Grid-specific styles
```

## Data Models

```elixir
# User (session-based)
%User{
  id: uuid,
  session_id: string,
  glyph_shape: enum(:circle, :triangle, :square, :diamond, :hexagon),
  glyph_color: string,
  inserted_at: datetime
}

# Node (topic on grid)
%Node{
  id: uuid,
  title: string,
  description: text,
  position_x: float,
  position_y: float,
  node_type: enum(:discussion, :question, :debate, :quiet),
  inserted_at: datetime
}

# Room (conversation space)
%Room{
  id: uuid,
  node_id: references(:nodes),
  inserted_at: datetime
}

# Message
%Message{
  id: uuid,
  room_id: references(:rooms),
  user_id: references(:users),
  content: text,
  inserted_at: datetime
}
```

## Open Questions

1. SVG vs Canvas? (Starting with SVG for LiveView simplicity)
2. How large is the initial viewable area?
3. What's the coordinate system? (0,0 at center?)
4. How do we handle very zoomed out views? (LOD?)

## Next Steps

1. Run `/s T-2025-003` to start work
2. Set up database schemas first
3. Build basic grid with pan/zoom
4. Add presence layer
5. Iterate on aesthetics throughout

## Auto-saved State (2026-01-15 20:57)

Recent commits:
- feat: implement Gridroom MVP (T-2025-003)
- chore: create task T-2025-003
- docs: add AI content seeding concept to vision

**Note**: This entry was auto-generated before memory compaction.

