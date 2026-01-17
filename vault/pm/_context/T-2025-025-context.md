# Context: T-2025-025 Discussion Pods

**Task**: [[T-2025-025-discussion-pods]]
**Created**: 2026-01-17
**Status**: Planning

## Overview

Pods are **global private groups** that exist independently of discussions. While any user can join a discussion (by adding it to their bucket), pods create a second layer of privacy - a curated group that can have their own conversation thread visible only to pod members.

**Key Architecture**: Pods are standalone entities, but currently the only interaction surface is within discussions. When viewing a discussion, pod members can toggle to a "pod view" to see/send messages only visible to their pod mates.

**Core Concept**: A discussion has two "layers":
1. **General** - The existing public discussion (visible to all discussion participants)
2. **Pod(s)** - Private threads visible only to pod members (same pod can be used across multiple discussions)

## User Flow

### Creating a Pod
1. User is viewing a discussion
2. Clicks "Create Pod" (or similar)
3. Names the pod
4. Invites other users who are in this discussion

### Inviting to a Pod
1. Pod creator/member can invite other discussion participants
2. Invited user receives notification
3. User accepts or declines
4. On accept, pod appears in their pod list for that discussion

### Viewing Pods
1. User opens a discussion
2. Sees toggle/tabs: "General" | "Pod: Coffee Break" | "Pod: Planning"
3. Switching views changes which messages are shown
4. Message input posts to currently active view

### Forwarding Messages
1. User sees interesting message in General
2. Has option to "Forward to Pod"
3. Selects which pod(s) to forward to
4. Message appears in pod (attributed to forwarder? original author?)

## Data Model

### Pod Schema
```elixir
schema "pods" do
  field :name, :string
  # NO node_id - pods are global, not tied to a single discussion

  belongs_to :creator, User
  has_many :memberships, PodMembership
  has_many :members, through: [:memberships, :user]

  timestamps()
end
```

### PodMembership Schema
```elixir
schema "pod_memberships" do
  belongs_to :pod, Pod
  belongs_to :user, User
  field :role, :string, default: "member"  # creator, admin, member
  field :status, :string, default: "pending"  # pending, accepted, declined
  field :invited_by_id, :binary_id

  timestamps()
end
```

### Message Changes
```elixir
# Add to existing message schema
# Messages already have node_id (which discussion)
# Adding pod_id scopes within that discussion
field :pod_id, :binary_id  # null = general discussion, non-null = pod-specific
field :forwarded_from_id, :binary_id  # if forwarded, original message id
```

**Message Visibility Logic**:
- `pod_id = null` → visible in general discussion view
- `pod_id = X` → visible only in pod X's view within that discussion
- Same pod can have separate message threads in different discussions (messages scoped by both node_id AND pod_id)

## Key Decisions

- **Pods are global entities** - Pods exist as standalone records, NOT scoped to a single discussion
- **Discussion is the interaction surface** - Currently, the only way to interact with a pod is from within a discussion (toggle to pod view)
- **Invitation required**: Can't join pods without invite (vs. open join)
- **Message separation**: Pod messages are completely separate from general
- **Forward attribution**: TBD - show original author or forwarder?

### Future Possibilities (out of scope for now)
- View which discussions your pod mates currently have in their bucket bars
- Pods could have their own shared bucket bars

## Open Questions

1. Can pod creators remove members?
2. Can users leave pods voluntarily?
3. What happens to messages when someone leaves?
4. Should there be pod "roles" (admin, member)?
5. Limit on number of pods per discussion?
6. Limit on members per pod?
7. Can anonymous users create/join pods?

## Implementation Plan

### Phase 1: Core Pod Infrastructure
1. Create migrations for `pods` and `pod_memberships` tables
2. Add `pod_id` to messages table
3. Create `Gridroom.Pods` context with basic CRUD
4. Create schemas: `Pod`, `PodMembership`

### Phase 2: Invitation System
1. Create pod invitation functions
2. Add invitation status management
3. Build notification mechanism (or basic polling)

### Phase 3: Message Scoping
1. Update message queries to filter by pod_id
2. Ensure general messages (pod_id = null) don't appear in pods
3. Add forwarding capability

### Phase 4: UI Components
1. Pod selector/toggle component
2. Pod creation modal/form
3. Member invitation UI
4. Forward message UI

## Next Steps

1. Review plan with user
2. Run `/s T-2025-025` to start work
