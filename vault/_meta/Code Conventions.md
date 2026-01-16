---
tags: [moc]
---

# Code Conventions

Quick reference for coding standards.

## Philosophy

How we think about code.

- **Single Author Principle** - Code should look like one person wrote it
- **YAGNI** - Don't build what you don't need yet
- **DRY** - Don't repeat yourself (with discipline)
- **Rule of Three** - Wait for patterns before abstracting
- **Wrong Abstraction** - Duplication is cheaper than the wrong abstraction

## Style

How we format and name things.

### File Naming

| Type       | Convention       | Example                 |
| ---------- | ---------------- | ----------------------- |
| Components | PascalCase       | `UserProfile.tsx`       |
| Utilities  | kebab-case       | `url-utils.ts`          |
| Tests      | source + `.test` | `auth.test.ts`          |

### Code Naming

| Type                | Convention      | Example                |
| ------------------- | --------------- | ---------------------- |
| Functions/Variables | camelCase       | `getUserById`          |
| Constants           | SCREAMING_SNAKE | `MAX_RETRIES`          |
| Types/Interfaces    | PascalCase      | `UserProfile`          |
| Booleans            | is/has/should   | `isAdmin`, `hasAccess` |

### Comments

- Explain "why", not "what"
- No temporal language ("recently", "soon", "will")
- No commented-out code - delete it (git has history)
- No stale TODOs - include task ID or fix it now

## Patterns

### Type Safety

- No `as any` - fix the types properly
- Use discriminated unions for state
- Prefer explicit types over inference for public APIs

### Logging

- Consistent prefix format: `[Module]` or `[Module:Function]`
- Include relevant context (IDs, counts)
- Error logs include stack traces

## Architecture

How we structure systems.

- **Server-First** - Business logic on the server
- **Single Source of Truth** - One canonical location for state
- **Separation of Concerns** - Different concerns, different places
- **Single Responsibility** - One reason to change

## Workflow

How we work day-to-day.

- **Boy Scout Rule** - Leave code better than you found it
- **Definition of Done** - Complete the checklist (see [[Definition of Done]])
- **Commit Often** - Small, focused commits with conventional format

## Quick Reference

### Avoid These

```
❌ as any                  - Fix types properly
❌ // TODO: fix later      - Use task ID: // TODO(T-2025-001): ...
❌ // oldFunction()        - Delete commented code
❌ will, recently, soon    - Use present tense
❌ Premature abstraction   - Wait for 3+ occurrences
```

### Prefer These

```
✅ Explicit types          - Clear contracts
✅ Discriminated unions    - Type-safe state
✅ Server-side validation  - Never trust client
✅ Focused commits         - One thing at a time
✅ Present tense comments  - "Validates input" not "Will validate"
```
