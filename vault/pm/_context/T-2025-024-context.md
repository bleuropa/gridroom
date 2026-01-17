# Context: T-2025-024 Streaming Messages with Lazy Loading

**Task**: [[T-2025-024-streaming-messages-pagination]]
**Created**: 2026-01-17
**Status**: Completed

## Overview

Currently, all messages in a node are loaded at once. This won't scale well when discussions have 1000+ messages. We need to implement efficient lazy loading using Phoenix LiveView streams.

**Goal**: Load most recent ~50 messages initially, then lazy-load ~25 older messages when user scrolls to top.

## Phoenix LiveView Streams

LiveView streams are the recommended approach for large collections:

```elixir
# In mount or handle_params
socket
|> stream(:messages, initial_messages)

# In template
<div id="messages" phx-update="stream">
  <div :for={{dom_id, message} <- @streams.messages} id={dom_id}>
    <%= message.content %>
  </div>
</div>
```

### Key Functions
- `stream/3` - Initialize stream
- `stream_insert/3` - Add item (`:at` option for position)
- `stream_delete/2` - Remove item
- `stream_reset/3` - Replace entire stream

### Scroll Detection
LiveView has built-in hooks for viewport detection:

```heex
<div id="messages"
     phx-viewport-top="load_more_messages"
     phx-viewport-bottom="at_bottom">
```

When element scrolls into viewport top, triggers `load_more_messages` event.

## Implementation Plan

### 1. Update Message Queries

```elixir
# lib/gridroom/grid.ex
def list_messages_paginated(node_id, opts \\ []) do
  limit = Keyword.get(opts, :limit, 50)
  before_id = Keyword.get(opts, :before)

  query = from m in Message,
    where: m.node_id == ^node_id,
    order_by: [desc: m.inserted_at],
    limit: ^limit,
    preload: [:user]

  query = if before_id do
    before_msg = Repo.get!(Message, before_id)
    from m in query, where: m.inserted_at < ^before_msg.inserted_at
  else
    query
  end

  Repo.all(query) |> Enum.reverse()  # Return in chronological order
end
```

### 2. Update NodeLive

```elixir
def mount(%{"id" => node_id}, _session, socket) do
  messages = Grid.list_messages_paginated(node_id, limit: 50)

  socket =
    socket
    |> stream(:messages, messages)
    |> assign(:has_more_messages, length(messages) == 50)
    |> assign(:oldest_message_id, List.first(messages)&.id)

  {:ok, socket}
end

def handle_event("load_more_messages", _, socket) do
  if socket.assigns.has_more_messages do
    older = Grid.list_messages_paginated(
      socket.assigns.node.id,
      limit: 25,
      before: socket.assigns.oldest_message_id
    )

    socket =
      socket
      |> stream_insert_many(:messages, older, at: 0)
      |> assign(:has_more_messages, length(older) == 25)
      |> assign(:oldest_message_id, List.first(older)&.id)

    {:noreply, socket}
  else
    {:noreply, socket}
  end
end
```

### 3. Scroll Position Management

When prepending messages, the scroll position can jump. Need JS hook to maintain position:

```javascript
// assets/js/hooks.js
Hooks.MessageScroll = {
  mounted() {
    this.scrollHeight = this.el.scrollHeight
  },
  updated() {
    // If new content was prepended, maintain scroll position
    const newHeight = this.el.scrollHeight
    if (newHeight > this.scrollHeight) {
      this.el.scrollTop = newHeight - this.scrollHeight
    }
    this.scrollHeight = newHeight
  }
}
```

## Open Questions

- What's the ideal initial load count? 50? 100?
- Should we show a loading spinner while fetching?
- Do we need to handle the case where user is at bottom and new messages arrive?
  - Currently using PubSub for real-time - need to combine with streams

## Research Links

- [Phoenix LiveView Streams](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/3)
- Chris McCord's ElixirConf demos on infinite scroll

## Completion Notes

**Completed**: 2026-01-17
**Outcome**: Implemented LiveView streams for efficient message lazy loading with infinite scroll.

### What was done:
- Added `list_messages_paginated/2` with cursor-based pagination
- Converted NodeLive to use `stream/3` for messages
- Added `load_more_messages` event handler
- Created `MessageStream` JS hook for scroll position management
- Created `InfiniteScroll` JS hook with IntersectionObserver
- Initial load: 50 messages, scroll loads 25 more per batch
- Highlights overlay now fetches from DB on demand

### Answers to open questions:
- Initial load: 50 messages (configurable via @initial_messages_limit)
- Loading indicator shows "loading..." text when fetching
- New messages handled via stream_insert, auto-scrolls if user at bottom

All core functionality implemented. Task closed.
