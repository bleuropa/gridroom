# Context: E-2025-001 - Todo App MVP

**Epic**: [[E-2025-001-todo-app-mvp]]
**Created**: 2025-01-15
**Last Updated**: 2025-01-20

---

## Overview

Context doc for todo app MVP epic. Captures decisions, learnings, and rationale throughout development.

---

## Key Decisions

### 2025-01-15: Choose Node HTTP over Express

**Decision**: Use Node built-in HTTP module instead of Express

**Rationale**:
- Zero dependencies demonstrates language-agnostic nature
- Example app should be trivial to understand
- Easier to delete and replace with real project
- Shows raw HTTP concepts clearly

**Trade-offs**:
- More verbose routing code
- Manual request parsing
- Less middleware ecosystem
- Acceptable for ~100 line example

### 2025-01-15: In-Memory Storage Only

**Decision**: Store todos in memory (array), no database

**Rationale**:
- Keeps example minimal
- No database setup required
- Data resets on restart - fine for demo
- Real apps will use their own storage

**Alternative Considered**: SQLite
- Rejected: Adds complexity and dependencies

### 2025-01-16: Vanilla JS Frontend

**Decision**: No React/Vue/Angular, just vanilla JavaScript

**Rationale**:
- Framework-agnostic template
- No build step required
- Works by opening HTML file
- Easy to understand for all developers

**Alternative Considered**: React
- Rejected: Requires build tools, npm, more complex

### 2025-01-16: Tailwind CSS via CDN

**Decision**: Use Tailwind CSS loaded from CDN

**Rationale**:
- No build step
- Familiar utility classes
- Professional look with minimal effort
- Single `<script>` tag

**Alternative Considered**: Plain CSS
- Considered but Tailwind makes example prettier

---

## Technical Challenges

### CORS Configuration

**Challenge**: Browser blocked API requests due to CORS policy

**Solution**:
1. Handle OPTIONS preflight requests explicitly
2. Add proper CORS headers to all responses
3. Allow all origins for development (`*`)

**Learning**: Always handle OPTIONS when building APIs that browsers will call

See [[B-2025-001-fix-cors-error]] for details.

### ID Generation

**Challenge**: Need unique IDs for todos

**Solution**: Simple counter-based IDs
```javascript
let nextId = 4;
todos.push({ id: nextId++, text, completed: false });
```

**Alternative Considered**: UUIDs
- Rejected: Overkill for example, would require dependency

---

## Scope Management

### What's In Scope

- ✅ Basic CRUD operations
- ✅ Minimal UI
- ✅ In-memory storage
- ✅ Zero dependencies

### What's Out of Scope

- ❌ User authentication
- ❌ Data persistence (database)
- ❌ Complex validation
- ❌ Testing infrastructure
- ❌ Production deployment
- ❌ Multiple lists/categories
- ❌ Due dates or priorities

**Rationale**: This is an EXAMPLE, not a production app. Keep it minimal so users can easily understand and delete it.

---

## Lessons Learned

1. **Simplicity is hard**: First version had too many features, had to cut back
2. **Dependencies creep**: Started with Express, realized we didn't need it
3. **Documentation matters**: Example needs to be self-explanatory
4. **Delete is good**: Explicitly tell users to delete this example

---

## Related Docs

- Epic: [[E-2025-001-todo-app-mvp]]
- Stories: [[US-2025-001-setup-api]], [[US-2025-002-build-frontend]]
- Tasks: [[T-2025-001-setup-todo-api]], [[T-2025-002-create-html-interface]]
- Bugs: [[B-2025-001-fix-cors-error]]

---

## Timeline

- **2025-01-15**: Epic started, architecture decisions made
- **2025-01-15**: Backend API implemented
- **2025-01-16**: Frontend started
- **2025-01-17**: CORS bug discovered and fixed
- **2025-01-18**: Frontend completed
- **2025-01-20**: Epic completed, documentation finalized

---

## Notes

This context doc demonstrates what to capture during epic development:
- Key decisions with rationale
- Technical challenges and solutions
- Scope boundaries
- Timeline of major events
- Links to related work

Your context docs should be similarly comprehensive for future reference.
