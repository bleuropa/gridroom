---
type: bug
id: B-2025-001
story: US-2025-001
epic: E-2025-001
created: 2025-01-17
status: completed
priority: high
severity: high
---

# Bug: Fix CORS Error

**Bug ID**: B-2025-001
**Story**: [[US-2025-001-setup-api]]
**Epic**: [[E-2025-001-todo-app-mvp]]
**Status**: Completed
**Priority**: High
**Severity**: High (blocks frontend development)
**Branch**: fix/B-2025-001-cors-error
**Created**: 2025-01-17
**Started**: 2025-01-17
**Completed**: 2025-01-17

---

## Description

Browser blocks API requests from frontend due to CORS policy. OPTIONS preflight requests failing.

## Error Message

```
Access to fetch at 'http://localhost:3000/api/todos' from origin 'null'
has been blocked by CORS policy: Response to preflight request doesn't
pass access control check: No 'Access-Control-Allow-Origin' header is
present on the requested resource.
```

## Steps to Reproduce

1. Start backend server: `node server.js`
2. Open `index.html` in browser
3. Try to add a todo
4. Check browser console - see CORS error
5. Network tab shows OPTIONS request failing

## Expected Behavior

- Frontend should successfully make requests to backend
- CORS headers should allow cross-origin requests during development
- OPTIONS preflight requests should return 200 OK

## Actual Behavior

- All API requests blocked by browser
- OPTIONS requests return 404
- Missing CORS headers on responses

## Root Cause

Server was only adding CORS headers to actual requests, not handling OPTIONS preflight requests. Browser sends OPTIONS before POST/PUT/DELETE to check if cross-origin requests are allowed.

## Fix

Added OPTIONS request handler and proper CORS headers:

```javascript
// Handle CORS preflight
if (req.method === 'OPTIONS') {
  res.writeHead(200, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  res.end();
  return;
}

// Add CORS headers to all responses
res.setHeader('Access-Control-Allow-Origin', '*');
res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
```

## Testing

1. ✅ OPTIONS requests return 200
2. ✅ POST requests succeed from browser
3. ✅ PUT requests succeed from browser
4. ✅ DELETE requests succeed from browser
5. ✅ No CORS errors in console

## Files Modified

- `example-app/server.js:15-25` (added OPTIONS handler)
- `example-app/server.js:30-32` (added CORS headers)

## Commits

- `fix: handle CORS preflight OPTIONS requests`

---

## Notes

**Bug Tracking Pattern**: This demonstrates how to track bugs in Balustrade:
- Reference parent story/epic
- Include error messages and reproduction steps
- Document root cause analysis
- Show the fix with code snippets
- List testing verification

**Severity Levels**:
- **Critical**: System down, data loss
- **High**: Blocks major functionality (like this bug)
- **Medium**: Degraded experience, workaround available
- **Low**: Minor issue, cosmetic

Your bugs should follow similar structure with clear repro steps and fix documentation.
