---
argument-hint: [task-id (optional)]
description: Close a task (updates status, merges to main)
---

# Close Task

Check the `<command-args>` tag for an optional task ID.

You are closing out a task. Follow this workflow:

## Steps

1. **Identify task to close**:
   - If task ID provided in `<command-args>`, use that
   - Otherwise, run `git branch --show-current` to get branch name
   - Extract task ID from branch name (format: `type/T-YYYY-NNN-slug`)
   - If not on a task branch and no ID provided, ask user which task to close

2. **Read task file** at `vault/pm/tasks/{TASK-ID}-*.md`

3. **Check for open children** (CRITICAL FOR HIERARCHICAL TASKS):
   - Read the `children: []` array from task frontmatter
   - For each child ID, check its status in `vault/pm/tasks/{CHILD-ID}-*.md`
   - If ANY children have status other than `completed` or `deferred`:
     - List open children:
       > "Cannot close T-2025-029. Open subtasks:
       >
       > - T-2025-029.1 (in-progress): Fix validation bug
       > - T-2025-029.2 (pending): Add filters"
     - Offer options:
       > "Options:
       >
       > 1. Complete the subtasks first
       > 2. Defer open subtasks to new tasks (creates linked tasks)
       > 3. Force close (marks subtasks as abandoned - not recommended)"
   - If user chooses defer:
     - For each deferred subtask, create new root task with link to original
     - Mark subtask as `deferred` with link to new task
   - If all children are `completed` or `deferred`, proceed to step 4

4. **Review completion**:
   - Check acceptance criteria - are they all checked?
   - Check review checklist - is it complete?
   - If not all done, show user what's missing and ask if they want to continue

5. **Update task file**:
   - Change status from `in-progress` to `completed`
   - Set `completed` field to today's date
   - Update `updated` field to today
   - Ensure all acceptance criteria boxes are checked (if user confirmed complete)
   - Ensure all review checklist boxes are checked

6. **Update parent task** (if closing a subtask):
   - Check if task has a `parent` field in frontmatter
   - If parent exists:
     - Read parent task file
     - Check the checkbox in parent's `## Subtasks` section: `- [x] [[T-2025-029.1-*]]`
     - Update parent's `updated` field to today

7. **Update context doc** (if exists):
   - Add final entry to context doc at `vault/pm/_context/{TASK-ID}-context.md`
   - Append to "Next Steps" or create "Completion Notes" section:

     ```markdown
     ## Completion Notes

     **Completed**: {today}
     **Outcome**: {1-sentence summary}

     All acceptance criteria met. Task closed.
     ```

8. **Sync PROJECT_STATUS.md**:
   - For root tasks: Remove from "Current Focus", add to "Recently Completed"
   - For subtasks: Update status under parent (e.g., "- ~~T-2025-029.1~~: completed")
   - Remove task from "Next Up" if it was there
   - Update "Last Updated" timestamp to today

9. **Commit task completion**:

```bash
git add vault/pm/tasks/{TASK-ID}*.md \
        vault/pm/tasks/{PARENT-ID}*.md \  # if subtask
        vault/pm/_context/{TASK-ID}*.md \
        PROJECT_STATUS.md
git commit -m "chore: complete {TASK-ID}

{Brief summary of what was accomplished}

"
```

10. **Ask about PR**:

- "Create pull request? (yes/no)"
- If yes:
  - Generate PR title from task name
  - Generate PR body with summary and link to task
  - Run: `gh pr create --title "{title}" --body "{body}"`
  - Show PR URL to user
- If no, remind user to merge manually when ready

11. **Remind about cleanup**:
    - After PR is merged, delete branch: `git branch -d {branch-name}`
    - Switch back to main: `git checkout main && git pull`

## Important Rules

### Hierarchical Tasks

- **ALWAYS check children before closing a parent task**
- Parent cannot close while children are `pending`, `in-progress`, or `backlog`
- Children must be `completed` or `deferred` to close parent
- When closing a subtask, update parent's Subtasks checkbox
- Offer defer option to move incomplete subtasks to new root tasks

### General

- DO check completion status before marking as done
- DO ask user if criteria aren't met
- DO create comprehensive commit message
- ASK user about PR creation (don't assume)
- Keep output concise and clear

## Examples

### Example 1: Root Task (no children)

User: `/c`

You:

1. Current branch: `feat/T-2025-003-user-authentication`
2. Task ID: T-2025-003
3. Check children: none
4. Read task file, check acceptance criteria (all done)
5. Update status to completed, completed: 2025-11-30
6. Update context doc with completion notes
7. Sync PROJECT_STATUS.md
8. Commit changes
9. Ask: "Create pull request? (yes/no)"
10. Output: "Task T-2025-003 completed and committed"

### Example 2: Closing Subtask

User: `/c T-2025-029.1`

You:

1. Task ID: T-2025-029.1
2. Check acceptance criteria (all done)
3. Update subtask status to completed
4. **Update parent T-2025-029**:
   - Check checkbox: `- [x] [[T-2025-029.1-fix-validation-bug]]`
   - Update parent's `updated` field
5. Update PROJECT_STATUS.md (mark under parent as completed)
6. Commit changes (include both subtask and parent files)
7. Output:

```
Subtask T-2025-029.1 completed

Updated:
- vault/pm/tasks/T-2025-029.1-fix-validation-bug.md (completed)
- vault/pm/tasks/T-2025-029-user-dashboard.md (subtask checkbox)
- PROJECT_STATUS.md

Parent T-2025-029 has 1 remaining subtask:
- T-2025-029.2 (pending): Add filters
```

### Example 3: Parent with Open Children

User: `/c`
Branch: `feat/T-2025-029-user-dashboard`

You:

1. Task ID: T-2025-029
2. Check children: T-2025-029.1 (completed), T-2025-029.2 (pending)
3. **Block**: Cannot close - open subtasks exist

Output:
```
Cannot close T-2025-029. Open subtasks:
- T-2025-029.2 (pending): Add filters

Options:
1. Complete the subtasks first
2. Defer T-2025-029.2 to new task (creates linked task)
3. Force close (marks subtasks as abandoned)

What would you like to do?
```
