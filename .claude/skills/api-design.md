---
name: api-design
description: RESTful API design patterns and best practices. Consistent, maintainable API endpoints.
---

# API Design Skill

Best practices for designing clear, consistent, and maintainable REST APIs.

## Core Principles

1. **Consistency** - Follow same patterns across all endpoints
2. **Predictability** - Behavior matches expectations
3. **Simplicity** - Easy to understand and use
4. **Versioning** - Plan for changes over time
5. **Documentation** - Clear, up-to-date docs

## Resource Naming

### Use Nouns, Not Verbs

❌ **Bad**:
```
/getUsers
/createUser
/deleteUser
```

✅ **Good**:
```
GET    /users
POST   /users
DELETE /users/:id
```

### Plural Resource Names

❌ **Bad**:
```
/user/:id
/post/:id
```

✅ **Good**:
```
/users/:id
/posts/:id
```

### Nested Resources

For related resources:
```
/users/:userId/posts
/posts/:postId/comments
/companies/:companyId/employees
```

**Don't nest too deep** (max 2 levels):
❌ `/users/:userId/posts/:postId/comments/:commentId/likes`
✅ `/comments/:commentId/likes`

## HTTP Methods

### Standard CRUD Operations

```
GET    /users          # List all users
GET    /users/:id      # Get specific user
POST   /users          # Create new user
PUT    /users/:id      # Replace entire user
PATCH  /users/:id      # Update partial user
DELETE /users/:id      # Delete user
```

### Method Semantics

**GET**: Safe, idempotent, cacheable
- No side effects
- Can be repeated safely
- Results can be cached

**POST**: Not idempotent
- Creates new resource
- May have side effects
- Returns 201 with Location header

**PUT**: Idempotent
- Replaces entire resource
- Same request = same result
- Returns 200 or 204

**PATCH**: Idempotent
- Partial update
- Only sends changed fields
- Returns 200 with updated resource

**DELETE**: Idempotent
- Removes resource
- Returns 204 (no content)
- Repeated deletes = 404

## Status Codes

### Success (2xx)

```
200 OK              # Successful GET, PUT, PATCH
201 Created         # Successful POST
204 No Content      # Successful DELETE
```

### Client Errors (4xx)

```
400 Bad Request     # Invalid input
401 Unauthorized    # Not authenticated
403 Forbidden       # Authenticated but not allowed
404 Not Found       # Resource doesn't exist
409 Conflict        # Conflict with current state
422 Unprocessable   # Validation failed
429 Too Many Requests # Rate limited
```

### Server Errors (5xx)

```
500 Internal Error  # Server error
502 Bad Gateway     # Upstream error
503 Service Unavailable # Server overloaded
```

## Request/Response Format

### Consistent JSON Structure

**Success Response**:
```json
{
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**List Response**:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "perPage": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

**Error Response**:
```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Email is required",
    "details": {
      "field": "email",
      "reason": "missing_field"
    }
  }
}
```

### Input Validation

```javascript
// Validate all inputs
POST /users
{
  "name": "",           // ❌ Empty
  "email": "invalid",   // ❌ Invalid format
  "age": -5            // ❌ Invalid value
}

// Response
400 Bad Request
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input validation failed",
    "details": [
      { "field": "name", "message": "Name is required" },
      { "field": "email", "message": "Invalid email format" },
      { "field": "age", "message": "Age must be positive" }
    ]
  }
}
```

## Query Parameters

### Filtering

```
GET /users?role=admin&active=true
GET /posts?author=john&category=tech
```

### Sorting

```
GET /users?sort=name
GET /users?sort=-created_at  # descending
GET /posts?sort=title,created_at
```

### Pagination

```
GET /users?page=2&per_page=20
GET /users?offset=40&limit=20
```

### Field Selection

```
GET /users?fields=id,name,email
GET /posts?include=author,comments
```

## Versioning

### URL Versioning (Recommended)

```
/api/v1/users
/api/v2/users
```

**Pros**: Clear, easy to route, cacheable

### Header Versioning

```
GET /users
Accept: application/vnd.myapp.v1+json
```

**Pros**: Clean URLs, content negotiation

## Authentication

### Bearer Token (Recommended)

```
Authorization: Bearer <token>
```

### API Key

```
X-API-Key: <key>
```

### OAuth 2.0

```
Authorization: Bearer <oauth_access_token>
```

## Rate Limiting

### Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000
```

### Response

```
429 Too Many Requests
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "retryAfter": 60
  }
}
```

## Idempotency

### Idempotency Keys

For non-idempotent operations (POST):
```
POST /payments
Idempotency-Key: unique-uuid
{
  "amount": 100,
  "currency": "USD"
}
```

**Implementation**:
- Store key + result
- Return cached result if key seen again
- Prevent duplicate charges

## Pagination

### Cursor-Based (For large datasets)

```
GET /posts?cursor=abc123&limit=20

Response:
{
  "data": [...],
  "pagination": {
    "nextCursor": "def456",
    "hasMore": true
  }
}
```

### Offset-Based (For smaller datasets)

```
GET /posts?page=2&per_page=20

Response:
{
  "data": [...],
  "pagination": {
    "page": 2,
    "perPage": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

## Error Handling

### Consistent Error Format

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "User with ID 123 not found",
    "timestamp": "2025-01-20T10:30:00Z",
    "path": "/users/123",
    "details": {}
  }
}
```

### Error Codes

Define standard codes:
```
VALIDATION_ERROR
AUTHENTICATION_REQUIRED
PERMISSION_DENIED
RESOURCE_NOT_FOUND
CONFLICT
RATE_LIMIT_EXCEEDED
INTERNAL_ERROR
```

## Security

### Input Validation

- Validate all inputs
- Sanitize data
- Use parameterized queries
- Limit request size

### Authentication/Authorization

- Require authentication
- Verify permissions
- Use HTTPS only
- Rotate tokens regularly

### Rate Limiting

- Prevent abuse
- Throttle by IP or user
- Return appropriate headers

## Documentation

### Essential Info

For each endpoint document:
- Method and path
- Description
- Request parameters
- Request body schema
- Response schema
- Status codes
- Example requests/responses
- Authentication requirements

### Example

```
GET /users/:id

Description: Get user by ID

Parameters:
  - id (path, required): User ID

Headers:
  - Authorization: Bearer token

Response:
  200 OK
  {
    "data": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }

Errors:
  401 - Unauthorized
  404 - User not found
```

## Best Practices Checklist

- [ ] Use nouns for resources
- [ ] Plural resource names
- [ ] Proper HTTP methods
- [ ] Appropriate status codes
- [ ] Consistent JSON structure
- [ ] Input validation
- [ ] Error handling
- [ ] Authentication
- [ ] Rate limiting
- [ ] Pagination for lists
- [ ] API versioning
- [ ] Documentation
- [ ] HTTPS only
- [ ] CORS configuration

## Remember

- Consistency is key
- Think from client perspective
- Design for evolution
- Document everything
- Security first
- Test all endpoints

## Customize

Add YOUR API conventions:
- Authentication method
- Error code scheme
- Response envelope format
- Pagination strategy
- Versioning approach
- Rate limiting rules
