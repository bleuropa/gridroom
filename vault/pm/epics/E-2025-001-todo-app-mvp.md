---
type: epic
id: E-2025-001
created: 2025-01-15
status: completed
priority: high
---

# Epic: Todo App MVP

**Epic ID**: E-2025-001
**Status**: Completed
**Priority**: High
**Created**: 2025-01-15
**Completed**: 2025-01-20

---

## Overview

Build minimal viable todo application to demonstrate Balustrade framework patterns. The app serves as a reference implementation showing how to structure product docs, architecture, and PM workflows.

## Goals

- Demonstrate language-agnostic patterns
- Show hook enforcement in action
- Provide simple, understandable example (~100 lines)
- Zero dependencies (Node built-ins + vanilla JS)

## Success Criteria

- [ ] ✅ Todo CRUD operations working
- [ ] ✅ Frontend communicates with backend
- [ ] ✅ No build step required
- [ ] ✅ Can be deleted and replaced easily

## User Stories

- [[US-2025-001-setup-api]] - Set up basic API server
- [[US-2025-002-build-frontend]] - Create frontend interface

## Tasks

- [[T-2025-001-setup-todo-api]] - Implement REST endpoints
- [[T-2025-002-create-html-interface]] - Build vanilla JS UI
- [[B-2025-001-fix-cors-error]] - Fix CORS configuration

## Context

See [[E-2025-001-context]] for detailed notes and decisions.

## Key Decisions

- **No dependencies**: Use Node HTTP module instead of Express
- **CDN for styling**: Tailwind via CDN, no build process
- **Minimal scope**: Just 4 endpoints (GET, POST, PUT, DELETE)
- **In-memory storage**: No database, just array in memory

## Links

- Product Doc: [[Product Vision]]
- Architecture: [[System Architecture]]
- Feature: [[Todo Management]]

---

## Notes

This epic is an **example only**. Delete it and replace with your own product's epics.

The value is in the **pattern**, not the specific app.
