---
description: Audit and sync project management state
---

# Project Grooming

Run a full audit of project management state and fix inconsistencies.

## Steps

### 1. Sync PROJECT_STATUS.md

Read all task files to understand actual state:

```bash
# List all task files
ls vault/pm/tasks/*.md

# For each, extract status from frontmatter
grep -l "status:" vault/pm/tasks/*.md | while read f; do
  grep "status:" "$f" | head -1
done
```

Compare with PROJECT_STATUS.md sections:
- **Current Focus**: Should match an in-progress task
- **Next Up**: Should list pending/backlog tasks
- **Recently Completed**: Should match completed tasks

Report mismatches:
- Task file says "completed" but still in "Current Focus"
- Task in "Next Up" but file says "completed"
- Task in "Current Focus" but file says "pending"

### 2. Identify Stale Tasks

Check for tasks that may need attention:

**In-progress but inactive:**
```bash
# Find tasks marked in-progress
grep -l "status: in-progress" vault/pm/tasks/*.md

# For each, check last commit touching the file
git log -1 --format="%ar" -- vault/pm/tasks/T-*.md
```

Flag if:
- Status is "in-progress" but no commits in 7+ days
- Status is "pending" and created 30+ days ago

**Orphaned context docs:**
```bash
# Find context docs
ls vault/pm/_context/*-context.md

# For each, check if matching task file exists
for ctx in vault/pm/_context/*-context.md; do
  task_id=$(basename "$ctx" | sed 's/-context.md//')
  if ! ls vault/pm/tasks/${task_id}*.md 2>/dev/null; then
    echo "Orphan: $ctx"
  fi
done
```

### 3. Check Branch Alignment

```bash
# Current branch
git branch --show-current

# Extract task ID from branch name
git branch --show-current | grep -oE 'T-[0-9]+-[0-9]+'
```

Verify:
- If on a task branch, that task should be in "Current Focus"
- If on main, "Current Focus" should be empty or say "No active task"

Check for orphan branches:
```bash
# List feature branches
git branch | grep -E 'feat/|fix/|chore/'

# For each, verify task file exists
```

### 4. Validate Hierarchies

For tasks with `children: []` in frontmatter:
- Verify each child task file exists
- Verify each child's `parent:` points back correctly

For tasks with `parent:` field:
- Verify parent task file exists
- Verify parent's `children:` includes this task

### 5. Report & Interactive Fix

Present findings in this format:

```markdown
## Grooming Report

### Sync Issues (X found)
| Task | Issue | Current | Should Be | Action |
|------|-------|---------|-----------|--------|
| T-2025-029 | STATUS mismatch | "Current Focus" | completed in file | [Fix/Skip] |

### Stale Tasks (X found)
| Task | Status | Last Activity | Suggestion | Action |
|------|--------|---------------|------------|--------|
| T-2025-025 | in-progress | 14 days ago | Close or continue? | [Close/Defer/Skip] |

### Orphans (X found)
| File | Type | Suggestion | Action |
|------|------|------------|--------|
| vault/pm/_context/T-2025-019-context.md | Context doc | No task file | [Delete/Skip] |

### Hierarchy Issues (X found)
| Task | Issue | Action |
|------|-------|--------|
| T-2025-029.1 | Parent doesn't list in children | [Fix/Skip] |
```

Use AskUserQuestion to get user decisions for each category.

### 6. Apply Fixes

For approved fixes:
- Update task file status
- Update PROJECT_STATUS.md sections
- Delete orphaned files (if approved)
- Fix hierarchy references

Commit all grooming changes:
```bash
git add vault/pm/ PROJECT_STATUS.md
git commit -m "chore: project grooming

- Fixed X sync issues
- Closed X stale tasks
- Removed X orphaned files
- Fixed X hierarchy issues"
```

## Output Summary

After grooming:
```
✓ Grooming complete

Fixed:
- 3 sync issues (PROJECT_STATUS.md updated)
- 1 stale task (T-2025-025 closed)
- 1 orphan removed (T-2025-019-context.md)
- 0 hierarchy issues

Skipped:
- 1 stale task (T-2025-028 - user chose to continue)

PROJECT_STATUS.md is now in sync with task files.
```

## Notes

- Run `/groom` periodically (weekly or when things feel out of sync)
- This is safe - always asks before making changes
- Commit is automatic after fixes (can be reverted if needed)
