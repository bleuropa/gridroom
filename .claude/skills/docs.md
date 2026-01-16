---
name: docs
description: Writing clear, maintainable documentation. Covers code comments, API docs, guides, and vault documents.
---

# Documentation Writing Skill

Guidelines for writing clear, useful documentation that stays current and serves both humans and AI agents.

## Documentation Types

### 1. Code Comments

**When to comment**:
- ✅ Why (not what) - Explain reasoning
- ✅ Complex algorithms
- ✅ Non-obvious solutions
- ✅ Workarounds for bugs
- ✅ Performance considerations

**When NOT to comment**:
- ❌ Obvious code
- ❌ What code does (code shows this)
- ❌ Redundant information
- ❌ Outdated information

**Examples**:

❌ **Bad**:
```javascript
// Increment counter by 1
counter++

// Loop through users
for (const user of users) {
  // ...
}
```

✅ **Good**:
```javascript
// Use exponential backoff to avoid overwhelming the API
// during high traffic periods
await retryWithBackoff(apiCall)

// Binary search requires sorted array - we sort here rather
// than on every call for better performance
const sorted = items.sort()
```

### 2. Function/Class Documentation

**Structure**:
```javascript
/**
 * Calculate the compound interest for an investment.
 *
 * @param principal - Initial investment amount
 * @param rate - Annual interest rate (as decimal, e.g., 0.05 for 5%)
 * @param years - Number of years
 * @returns Final amount including principal and interest
 *
 * @example
 * calculateCompoundInterest(1000, 0.05, 10)
 * // returns 1628.89
 */
function calculateCompoundInterest(principal, rate, years) {
  return principal * Math.pow(1 + rate, years)
}
```

### 3. API Documentation

**For each endpoint**:
- Purpose and use case
- Authentication requirements
- Request format
- Response format
- Possible errors
- Example requests/responses

**Example**:
```markdown
## POST /api/users

Creates a new user account.

**Authentication**: Required (Bearer token)

**Request Body**:
\`\`\`json
{
  "name": "John Doe",
  "email": "john@example.com",
  "role": "user"  // optional, defaults to "user"
}
\`\`\`

**Response**:
\`\`\`json
{
  "data": {
    "id": 123,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "createdAt": "2025-01-20T10:30:00Z"
  }
}
\`\`\`

**Errors**:
- 400 - Invalid input (email format, etc.)
- 401 - Not authenticated
- 409 - Email already exists
```

### 4. README Files

**Essential sections**:
```markdown
# Project Name

Brief description (1-2 sentences)

## Quick Start

\`\`\`bash
npm install
npm run dev
\`\`\`

## What It Does

More detailed explanation

## Key Features

- Feature 1
- Feature 2

## Documentation

- [Architecture](docs/architecture.md)
- [API Reference](docs/api.md)
- [Contributing](CONTRIBUTING.md)

## Tech Stack

- Framework
- Database
- Key libraries

## License

MIT
```

### 5. Vault Documents (Balustrade Pattern)

**Evergreen docs** (product/, architecture/, features/):
```markdown
# Feature: User Authentication

**Purpose**: Secure user account management

## Overview
[Timeless description of how auth works]

## Components
- JWT tokens for stateless auth
- bcrypt for password hashing
- Refresh token rotation

## Flow
[Diagram or description]

## Related
- [[System Architecture]]
- [[Security Guidelines]]
```

**PM docs** (pm/tasks, pm/_context):
```markdown
# Task: T-2025-007

**Status**: In Progress
**Priority**: High

## Description
[What needs to be done]

## Checklist
- [ ] Step 1
- [ ] Step 2

## Context
See [[T-2025-007-context]] for decisions and notes.
```

## Writing Style

### Be Clear and Concise

❌ **Verbose**:
"The function that we have implemented here is designed for the purpose of taking into consideration the various parameters that have been provided to it and then proceeding to calculate..."

✅ **Concise**:
"Calculates compound interest using principal, rate, and years."

