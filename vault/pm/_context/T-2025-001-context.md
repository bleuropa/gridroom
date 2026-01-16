# Context: T-2025-001 - Setup Todo API

**Task**: [[T-2025-001-setup-todo-api]]
**Created**: 2025-01-15
**Last Updated**: 2025-01-17

---

## Implementation Notes

### Server Setup

Used Node.js built-in HTTP module:
```javascript
const http = require('http');
const server = http.createServer(handleRequest);
server.listen(3000);
```

No Express, no dependencies - just Node built-ins.

### Routing Approach

Manual URL parsing and method checking:
```javascript
const url = new URL(req.url, `http://${req.headers.host}`);
const path = url.pathname;

if (req.method === 'GET' && path === '/api/todos') {
  // Handle GET
} else if (req.method === 'POST' && path === '/api/todos') {
  // Handle POST
}
```

Simple but effective for 4 endpoints.

### Request Body Parsing

Manual JSON parsing since no middleware:
```javascript
let body = '';
req.on('data', chunk => body += chunk);
req.on('end', () => {
  const data = JSON.parse(body);
  // Process data
});
```

### CORS Headers

Initially forgot these - see [[B-2025-001-fix-cors-error]]. Final version:
```javascript
res.setHeader('Access-Control-Allow-Origin', '*');
res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
```

### Data Structure

Simple array of objects:
```javascript
let todos = [
  { id: 1, text: 'Delete example-app/', completed: false },
  { id: 2, text: 'Add your own app', completed: false },
  { id: 3, text: 'Customize .claude/', completed: false }
];
```

---

## Testing Commands

```bash
# Start server
cd example-app
node server.js

# Test in another terminal
curl http://localhost:3000/api/todos
curl -X POST http://localhost:3000/api/todos -H "Content-Type: application/json" -d '{"text":"New task"}'
curl -X PUT http://localhost:3000/api/todos/1 -H "Content-Type: application/json" -d '{"completed":true}'
curl -X DELETE http://localhost:3000/api/todos/1
```

---

## Decisions

**Why not Express?**
- Wanted zero dependencies
- HTTP module sufficient for 4 endpoints
- Makes example more understandable

**Why in-memory storage?**
- Keeps example simple
- No database setup required
- Acceptable for demonstration

**Why these specific endpoints?**
- Standard REST pattern
- Covers all CRUD operations
- Familiar to most developers

---

## Files

- `example-app/server.js` - Full implementation (~80 lines)

---

## Commits

- `feat: add todo REST API endpoints` - Initial implementation
- `fix: handle CORS preflight OPTIONS requests` - CORS fix

---

## Notes

This task took ~2 hours including CORS debugging. Most time spent on manual routing logic and ensuring clean JSON responses.
