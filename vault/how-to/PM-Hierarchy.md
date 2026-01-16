# PM Hierarchy: Epics, Stories, Tasks, and Bugs

**Purpose**: Understanding when to use each PM artifact type and how they relate

---

## The Hierarchy

```
EPIC (E-YYYY-NNN)
  └── STORY (US-YYYY-NNN)
      ├── TASK (T-YYYY-NNN)
      ├── TASK (T-YYYY-NNN)
      └── BUG (B-YYYY-NNN)
```

### Directory Structure

```
vault/
├── _templates/     # Templates for creating new PM artifacts
│   ├── Epic.md
│   ├── Story.md
│   ├── Task.md
│   ├── Bug.md
│   └── Context.md
└── pm/
    ├── epics/      # Epic files (E-YYYY-NNN-*.md)
    ├── stories/    # User story files (US-YYYY-NNN-*.md)
    ├── tasks/      # Task files (T-YYYY-NNN-*.md)
    ├── bugs/       # Bug files (B-YYYY-NNN-*.md)
    └── _context/   # Context docs for all types
```

---

## 1. Epics (E-YYYY-NNN)

### What

Large body of work that delivers significant product value. Multiple weeks/months of effort.

### When to Use

- Major feature development
- Large architectural changes
- Multi-phase initiatives
- Work requiring multiple stories

### Structure

```markdown
---
type: epic
id: E-2025-001
created: YYYY-MM-DD
status: in-progress | completed | cancelled
priority: high | medium | low
---

# Epic: [Name]

## Overview
[What is this epic about?]

## Goals
[What are we trying to achieve?]

## Success Criteria
[How do we know we're done?]

## User Stories
- [[US-YYYY-NNN]] - Story name
- [[US-YYYY-NNN]] - Story name

## Key Decisions
[Major architectural/product decisions]
```

### Example

```markdown
# Epic: User Authentication System

**Epic ID**: E-2025-001
**Status**: In Progress

## Overview
Build complete authentication system with email/password,
OAuth, password reset, and session management.

## User Stories
- [[US-2025-001]] - Email/password login
- [[US-2025-002]] - OAuth integration
- [[US-2025-003]] - Password reset flow
```

---

## 2. User Stories (US-YYYY-NNN)

### What

User-facing feature or capability. 1-2 weeks of work. Describes WHO wants WHAT and WHY.

### When to Use

- New user-facing functionality
- Feature that delivers standalone value
- Work that can be demoed to users
- Bridges epic to implementable tasks

### Structure

```markdown
---
type: story
id: US-2025-001
epic: E-2025-001
created: YYYY-MM-DD
status: in-progress | completed
priority: high | medium | low
---

# User Story: [Name]

As a **[user type]**
I want to **[capability]**
So that **[benefit]**

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Tasks
- [[T-YYYY-NNN]] - Task name
- [[T-YYYY-NNN]] - Task name

## Definition of Done
[What must be true to consider this story complete?]
```

### Example

```markdown
# User Story: Email/Password Login

As a **user**
I want to **log in with email and password**
So that **I can access my account securely**

## Acceptance Criteria
- [ ] Login form with email/password fields
- [ ] Password hashing with bcrypt
- [ ] Session creation on successful login
- [ ] Error messages for invalid credentials

## Tasks
- [[T-2025-001]] - Create login form UI
- [[T-2025-002]] - Implement auth API
- [[T-2025-003]] - Add session management
```

---

## 3. Tasks (T-YYYY-NNN)

### What

Discrete unit of work. 1-3 days max. Technical implementation, no user story format.

### When to Use

- Implementing part of a story
- Technical work (refactoring, infrastructure)
- Work that's too small for a story
- Concrete, actionable work items

### Structure

```markdown
---
type: task
id: T-2025-001
story: US-2025-001
epic: E-2025-001
created: YYYY-MM-DD
status: pending | in-progress | completed
priority: high | medium | low
---

# Task: [Name]

**Task ID**: T-2025-001
**Story**: [[US-YYYY-NNN]]
**Status**: In Progress
**Branch**: feat/T-2025-001-description

## Description
[What needs to be done?]

## Checklist
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Technical Details
[Implementation approach, APIs, data structures]

## Files Modified
- path/to/file.ts
- path/to/test.ts

## Commits
- feat: description
- fix: description
```

### Example

```markdown
# Task: Implement Auth API

**Task ID**: T-2025-002
**Story**: [[US-2025-001-email-login]]

## Description
Build REST API endpoints for user authentication
with bcrypt password hashing and JWT tokens.

## Checklist
- [x] POST /api/auth/login endpoint
- [x] Bcrypt password comparison
- [x] JWT token generation
- [x] Error handling for invalid credentials
- [ ] Rate limiting for login attempts

## Technical Details
- Express route in `src/routes/auth.ts`
- Password validation with bcrypt
- JWT signing with 24h expiry
- Return user object + token on success
```

---

## 4. Bugs (B-YYYY-NNN)

### What

Issue with existing functionality. Unplanned work to fix problems.

### When to Use

- Something broken that used to work
- Incorrect behavior vs. specification
- Edge case causing errors
- Production issues

### Structure