### Use Active Voice

❌ **Passive**: "The data is processed by the server"
✅ **Active**: "The server processes the data"

### Be Specific

❌ **Vague**: "Update the thing when needed"
✅ **Specific**: "Update the cache when user preferences change"

### Use Examples

Show, don't just tell:
```markdown
## Usage

\`\`\`javascript
// Create a user
const user = await createUser({
  name: 'John',
  email: 'john@example.com'
})

// Update user
await updateUser(user.id, {
  name: 'John Doe'
})
\`\`\`
```

## Structuring Documents

### Use Headings Hierarchy

```markdown
# Main Title (H1) - One per document

## Major Section (H2)

### Subsection (H3)

#### Detail (H4)
```

### Add Table of Contents (for long docs)

```markdown
## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Reference](#api-reference)
```

### Use Lists for Scanability

❌ **Wall of text**:
"The system requires Node.js version 18 or higher and also needs PostgreSQL version 14 or later and you'll also need Redis for caching..."

✅ **List**:
**Requirements**:
- Node.js 18+
- PostgreSQL 14+
- Redis 6+

## Documentation Best Practices

### 1. Keep It Current

- Update docs with code changes
- Review docs quarterly
- Remove outdated information
- Use automated tools where possible

### 2. Make It Discoverable

- Link related documents
- Use consistent naming
- Create clear navigation
- Add search functionality

### 3. Write for Your Audience

**For developers**:
- Technical details
- Code examples
- API references

**For end users**:
- Plain language
- Screenshots
- Step-by-step guides

**For AI agents**:
- Atomic notes (one concept per file)
- Rich internal linking
- Clear structure
- Complete context

### 4. Use Diagrams

When helpful, add visual explanations:
```markdown
## Authentication Flow

\`\`\`
User → Frontend → API → Database
                     ↓
                   JWT Token
                     ↓
                   User
\`\`\`
```

## Balustrade Vault Patterns

### Atomic Notes

One concept per file:
```markdown
# JWT Authentication

[Complete explanation of JWT auth in this file]

## Related
- [[Session Management]] - Alternative approach
- [[Security Best Practices]] - Implementation guide
```

### Rich Linking

Connect related concepts:
```markdown
# User Management Feature

Implements [[Authentication]] and [[Authorization]].

Uses [[PostgreSQL Database]] for storage.

See [[System Architecture#User Module]] for technical design.
```

### Evergreen vs Temporal

**Evergreen** (product/, architecture/, features/):
- Describe current state
- No "will", "soon", "planned"
- Update when reality changes

**Temporal** (pm/):
- Track progress and status
- Use temporal language freely
- Link to evergreen docs

## Documentation Checklist

Before publishing:
- [ ] Clear purpose/overview
- [ ] Examples included
- [ ] Technical details accurate
- [ ] Links work
- [ ] Code samples tested
- [ ] Grammar/spelling checked
- [ ] Reviewed by another person
- [ ] Accessible to target audience

## Common Mistakes

❌ **Don't**:
- Write docs that duplicate code
- Use jargon without explanation
- Skip examples
- Let docs get outdated
- Write for yourself only

✅ **Do**:
- Explain "why" not just "what"
- Define terms clearly
- Show concrete examples
- Keep docs current
- Write for your audience

## Tools and Automation

### Generate API Docs

Use tools like:
- Swagger/OpenAPI
- JSDoc
- TypeDoc
- Sphinx (Python)
- Rustdoc

### Lint Documentation

- Check spelling
- Verify links
- Validate code examples
- Check style consistency

### Version Documentation

- Version with code
- Keep old versions accessible
- Note breaking changes
- Migration guides

## Remember

- Documentation is code
- Update docs with features
- Write for humans AND agents
- Examples are valuable
- Less is more (be concise)
- Keep it current

## Customize

Add YOUR documentation standards:
- Doc templates
- Style guide
- Review process
- Tools and automation
- Hosting/publishing
- Maintenance schedule
