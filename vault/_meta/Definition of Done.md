---
tags: [workflow, quality, checklist]
related: [[Code Conventions]], [[Vault Writing Guidelines]]
---

# Definition of Done

The Definition of Done (DoD) establishes baseline acceptance criteria that apply to **every** task, regardless of type. Task-specific acceptance criteria build on top of these universal standards.

A task is not complete until all applicable items are satisfied.

## Universal Criteria

### 1. Code Quality

- [ ] Code follows project conventions - consistent style, naming, patterns
- [ ] No compiler/transpiler errors or warnings
- [ ] No linter errors or warnings
- [ ] No type workarounds (`as any`, `@ts-ignore`) - fix types properly
- [ ] No commented-out code, no stale TODOs (use task IDs)
- [ ] Comments explain "why", not "what"
- [ ] Avoid over-engineering: only make changes directly requested or clearly necessary
  - No features, refactors, or "improvements" beyond what was asked
  - No docstrings/comments/type annotations added to unchanged code
  - No error handling for scenarios that can't happen
  - Three similar lines of code is better than a premature abstraction

### 2. Security

- [ ] No data leakage to unauthorized users
  - Server-side authorization, not client-side hiding
  - If visible in DevTools, it's leaked
- [ ] All user input validated server-side
- [ ] Authorization checked on every endpoint
- [ ] No secrets or credentials in code or logs

### 3. Testing

- [ ] Critical paths have test coverage
- [ ] Core business logic has unit tests
- [ ] Happy path works end-to-end
- [ ] Edge cases considered and handled

### 4. Documentation

- [ ] Key decisions captured (in context doc or ADR if significant)
- [ ] Complex logic has inline comments explaining "why"
- [ ] Public APIs have clear type definitions
- [ ] Architecture diagrams updated if schema or core services changed
- [ ] Evergreen docs use no temporal language (see [[Avoiding Temporal Language]])

### 5. User Experience

- [ ] Loading states for async operations
- [ ] Error states handled gracefully
- [ ] Mobile-responsive (if applicable)
- [ ] Accessible (keyboard navigation, screen reader basics)

### 6. Operational Readiness

- [ ] No console errors or warnings in browser
- [ ] No unhandled promise rejections
- [ ] Reasonable performance (no obvious N+1 queries, unnecessary re-renders)
- [ ] Build passes

## When to Skip Items

Some criteria don't apply to every task:

| Task Type          | Likely N/A                              |
| ------------------ | --------------------------------------- |
| Documentation-only | Testing, Security, UX                   |
| Bug fix            | Documentation (unless behavior changed) |
| Refactor           | Documentation (unless API changed)      |
| Spike/research     | All except Documentation                |

Use judgment, but err on the side of completeness.

## Verification

Before marking a task complete:

1. **Self-review**: Walk through the DoD checklist
2. **Build passes**: Ensure build succeeds
3. **Manual test**: Exercise the feature in the browser

## Anti-Patterns

These indicate a task is NOT done:

- "It works on my machine" without testing elsewhere
- Tests are skipped or commented out
- TODO comments added for "later" without task ID
- Known bugs deferred without tracking
- UI looks correct but data is accessible via DevTools to unauthorized users
- Over-engineered solution when simpler approach works
- Backwards-compatibility hacks for unused code (if unused, delete it)
- Temporal language in evergreen docs ("will", "recently", "currently")
- Saying "out of scope" without documenting the issue
- Mixing unrelated changes in a single commit

## Relationship to Task Template

The task template includes a Review Checklist:

```markdown
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
```

This DoD expands on those items with the full criteria. The template checklist is a quick reminder; this DoD is the complete standard.

## Related

- [[Code Conventions]] - Naming, style, patterns
- [[Vault Writing Guidelines]] - Documentation standards
- [[Avoiding Temporal Language]] - Evergreen doc rules
