# Context: T-2025-019 Lumon Terminal Emergence Interface

**Task**: [[T-2025-019-corridor-navigation]]
**Created**: 2026-01-16
**Completed**: 2026-01-17
**Status**: Completed

## Overview

Replace the 2D canvas grid with a Severance-inspired terminal interface. Instead of spatial navigation, users discover discussions through a scrolling text stream. Activity drives visibility (larger text = more active). Users "bucket" discussions they want to track and toggle seamlessly between stream and discussion views.

## Design Vision

### Core Experience
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│    The AI hiring question                               │
│         "where does automation end..."                  │
│                                                         │
│              Sleep as resistance                        │
│                   "rest is radical"                     │
│    Digital gardens                                      │
│         "tend your corner..."                           │
│                        The loneliness epidemic          │
│              "connected but alone"                      │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│  [1] AI hiring  [2] Sleep  [3] Gardens  [ ] [ ] [ ]    │
└─────────────────────────────────────────────────────────┘
```

### Visual Reference
- Lumon terminal screens (green/amber text on dark)
- Scrolling stock ticker / airport departure boards
- Old BBS systems, but elegant
- Subtle CRT glow/scan lines optional

### Interaction Model
1. **Stream View**: Text scrolls continuously, showing all discussions
2. **Bucket**: Click a discussion to add it to your bucket bar (bottom)
3. **Enter**: Press 1-6 or click bucket to open that discussion
4. **Toggle**: Spacebar switches between stream and active discussion
5. **Awareness**: Stream keeps updating even when in a discussion

## Key Decisions

### Font Size = Activity
- Base size: 14px (quiet)
- Medium: 18px (some activity)
- Large: 24px (active conversation)
- Activity = messages in last N minutes + users present

### Bucket System
- 6 slots maximum
- Click discussion in stream → adds to first empty slot
- Click filled bucket → opens discussion
- Right-click bucket → removes from bucket
- Buckets saved to localStorage for persistence

### Stream Behavior
- Auto-scrolls upward (new items at bottom? or top?)
- Pauses on hover for easier clicking
- Items fade in/out smoothly
- Position varies (left/right offset for organic feel)

### Toggle Mechanics
- Spacebar when in discussion → back to stream (discussion stays bucketed)
- Spacebar when in stream with active bucket → open that discussion
- ESC always returns to stream

## Implementation Plan

### Phase 1: Basic Terminal Stream
- [ ] Create terminal_live.ex (replace grid_live)
- [ ] Render scrolling list of discussions
- [ ] Terminal CSS styling (dark bg, monospace, glow)
- [ ] Font size based on activity

### Phase 2: Bucket System
- [ ] Bucket bar UI at bottom
- [ ] Click to bucket functionality
- [ ] Keybinds 1-6 for bucket access
- [ ] localStorage persistence

### Phase 3: Discussion Integration
- [ ] Open discussion as overlay/split
- [ ] Spacebar toggle
- [ ] Stream continues in background
- [ ] Activity updates in real-time

### Phase 4: Polish
- [ ] Smooth animations
- [ ] Mobile support (tap, swipe)
- [ ] Node creation from terminal
- [ ] Sound cues (optional)

## Technical Notes

### LiveView Structure
- `terminal_live.ex` - main terminal view
- Subscribes to `grid:nodes` for real-time updates
- Manages bucket state in socket assigns
- Embeds or navigates to node_live for discussions

### Activity Calculation
```elixir
def calculate_activity(node) do
  recent_messages = count_messages_since(node, minutes_ago: 5)
  users_present = count_users_in_node(node)

  cond do
    recent_messages > 10 or users_present > 3 -> :high
    recent_messages > 3 or users_present > 1 -> :medium
    true -> :low
  end
end
```

### CSS Approach
- CSS custom properties for terminal colors
- `@keyframes scroll` for smooth movement
- `text-shadow` for subtle glow effect
- `backdrop-filter` for depth when overlaying

## Open Questions

1. Stream direction: new items appear at top or bottom?
2. How many discussions visible at once in stream?
3. Should discussions "pulse" when new message arrives?
4. Node creation: modal over terminal or dedicated view?

## Next Steps

1. Build minimal terminal_live.ex with static content
2. Add real node data with activity-based sizing
3. Implement bucket system
4. Integrate discussion toggle

## Completion Notes

**Completed**: 2026-01-17
**Outcome**: Successfully replaced canvas grid with Lumon-inspired terminal emergence interface.

### Design Pivot
The original plan for a scrolling text stream evolved through user feedback into an "emergence" interface:
- Discussions appear **one at a time** from the void
- Users curate through **rejection** (keep or skip)
- More mysterious and Lumon-like than the Reddit-style scrolling stream

### What Was Built
- **Emergence discovery**: Discussions fade in from void with blur effects
- **Bucket system**: 6 slots, DB-backed persistence, decay filtering
- **Keybind-driven**: space (keep), x (skip), 1-6 (enter), c (clear), h (help)
- **Heavy animations**: Custom easing curves, distinct keep vs skip animations
- **Empty state**: Lumon-style "all topics reviewed" message

### Key Files
- `lib/gridroom_web/live/terminal_live.ex` - Main emergence interface
- `assets/css/app.css` - Lumon animation system
- `lib/gridroom/accounts.ex` - Bucket persistence functions
- `priv/repo/migrations/*_add_bucket_ids_to_users.exs` - DB schema

### Future Considerations
- Mobile gestures (tap/swipe)
- Sound cues
- More node types beyond discussions

