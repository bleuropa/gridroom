# Context: T-2025-021 Persistent Dismissed Discussions

**Task**: [[T-2025-021-persistent-dismissed-discussions]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Users who X (dismiss) a discussion should never see that discussion again, even after:
- Page refresh
- Clearing buckets
- Session expiry (for auth users)

This requires moving dismissal state from ephemeral (session/LiveView assigns) to persistent (database) storage.

## Key Decisions

- Storage: Database table vs user preferences JSON
- Anonymous users: Track by session_id, potentially migrate on auth
- Query strategy: Filter at query level vs LiveView level

## Implementation Plan

### 1. Database Schema

```elixir
# dismissed_discussions table
- id: uuid primary key
- user_id: uuid (nullable, for authenticated users)
- session_id: string (for anonymous users)
- discussion_id: uuid references discussions
- dismissed_at: utc_datetime
- unique constraint on (user_id, discussion_id) and (session_id, discussion_id)
```

### 2. Context Functions

```elixir
# lib/gridroom/discussions.ex or new context
def dismiss_discussion(user_or_session, discussion_id)
def list_dismissed_ids(user_or_session)
def dismissed?(user_or_session, discussion_id)
```

### 3. Query Integration

Update emergence/discovery queries to exclude dismissed IDs:
```elixir
def list_available_discussions(user_or_session) do
  dismissed_ids = list_dismissed_ids(user_or_session)

  from(d in Discussion,
    where: d.id not in ^dismissed_ids,
    # ... rest of query
  )
end
```

### 4. LiveView Integration

On X click:
1. Call dismiss_discussion/2
2. Remove from assigns
3. Dismissal survives reconnect via database

## Open Questions

- Should there be an "undo" or way to see dismissed discussions?
- Migration strategy for any existing session-based dismissals?
- Rate limit dismissals to prevent abuse?

## Next Steps

1. Review plan with user
2. Run `/s T-2025-021` to start work

## Auto-saved State (2026-01-16 21:28)

Recent commits:
- feat: Strange glyph designations (682 surreal identifiers)
- feat: Require account to chat, cleaner terminal logos
- feat: Terminal boot-up aesthetic for auth pages

**Note**: This entry was auto-generated before memory compaction.

