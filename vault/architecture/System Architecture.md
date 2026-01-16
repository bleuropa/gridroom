# System Architecture (Example: Todo API)

**This is an example.** Replace with YOUR architecture.

---

## Architecture Overview

Simple REST API with in-memory storage.

**Why this approach**: Minimal dependencies, easy to understand and delete.

## Components

### API Server (server.js)
- Node HTTP server (no Express)
- 4 REST endpoints
- In-memory storage
- CORS enabled for local development

### Frontend (index.html)
- Vanilla JavaScript
- Tailwind via CDN
- Fetch API for requests

## Design Decisions

### Why No Database?
- Keep example minimal
- Zero setup required
- Easy to understand and replace

### Why No Framework?
- No build step
- No dependencies to install
- Works with just Node built-ins

### Why REST?
- Universal pattern
- Easy to understand
- Shows endpoint documentation

## API Design

```
GET    /todos     - List all todos
POST   /todos     - Create todo
PATCH  /todos/:id - Update todo
DELETE /todos/:id - Delete todo
```

---

## For Your Project

Replace this with YOUR architecture:
- System components
- Data flow
- Technology choices
- Design decisions and trade-offs
- Integration points

Keep it evergreen - describe current state, not future plans.
