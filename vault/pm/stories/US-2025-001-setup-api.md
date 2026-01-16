---
type: story
id: US-2025-001
epic: E-2025-001
created: 2025-01-15
status: completed
priority: high
---

# User Story: Set Up API Server

**Story ID**: US-2025-001
**Epic**: [[E-2025-001-todo-app-mvp]]
**Status**: Completed
**Priority**: High
**Created**: 2025-01-15
**Completed**: 2025-01-17

---

## Story

As a **developer**
I want to **have a simple REST API for todos**
So that **the frontend can perform CRUD operations**

## Acceptance Criteria

- [ ] ✅ Server starts on port 3000
- [ ] ✅ GET /api/todos returns all todos
- [ ] ✅ POST /api/todos creates new todo
- [ ] ✅ PUT /api/todos/:id updates todo
- [ ] ✅ DELETE /api/todos/:id deletes todo
- [ ] ✅ CORS enabled for local development
- [ ] ✅ No external dependencies (Node built-ins only)

## Tasks

- [[T-2025-001-setup-todo-api]] - Implement REST endpoints

## Context

See [[US-2025-001-context]] for implementation notes.

## Technical Notes

- Using Node HTTP module (no Express)
- In-memory storage (array)
- Simple JSON request/response parsing
- Manual routing with URL parsing

## Definition of Done

- All endpoints functional
- CORS working
- Can run with `node server.js`
- No npm dependencies required

---

## Notes

This story demonstrates how to structure user stories in Balustrade. Replace with your own stories.
