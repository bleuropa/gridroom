# Avoiding Temporal Language

Evergreen documents must describe current state, not past or future. This prevents documentation rot and ensures docs are always accurate.

## Blocked Words

The pre-commit hook blocks these words in `vault/product/`, `vault/architecture/`, and `vault/features/`:

| Word       | Problem          | Alternative                              |
| ---------- | ---------------- | ---------------------------------------- |
| now        | Implies change   | Remove or describe current state         |
| currently  | Implies change   | Remove or describe current state         |
| recently   | Time-dependent   | Remove or describe current state         |
| soon       | Promise/forecast | Move to PM doc or remove                 |
| will       | Future promise   | Move to PM doc or describe current state |
| going to   | Future promise   | Move to PM doc or describe current state |
| planned    | Future promise   | Move to PM doc                           |
| future     | Time-dependent   | Move to PM doc or be specific            |
| next       | Time-dependent   | Move to PM doc                           |
| upcoming   | Time-dependent   | Move to PM doc                           |
| later      | Time-dependent   | Move to PM doc                           |
| eventually | Time-dependent   | Move to PM doc                           |
| previously | Past-dependent   | Describe current state                   |
| formerly   | Past-dependent   | Describe current state                   |
| originally | Past-dependent   | Describe current state                   |
| initially  | Past-dependent   | Describe current state                   |

## Examples

### Bad (temporal)

> "We will add team collaboration features in the next sprint."

### Good (evergreen)

> "Team collaboration enables shared workspaces for organizations."

Or if not implemented yet, **don't document it in evergreen docs**. Put it in a PM task instead.

### Bad (temporal)

> "The system currently uses PostgreSQL for analysis."

### Good (evergreen)

> "The system uses PostgreSQL for analysis."

### Bad (temporal)

> "We recently migrated from MySQL to PostgreSQL."

### Good (evergreen)

> "The system uses PostgreSQL for data persistence."

## Where Temporal Language IS Allowed

- `vault/pm/` - All PM documents (tasks, epics, context docs)
- `PROJECT_STATUS.md` - Status updates
- Commit messages
- Pull request descriptions
- Code comments (sparingly)

## Why This Matters

1. **Documentation rot**: "Soon" written 6 months ago is misleading
2. **Single source of truth**: Evergreen docs should always be accurate
3. **Maintenance burden**: Temporal language requires constant updates
4. **Reader confusion**: "Currently" implies something changed or will change

## Enforcement

The pre-commit hook automatically blocks commits that add temporal language to evergreen docs. If you see this error:

```
Found temporal language in evergreen doc: vault/features/Auth.md
   Evergreen docs must describe current state, not temporal changes
   Blocked words: now, currently, recently, soon, will, planned, future, etc.
```

Fix by:

1. Removing the temporal word
2. Rephrasing to describe current state
3. Moving future plans to a PM task document
