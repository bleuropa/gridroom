---
type: task
id: T-2025-001
story: US-2025-001
epic: E-2025-001
created: 2025-01-15
status: completed
priority: high
---

# Task: Set Up Todo API

**Task ID**: T-2025-001
**Story**: [[US-2025-001-setup-api]]
**Epic**: [[E-2025-001-todo-app-mvp]]
**Status**: Completed
**Priority**: High
**Branch**: feat/T-2025-001-setup-todo-api
**Created**: 2025-01-15
**Started**: 2025-01-15
**Completed**: 2025-01-17

---

## Description

Implement REST API endpoints for todo CRUD operations using only Node.js built-in modules. No external dependencies.

## Checklist

- [x] Create server.js with HTTP server
- [x] Implement GET /api/todos endpoint
- [x] Implement POST /api/todos endpoint
- [x] Implement PUT /api/todos/:id endpoint
- [x] Implement DELETE /api/todos/:id endpoint
- [x] Add CORS headers for local development
- [x] Add request body parsing
- [x] Add URL routing logic
- [x] Test all endpoints manually
- [x] Add example todos to seed data

## Context

See [[T-2025-001-context]] for detailed implementation notes.

## Technical Details

**File**: `example-app/server.js`
**Lines**: ~80 lines
**Dependencies**: None (Node built-ins only)

**Endpoints**:
```
GET    /api/todos       # List all todos
POST   /api/todos       # Create new todo
PUT    /api/todos/:id   # Update todo
DELETE /api/todos/:id   # Delete todo
```

**Data Structure**:
```javascript
{
  id: number,
  text: string,
  completed: boolean
}
```

## Key Decisions

1. **In-memory storage**: Just an array, resets on restart
2. **Manual routing**: URL parsing instead of router library
3. **Simple error handling**: Basic status codes
4. **CORS wide-open**: `Access-Control-Allow-Origin: *` for dev

## Testing

Manual testing with curl:
```bash
# Get all todos
curl http://localhost:3000/api/todos

# Create todo
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -d '{"text":"New task"}'

# Update todo
curl -X PUT http://localhost:3000/api/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'

# Delete todo
curl -X DELETE http://localhost:3000/api/todos/1
```

## Files Modified

- `example-app/server.js` (created)

## Commits

- `feat: add todo REST API endpoints`
- `fix: correct CORS headers for preflight`

---

## Notes

This task demonstrates task structure and detail level. Your tasks should have similar clarity about scope, technical approach, and completion criteria.
