# Gridroom Vision

> "What if a website was a living room, not a page?"

**Domain**: gridroom.io

---

## The Concept

Gridroom is a liminal space between a cozy fantasy tavern and the severed floor from Apple TV's Severance. It's a social platform where:

- Users explore an infinite, quiet grid
- Simple geometric shapes represent ideas, topics, and stances
- Other visitors appear as small glyphs - not avatars, just presence
- Clusters form where people gather around topics
- Lines connect related concepts - you can walk them
- "Rooms" emerge organically where conversation happens
- Your path through the space creates your identity (not a profile)

It feels like wandering a library that's also a pub after hours.

---

## The Living Grid: AI Content Seeding

The grid isn't just user-generated - it breathes on its own. New nodes trickle in continuously, seeded by AI that monitors the world's conversations.

### How It Works

**Source: xAI/Grok + X Trends**
- Use xAI's X Search API to find trending topics, conversations, debates
- Grok synthesizes what's being discussed into abstract node concepts
- New nodes appear on the grid organically, like mushrooms after rain

**The Seeding Rhythm**
- New nodes appear every few hours (not constant, feels organic)
- Some nodes are "hot" (trending now) - they glow warmer
- Some are "emergent" (building momentum) - subtle pulse
- Some are "evergreen" (perennial topics) - stable, anchored

**Node Generation**
- AI distills a trend into a concise topic/question
- Assigns it a position on the grid (near related nodes)
- Seeds initial context (a brief, mysterious description)
- Users discover and claim it through conversation

**Examples of Seeded Nodes**
- "The AI hiring question" (from tech discourse)
- "Sleep as resistance" (from wellness trends)
- "The third place is dead" (from urban commentary)
- "Vibes-based decision making" (from culture chatter)

### Why This Matters

1. **Solves cold start** - Grid is alive from day one
2. **Keeps it fresh** - Always something new to discover
3. **Reduces burden on users** - Don't need to create, just explore
4. **Connects to the world** - Grid reflects what humanity is thinking about
5. **Mystery** - "Where do these nodes come from?" adds to the vibe

### Technical: xAI Integration

```
xAI X Search API
├── Keyword search for trending topics
├── Semantic search for emerging themes
├── Date filtering for recency
└── Handle filtering for quality sources

Processing Pipeline:
1. Fetch trends/conversations from X via xAI
2. Grok synthesizes into node concepts
3. Check for duplicate/similar existing nodes
4. Position new node on grid (semantic proximity)
5. Publish with subtle "new" indicator
```

**API**: `https://api.x.ai/v1/responses` with X Search tool
**Model**: `grok-4-1-fast` for speed
**Frequency**: Cron job every 2-4 hours

---

## Aesthetic & Style Guide

### The Severance Energy
- Clean, almost sterile surface
- But underneath: warm, human, mysterious
- Numbers and shapes that *mean* something
- The deeper you go, the weirder it gets
- Discovering connections feels like finding secrets
- Lumon's MDR floor aesthetic: endless grids, colored zones, hidden depths

### The Tavern Energy
- Regulars have their corners
- Strangers can pull up a chair
- Conversations drift, merge, split
- You recognize shapes before you know names
- Cozy despite the abstraction
- Fantasy tavern warmth without literal fantasy graphics

### Visual Principles
- **Not graphically intense** - small shapes and concepts signify a lot
- **Endless grids** - but alive, breathing, not sterile
- **Connections visible** - lines, paths, relationships
- **Exploration rewarded** - the deeper you go, the more you find
- **Topics, convos, stances** - abstract but meaningful

### Color Palette
- Muted, desaturated base (Severance beige/gray)
- Warm accent colors for presence/activity (amber, soft gold)
- Cool accents for structure/paths (subtle blue-gray)
- Pops of color where life happens (conversations, clusters)

### Typography
- Clean, readable, slightly retro-modern
- Monospace for system elements
- Serif or humanist sans for warmth in content

### Animation
- Subtle, breathing movements
- Shapes pulse gently when active
- Smooth panning/zooming
- Nothing jarring or flashy

---

## MVP Scope (Prototype v1)

### Core Features

#### 1. Infinite Pannable Grid
- 2D canvas that extends in all directions
- Smooth pan with mouse drag or touch
- Zoom in/out to see more detail or broader view
- Grid lines subtle but present

#### 2. User Presence as Glyphs
- Each user is a simple geometric shape (circle, triangle, square, etc.)
- Shape assigned on first visit (or chosen?)
- See other users' glyphs in real-time
- Subtle animation shows "alive" state
- No usernames visible by default (mystery first)

#### 3. Topic Nodes
- Fixed points on the grid representing ideas/topics
- Slightly larger shapes with labels
- Click to "enter" the node
- Nodes can be created by users (or seeded initially)

#### 4. Conversation Rooms
- Entering a node opens a chat-like space
- See who else is in the room (their glyphs)
- Simple text-based conversation
- Messages appear in the space, not a traditional chat box
- Room persists - conversations have history