```markdown
---
type: bug
id: B-2025-001
story: US-YYYY-NNN (optional)
epic: E-YYYY-NNN (optional)
created: YYYY-MM-DD
status: pending | in-progress | completed
priority: high | medium | low
severity: critical | high | medium | low
---

# Bug: [Short Description]

**Bug ID**: B-2025-001
**Severity**: High
**Status**: In Progress
**Branch**: fix/B-2025-001-description

## Description
[What's wrong?]

## Error Message
```
[Paste error if applicable]
```

## Steps to Reproduce
1. Step 1
2. Step 2
3. Observe error

## Expected Behavior
[What should happen?]

## Actual Behavior
[What actually happens?]

## Root Cause
[Why is this happening?]

## Fix
[How to fix it]

## Testing
[How to verify fix works]
```

### Example

```markdown
# Bug: CORS Error Blocking API Calls

**Bug ID**: B-2025-001
**Severity**: High (blocks frontend dev)
**Status**: Completed

## Error Message
```
Access to fetch at 'http://localhost:3000/api/todos'
has been blocked by CORS policy
```

## Steps to Reproduce
1. Start backend server
2. Open frontend in browser
3. Try to create todo
4. See CORS error in console

## Root Cause
Server not handling OPTIONS preflight requests,
missing CORS headers.

## Fix
Added OPTIONS handler and CORS headers to all responses.
```

---

## Choosing the Right Type

### Ask Yourself:

**Is it large, multi-week work?** → Epic
**Is it user-facing functionality?** → Story
**Is it a concrete implementation step?** → Task
**Is something broken?** → Bug

### Size Guidelines:

- **Epic**: Weeks to months
- **Story**: Days to 2 weeks
- **Task**: Hours to 3 days
- **Bug**: Hours to days (depends on severity)

### Relationships:

```
✅ Epic contains Stories
✅ Story contains Tasks
✅ Story contains Bugs (if bug found during story work)
✅ Task can exist without Story (technical work)
✅ Bug can exist without Story/Epic (production issues)

❌ Epic does not contain Tasks directly (use Story)
❌ Task does not contain other Tasks (break it down differently)
```

---

## Practical Examples

### Example 1: New Feature

```
E-2025-002: Shopping Cart
  └── US-2025-010: Add Items to Cart
      ├── T-2025-020: Create cart data model
      ├── T-2025-021: Build add-to-cart UI
      ├── T-2025-022: Implement cart API
      └── B-2025-005: Fix quantity update bug
  └── US-2025-011: Checkout Flow
      ├── T-2025-023: Build checkout form
      └── T-2025-024: Integrate payment API
```

### Example 2: Technical Work

```
No Epic/Story needed:
  └── T-2025-030: Refactor database queries to use repository pattern
  └── T-2025-031: Add TypeScript to legacy JS files
  └── T-2025-032: Update dependencies to latest versions
```

### Example 3: Production Bug

```
No Epic/Story needed:
  └── B-2025-010: Production crash when uploading large files
      (Severity: Critical, needs immediate fix)
```

---

## Frontmatter Reference

### All Types Share:

```yaml
---
type: epic | story | task | bug
id: [E|US|T|B]-YYYY-NNN
created: YYYY-MM-DD
status: backlog | in-progress | paused | completed | deferred | superseded | cancelled
priority: high | medium | low
---
```

### Status Definitions

| Status | Meaning |
|--------|---------|
| `backlog` | Not started, waiting in queue |
| `in-progress` | Currently being worked on |
| `paused` | Started but on hold (will resume) |
| `completed` | Finished successfully (**preferred term**) |
| `deferred` | Postponed indefinitely (may never resume) |
| `superseded` | Replaced by another task |
| `cancelled` | Abandoned, will not be done |

**Note**: Always use `completed` for finished work. Do not use `done` - this ensures consistency across all PM artifacts.

### Bug-Specific:

```yaml
---
severity: critical | high | medium | low
---
```

### Story/Task-Specific:

```yaml
---
story: US-YYYY-NNN  # Parent story
epic: E-YYYY-NNN    # Parent epic
---
```

---

## Working with the Hierarchy

### Starting New Work

1. **Large feature?** Create Epic first
2. **Break into Stories** - user-facing slices
3. **Break into Tasks** - implementation steps
4. **Track Bugs** - issues found during work

### During Development

- Update task status as you progress
- Add bugs when you find issues
- Link bugs to stories/epics if related
- Update context docs with decisions

### Completing Work

- Mark tasks complete when done
- Close bugs when fixed and verified
- Complete stories when all criteria met
- Complete epics when all stories done

---

## Tips

1. **Keep tasks small**: If >7 checklist items, break into multiple tasks
2. **Link everything**: Use `[[]]` wiki links to connect related work
3. **Update context docs**: Capture decisions and learnings
4. **Use branches**: Name branches after task/bug ID
5. **One task at a time**: Focus on completing before starting next

---

## See Also

- [[Meta-Framework]] - Understanding the Balustrade system
- [[Git Workflow]] - How to commit and branch
- [[Hooks and Automation]] - What gets validated automatically

---

## Notes

This hierarchy is a **pattern**, not a rule. Adapt to your needs:
- Small projects might skip Epics entirely
- Some teams use different terminology
- Adjust frontmatter fields for your workflow
- The key is consistency and clear relationships

**Remember**: The framework shows you HOW to organize work, not WHICH specific structure you must use.
