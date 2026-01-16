# Quick Status Check

Provide a concise project status overview.

## Steps

1. **Read PROJECT_STATUS.md** (root of repo)
   - This is the ONLY file you need to read
   - DO NOT read task files, vault docs, or scan git history

2. **Summarize in 4 sections**:

   **Current Focus**: What task is active? What's the goal?

   **Recent Progress**: Last 2-3 completed tasks

   **Next Up**: Top 2-3 priorities

   **Blockers**: Any open questions or blockers (if present)

3. **Keep it brief**: Target ~100 words total

## Example Output

```
Current Focus: T-2025-007 (User Authentication)
Goal: Implement JWT-based authentication with login/logout

Recent Progress:
✅ API endpoints for user CRUD operations
✅ Database schema with user table
✅ Basic frontend scaffolding

Next Up:
1. Complete authentication flow with password reset
2. Add email verification
3. Implement role-based access control

Blockers: None
```

## Important Rules

- **Token efficiency**: This command exists to give quick status with minimal token cost
- **No exploration**: Don't read anything except PROJECT_STATUS.md
- **No assumptions**: If PROJECT_STATUS.md is outdated or missing info, say so
- **Fast response**: Should take < 5 seconds to execute