#### 5. The Vibe
- Must feel mysterious and inviting from first load
- Sound design: subtle ambient (optional, off by default)
- Loading states feel intentional, not broken
- Empty space feels pregnant with possibility, not lonely

### Technical MVP Requirements
- Phoenix LiveView for all real-time updates
- Phoenix Presence for tracking who's where
- Canvas or SVG for grid rendering
- PostgreSQL for nodes, rooms, messages
- No authentication required initially (anonymous exploration)
- Session-based identity (shape persists for session)

---

## Beyond MVP: Future Phases

### Phase 2: Identity & Persistence
- Optional accounts (claim your glyph permanently)
- Your path history visualized (where you've been)
- "Home corner" - a space that's yours
- Reputation through presence (not likes/follows)

### Phase 3: Rich Nodes
- Nodes can contain more than conversation
  - Shared documents/notes
  - Embedded media (links, images)
  - Polls/votes on stances
- Node types: Discussion, Question, Debate, Quiet
- Node moderation by proximity regulars

### Phase 4: The Map Evolves
- Popular nodes grow larger
- Abandoned nodes fade (but don't disappear)
- Connections form automatically between related topics
- "Neighborhoods" emerge from clusters
- Seasonal events that reshape the map

### Phase 5: Spatial Stances
- Your position relative to nodes = your stance
- Between two opposing nodes = on the fence
- Move to express opinion without words
- Debate visualized as spatial tension

### Phase 6: Discovery & Exploration
- "Wander" mode - random exploration
- Breadcrumb trails from others (opt-in)
- "Regulars" of a node visible
- Node recommendations based on your path
- Secret rooms / easter eggs in far corners

### Phase 7: Creation Tools
- User-created nodes (with limits)
- Connection proposals (link two nodes)
- Room decoration (persistent doodles?)
- Glyph customization

### Phase 8: Multiplayer Experiences
- Synchronized events (everyone in a node at once)
- Collaborative drawing on the grid
- "Ceremonies" - structured group activities
- Watch parties for external content

---

## User Acquisition Strategy

### Why People Come
- "Come see what's happening" - FOMO on the living grid
- "Visit my corner" - shareable presence
- Novelty - nothing else like this on the web
- Cozy vibes - an antidote to social media anxiety

### Viral Mechanics
- Share a link to a specific node ("join this conversation")
- Share your glyph/location ("I'm here")
- Screenshot moments of beautiful chaos
- Word of mouth from the "this is weird and cool" factor

### Community Seeding
- Start with a small, curated set of topic nodes
- Invite specific communities (indie devs, writers, thinkers)
- Let emergent culture develop before scaling
- The first 100 users define the vibe

---

## Technical Architecture

### Stack
```
Frontend:
- Phoenix LiveView (real-time updates)
- Canvas API or SVG (grid rendering)
- Tailwind CSS (styling)
- Vanilla JS hooks for canvas interaction

Backend:
- Elixir/Phoenix 1.7+
- Phoenix Presence (who's where)
- PostgreSQL (persistence)
- PubSub for real-time updates

Infrastructure:
- Single server to start (Hetzner CPX31)
- Can scale horizontally with Phoenix clustering later
```

### Data Model
```
Users (session-based initially)
- id, session_id, glyph_shape, glyph_color, created_at

Nodes (topics/spaces)
- id, title, position_x, position_y, node_type, created_at, created_by

Messages
- id, node_id, user_id, content, created_at

Connections (between nodes)
- id, from_node_id, to_node_id, strength, created_at

Presence (ephemeral)
- user_id, position_x, position_y, current_node_id
```

---

## Open Questions

1. **Identity**: Fully anonymous? Session-based? Optional accounts?
2. **Scale**: How big should the initial grid be?
3. **Seeding**: What topics to start with?
4. **Moderation**: How to handle bad actors in an anonymous space?
5. **Mobile**: Touch-first or desktop-first?
6. **Sound**: Ambient audio on by default or opt-in?
7. **Onboarding**: Explain or let people discover?

---

## Inspiration & References

### Visual
- **Severance** (Apple TV) - The MDR floor, refinement screens
- **Dieter Rams** - Clean, functional, humane
- **Early internet** - Geocities soul, modern execution
- **r/place** - Collaborative chaos

### Conceptual
- **Are.na** - Collecting and connecting ideas
- **MUDs/MOOs** - Text-based spatial exploration
- **The Glass Bead Game** (Hesse) - Abstract intellectual play
- **Third places** - Neither home nor work
- **Liminal spaces** - Thresholds, in-between

### Technical
- **Figma** - Multiplayer cursors done right
- **Gather.town** - Spatial presence (but we skip the video)
- **Phoenix LiveView** - Our real-time foundation

---

## Taglines (Draft)

- "A room with infinite corners"
- "Where strangers become shapes"
- "The space between"
- "Wander. Gather. Speak."
