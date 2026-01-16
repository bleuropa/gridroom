# Epic vs Task Decision Tree

Use this decision tree when classifying new work items.

## The Decision Tree

```
Is this fixing broken existing behavior?
├── YES → BUG
└── NO ↓

Is this user-facing with UI/UX work?
├── YES → Is it purely technical implementation?
│         ├── YES → TASK
│         └── NO → STORY (optional, default to TASK)
└── NO ↓

Do 5+ child tasks/stories ALREADY EXIST?
├── NO → TASK (always)
└── YES ↓

Does it span multiple major components?
├── NO → TASK
└── YES ↓

Is the timeline > 2 weeks?
├── NO → TASK
└── YES ↓

Does it have system-wide impact?
├── NO → TASK
└── YES → EPIC (rare)
```

## Key Principle

**When in doubt, choose TASK.**

Tasks are the default work unit. Epics are rare and should only be created when significant child work already exists.

## ID Prefixes

| Type    | Prefix       | Example      |
| ------- | ------------ | ------------ |
| Task    | T-           | T-2025-001   |
| Subtask | T-{parent}.N | T-2025-029.1 |
| Epic    | E-           | E-2025-001   |
| Story   | US-          | US-2025-001  |
| Bug     | BUG-         | BUG-2025-001 |

### Subtask Nesting

Subtasks use dot notation appended to parent ID:

- `T-2025-029` → Parent task
- `T-2025-029.1` → First subtask
- `T-2025-029.2` → Second subtask
- `T-2025-029.1.1` → Nested subtask (unlimited depth)

## Anti-Patterns

### "This sounds big" → Epic

**Wrong**: Creating an Epic because the work seems large.
**Right**: Create a Task. If it grows to 5+ child tasks, consider promoting to Epic.

### "I wrote a design doc" → Epic

**Wrong**: Creating an Epic because you wrote planning documentation.
**Right**: Design docs are outputs of Tasks, not criteria for Epics.

### Creating Epic before child work

**Wrong**: Starting with an Epic and planning to create child tasks.
**Right**: Create Tasks first. Only create Epic when 5+ Tasks already exist and need grouping.

### Inventing new prefixes

**Wrong**: Using FEAT-, IMP-, REF- or other custom prefixes.
**Right**: Use the standard prefixes (T-, E-, US-, BUG-).

## Examples

### Task (most common)

- "Add dark mode toggle"
- "Implement authentication"
- "Set up database schema"
- "Create API endpoint"
- "Refactor database queries"

### Story (optional)

- "As a user, I want to share my work so others can view it"
- "As a team member, I want to collaborate"

Use Story when:

- There's clear user-facing value
- UI/UX design is significant
- You want to track user journey

Otherwise, just use Task.

### Bug

- "Login redirect fails on Safari"
- "Page doesn't render on mobile"
- "API returns 500 on empty input"

Must be fixing **existing broken behavior**, not adding new features.

### Epic (rare)

- "Authentication System" (after T-001 login, T-002 signup, T-003 password reset, T-004 OAuth, T-005 session management exist)
- "Team Collaboration" (after 5+ team-related tasks exist)

Only create when grouping existing work provides organizational value.

## Hierarchical Tasks (Subtasks)

### When to Create Subtasks

Create a subtask when:

- Discovery during a task reveals additional sub-work
- Breaking down a complex task into manageable pieces
- Tracking multiple related fixes under one umbrella task

### Subtask vs New Root Task

| Situation                               | Create              |
| --------------------------------------- | ------------------- |
| Sub-work discovered during current task | Subtask (T-NNN.1)   |
| Unrelated new feature request           | Root task (T-NNN+1) |
| Bug found while working on feature      | Subtask if related  |
| User explicitly requests separate task  | Root task           |

### Parent-Child Rules

1. **Parent cannot close while children are open**
   - Children must be `completed` or `deferred`
   - System enforces this via `/c` command

2. **Subtasks share parent's context doc**
   - Append notes with headers: `## T-2025-029.1: {Title}`
   - Create separate context doc only for substantial subtasks

3. **Branch naming stays flat**
   - Work on subtasks using parent's branch
   - Example: `feat/T-2025-029-implement-auth` for all T-2025-029.\* subtasks

4. **File structure is flat**
   - All tasks in `vault/pm/tasks/`
   - Hierarchy shown in ID, not folder structure

## Task Lifecycle & Status Management

### Standard Statuses

| Status      | Meaning                                    |
| ----------- | ------------------------------------------ |
| backlog     | Not yet started, waiting to be prioritized |
| todo        | Prioritized, ready to start                |
| in-progress | Currently being worked on                  |
| completed   | Completed successfully                     |
| superseded  | Replaced by another task                   |
| archived    | No longer relevant, preserved for history  |

### When to Supersede a Task

Before creating a new task that overlaps with existing work:

1. **Search for related tasks** using keywords
2. **Check if new task eclipses old one** (broader scope, evolved thinking)
3. **Decide on relationship**:
   - **Supersede**: New task fully replaces old (mark old as `superseded`)
   - **Incorporate**: Merge relevant items into new task, archive old
   - **Coexist**: Different scopes, both remain active (link them)
   - **Rewrite**: Update old task instead of creating new one

### How to Supersede

1. Update old task frontmatter:

   ```yaml
   status: superseded
   superseded_by: T-YYYY-NNN
   ```

2. Add note to old task explaining why it was superseded

3. Reference old task in new task's "Related Tasks" section

### Best Practices

- **Check before creating**: Search for related tasks first
- **Link related work**: Use `[[wiki links]]` between related tasks
- **Document decisions**: Explain why tasks were superseded/archived
- **Keep records clean**: Avoid redundant open tasks for same work
