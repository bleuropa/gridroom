# Git Workflow

This document defines Git conventions for the your-project project. These conventions are enforced through automation (hooks, slash commands) to ensure consistency.

## Branch Naming

**Format**: `type/TASK-ID-slug`

### Types
- `feat/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring (no behavior change)
- `docs/` - Documentation changes
- `test/` - Test additions or updates
- `chore/` - Build, tooling, dependencies

### Examples
```
feat/T-2025-003-study-sessions
fix/B-2025-001-login-error
refactor/T-2025-010-db-cleanup
docs/T-2025-005-api-docs
```

### Rules
- Always include task ID (from vault/pm/tasks/)
- Use kebab-case for slug
- Keep slug short but descriptive (3-5 words max)
- Branch from `main` unless otherwise specified

## Commit Messages

**Format**: [Conventional Commits](https://www.conventionalcommits.org/)

```
type(scope): subject

[optional body]

[optional footer]
```

### Types
Same as branch types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Scope
Optional, typically:
- Component name: `feat(StudySession): add timer`
- Domain: `fix(auth): handle expired tokens`
- Omit if change is broad: `refactor: improve error handling`

### Subject
- Use imperative mood ("add feature" not "added feature")
- Lowercase first letter (except proper nouns)
- No period at end
- Max 50 characters

### Body
- Wrap at 72 characters
- Explain what and why, not how
- Separate from subject with blank line

### Footer
- Breaking changes: `BREAKING CHANGE: description`
- Issue references: `Closes #123`
- Always include co-author footer:
  ```
  ```

### Examples

**Simple commit**:
```
feat: add question difficulty scoring

```

**Complex commit**:
```
feat(api): implement user authentication

Add JWT-based authentication with bcrypt password hashing.
Includes login, logout, and token refresh endpoints.

Relates to T-2025-015

```

## Pull Request Workflow

### Creating PRs
1. Complete work on feature branch
2. Ensure all tests pass
3. Update relevant documentation
4. Run `/c` to close task and optionally create PR
5. PR title matches task name
6. PR description includes:
   - Summary of changes
   - Link to task: `Closes [[T-2025-XXX-task-name]]`
   - Testing notes
   - Screenshots/videos if UI changes

### PR Review Process
- Self-review first (use GitHub's "Files changed" tab)
- Request review from team (when applicable)
- Address feedback with new commits
- Squash commits when merging

### Merging
- **Squash and merge** - Combines all commits into one
- Final commit message should be clean and descriptive
- Delete branch after merge
- Update task status to completed in vault

## Linear History

We maintain a linear Git history by:
- Squashing commits in PRs
- Avoiding merge commits
- Rebasing feature branches if needed

**Benefits**:
- Clean, readable history
- Easy to bisect
- Simple to revert
- Clear changelog

## Task Lifecycle Integration

### Starting Work
```bash
/s T-2025-XXX
```
This:
1. Creates branch: `feat/T-2025-XXX-slug`
2. Updates task status to `in-progress`
3. Creates context doc if needed

### During Work
- Commit frequently with conventional format
- Update task checklist as you progress
- Update context doc for significant decisions

### Closing Work
```bash
/c
```
This:
1. Reviews task completion
2. Updates task status to `completed`
3. Optionally creates PR
4. Reminds to merge and delete branch

## Automation

### Pre-commit Hook
Validates:
- Commit message format (conventional commits)
- No merge conflicts
- No debug statements (console.log, debugger)

### Commands
- `/s <TASK-ID>` - Start task (creates branch, updates status)
- `/c` - Close task (reviews, updates status, optionally creates PR)
- `/p <TASK-ID>` - Plan task (creates task doc, breaks down work)
- `/ctx <note>` - Update context doc

## Common Patterns

### Working on Multiple Tasks
```bash
# Save current work
git add . && git commit -m "wip: save progress"

# Switch to new task
git checkout main
/s T-2025-XXX

# Return to original
git checkout feat/T-2025-YYY-slug
```

### Fixing Issues During PR Review
```bash
# Make changes
git add .
git commit -m "fix: address PR feedback"
git push
# Commits will be squashed on merge
```

### Updating Task Docs
```bash
# Edit vault/pm/tasks/T-2025-XXX.md
git add vault/pm/tasks/T-2025-XXX.md
git commit -m "docs: update task progress"
```

## Related Documentation
- [[Development Setup]] - Initial setup
- [[Using Obsidian Vault]] - PM workflow
- [[AGENTS.md]] - Claude Code guidance
