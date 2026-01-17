# Context: T-2025-025 Discussion Pods

**Task**: [[T-2025-025-discussion-pods]]
**Created**: 2026-01-17
**Status**: Planning

## Overview

Pods are private groups within discussions. While any user can join a discussion (by adding it to their bucket), pods create a second layer of privacy - a curated group that can have their own conversation thread visible only to pod members.

**Core Concept**: A discussion has two "layers":
1. **General** - The existing public discussion (visible to all discussion participants)
2. **Pod(s)** - Private threads visible only to pod members

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
  field :node_id, :binary_id  # Which discussion this pod belongs to

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
field :pod_id, :binary_id  # null = general discussion
field :forwarded_from_id, :binary_id  # if forwarded, original message id
```

## Key Decisions

- **Pod scope**: Pods are per-discussion (not global)
- **Invitation required**: Can't join pods without invite (vs. open join)
- **Message separation**: Pod messages are completely separate from general
- **Forward attribution**: TBD - show original author or forwarder?

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
