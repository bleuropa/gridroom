---
argument-hint: [work description]
description: Plan a new work item (Epic/Story/Task/Bug)
---

# Plan Work Item

The user called this command. Check the conversation context for `<command-args>` tag to see what they want to work on.

If the arguments are empty or this looks like a question/complaint (not a work request), abort and respond normally.

Otherwise, use the arguments as the work description and proceed with planning.

---

## Classification Decision (CRITICAL FIRST STEP)

**Before creating anything, classify the work item:**

### Decision Tree

1. **Epic?** Only if ALL of these are true:
   - 5+ child tasks/stories ALREADY CREATED (not planned)
   - Multiple major components (not just phases)
   - Timeline > 2 weeks
   - System-wide impact
   - **If unsure → NOT an Epic** (default to Task)

2. **Story?** Only if:
   - User-facing feature with clear acceptance criteria
   - Has UI/UX work
   - NOT just technical implementation
   - Example: "Add authentication flow", "Enable file uploads"
   - **If unsure → Task** (Stories are optional, Tasks are not)

3. **Bug?** Only if:
   - Fixing existing broken behavior
   - NOT adding new features
   - NOT refactoring or improvements

4. **Task?** (Default)
   - Implementation work
   - Technical improvements
   - Anything that doesn't fit above categories
   - **When in doubt, choose Task**

### Anti-Patterns to Avoid

- Creating Epic before child work items exist
- "This sounds big" → Epic (check if it's 1 big Task or 10+ small Tasks)
- "I wrote a design doc" → Epic (design doc is Task output)
- Inventing new ID prefixes (always check existing patterns)

## Steps

1. **Classify work item type** (Epic/Story/Task/Bug):
   - Analyze user's description using decision tree above
   - If Epic-like, ask user: "This sounds large. Have you already created 5+ child tasks? If not, should I create this as a Task?"
   - If Story-like but ambiguous, ask: "Is this user-facing or purely technical?"
   - Default to Task when uncertain

2. **Verify ID prefix pattern**:
   - Check existing patterns BEFORE generating ID:
     ```bash
     # For Epic
     ls vault/pm/epics/ 2>/dev/null | grep -o '^[A-Z]*-' | sort -u
     # For Story
     ls vault/pm/stories/ 2>/dev/null | grep -o '^[A-Z]*-' | sort -u
     # For Task
     ls vault/pm/tasks/ 2>/dev/null | grep -o '^[A-Z]*-' | sort -u
     # For Bug
     ls vault/pm/bugs/ 2>/dev/null | grep -o '^[A-Z]*-' | sort -u
     ```
   - **Known patterns:**
     - Epic: `E-YYYY-NNN`
     - Story: `US-YYYY-NNN`
     - Task: `T-YYYY-NNN`
     - Bug: `BUG-YYYY-NNN`

3. **Get work item details** from user input:
   - Work item ID (if provided) or generate next using correct prefix
   - Title/description
   - Priority (p0/p1/p2/p3)
   - Linked story or epic (if any)

4. **Check for parent task context** (SUBTASK SUPPORT):
   - Check current git branch: `git branch --show-current`
   - If on a task branch (e.g., `feat/T-2025-029-*`), extract parent task ID
   - Check PROJECT_STATUS.md "Current Focus" for active parent task
   - If parent context exists, ask user:
     > "Create as subtask of T-2025-029? (yes/no)"
   - If yes → generate subtask ID (see step 5a)
   - If no → generate root task ID (see step 5b)

5a. **Generate SUBTASK ID** (if creating under parent):

- Find highest existing child for this parent:
  ```bash
  # For parent T-2025-029, find children like T-2025-029.1, T-2025-029.2
  ls vault/pm/tasks/ | grep -E 'T-2025-029\.[0-9]+' | sort -t. -k3 -n | tail -1
  ```
- If no children exist → `{PARENT}.1`
- Otherwise increment: `T-2025-029.3` → `T-2025-029.4`
- For nested subtasks: `T-2025-029.1.1`, `T-2025-029.1.2`
- Set `parent` field in frontmatter to parent task ID
- Update parent task's `children` array and `## Subtasks` section

5b. **Generate ROOT TASK ID** (no parent):

- Find highest existing number for the work item type:
  ```bash
  # For Task (exclude subtasks with dots)
  ls vault/pm/tasks/ | grep -E 'T-[0-9]+-[0-9]+' | grep -v '\.' | sort -u | tail -1
  # For Epic
  ls vault/pm/epics/ 2>/dev/null | grep -o 'E-[0-9]*-[0-9]*' | sort -u | tail -1
  # For Story
  ls vault/pm/stories/ 2>/dev/null | grep -o 'US-[0-9]*-[0-9]*' | sort -u | tail -1
  # For Bug
  ls vault/pm/bugs/ 2>/dev/null | grep -o 'BUG-[0-9]*-[0-9]*' | sort -u | tail -1
  ```
- Increment by 1 for new ID
- Leave `parent` field empty in frontmatter
- **IMPORTANT**: Use the correct folder based on type!

6. **Create work item file** at appropriate location:
   - Epic: `vault/pm/epics/{ID}-{slug}.md` (use `vault/_templates/Epic.md`)
   - Story: `vault/pm/stories/{ID}-{slug}.md` (use `vault/_templates/Story.md`)
   - Task: `vault/pm/tasks/{ID}-{slug}.md` (use `vault/_templates/Task.md`)
   - Bug: `vault/pm/bugs/{ID}-{slug}.md` (use `vault/_templates/Bug.md`)

   **Fill in template:**
   - Frontmatter: tags, status (todo/backlog), priority, created date
   - Details section with ID, priority, created date
   - Description from user input
   - Acceptance criteria (3-5 items based on description)
   - For Epics: Add "Components" section grouping existing child work items
   - Leave other sections as placeholders

7. **Create context doc** (or use parent's for subtasks):
   - **Subtasks**: By default, share parent's context doc. Append with headers:

     ```markdown
     ## T-2025-029.1: {Subtask Title}

     {Subtask-specific notes}
     ```

   - **Root tasks**: Create new context doc at `vault/pm/_context/{ID}-context.md`:
   - Start with basic structure:

     ```markdown
     # Context: {TASK-ID} {Title}

     **Task**: [[{TASK-ID}-{slug}]]
     **Created**: {today}
     **Status**: Planning

     ## Overview

     {Expand on task description}

     ## Key Decisions

     -

     ## Implementation Plan

     {If user wants breakdown, add steps here}

     ## Open Questions

     -

     ## Next Steps

     1. Review plan with user
     2. Run `/s {TASK-ID}` to start work
     ```

8. **Break down work** (if requested):
   - Add implementation steps to context doc
   - Identify files that will need changes
   - List dependencies
   - Estimate complexity

9. **Sync PROJECT_STATUS.md**:
   - For root tasks: Add to "Next Up" section if user intends to work on it soon
   - For subtasks: Add under parent in "Current Focus" with indent:

     ```markdown
     ## Current Focus

     **T-2025-029**: Build user dashboard - IN PROGRESS

     - **T-2025-029.1**: Fix loading issue - pending
     - **T-2025-029.2**: Add filters - pending
     ```

   - Update "Last Updated" timestamp to today

10. **Update parent task** (if subtask):
    - Add child ID to parent's `children: []` frontmatter array
    - Add checkbox line to parent's `## Subtasks` section:
      ```markdown
      - [ ] [[T-2025-029.1-fix-loading-issue]] - Fix loading issue
      ```

11. **Commit work item creation**:

```bash
# Add files from appropriate folder (epics/stories/tasks/bugs)
git add vault/pm/{folder}/{ID}*.md \
        vault/pm/_context/{ID}*.md \
        PROJECT_STATUS.md
git commit -m "chore: create {type} {ID}

{Title}

"
```

12. **Summary output**:

- Show work item type and ID
- Show file location
- Show context doc location
- Suggest next step: `/s {ID}` to start work

## Important Rules

### Classification

- **ALWAYS classify first** using the decision tree
- **ALWAYS check ID prefixes** before generating new IDs
- **Default to Task when unsure** (easier to promote than demote)
- **Ask user when Epic-like** to verify child work exists
- **Never invent new prefixes** - use existing patterns

### File Creation

- **ALWAYS create both work item file AND context doc**
- **Use correct folder** for work item type (epics/stories/tasks/bugs)
- **Use correct template** for work item type
- Generate clear acceptance criteria (3-5 items)
- Keep work item doc structured (use template)
- Context doc can be more free-form for planning

### Subtasks

- **Check for parent context** before creating any new task
- **Subtask IDs use dot notation**: T-2025-029.1, T-2025-029.2, T-2025-029.1.1
- **Subtasks share parent's context doc** by default (append with headers)
- **Update parent's children array** and Subtasks section when creating
- **Subtasks go in same folder** as root tasks (vault/pm/tasks/)
- **Branch naming stays flat**: Use parent's branch for subtask work

### Workflow

- Commit immediately after creation
- Update PROJECT_STATUS.md if relevant
- Be efficient - don't overthink the initial plan
- Suggest `/s {ID}` to start work

## Examples

### Example 1: Root Task

User: `/p Add user authentication`

You:

1. **Classify**: Multi-step feature work → **Task**
2. **Check prefix**: `ls vault/pm/tasks/` → T- prefix confirmed
3. **Find next ID**: Highest is T-2025-002 → **T-2025-003**
4. **Create task file**: `vault/pm/tasks/T-2025-003-user-authentication.md`
5. **Create context doc**: `vault/pm/_context/T-2025-003-context.md`
6. **Commit**
7. **Output**:

   ```
   Created Task T-2025-003-user-authentication

   Type: Task (feature implementation)
   Files:
   - vault/pm/tasks/T-2025-003-user-authentication.md
   - vault/pm/_context/T-2025-003-context.md

   Next: /s T-2025-003 to start work
   ```

### Example 2: Subtask (on existing task branch)

User: `/p Fix validation bug`
Branch: `feat/T-2025-029-user-dashboard`

You:

1. **Detect parent context**: Branch is `feat/T-2025-029-*` → parent is T-2025-029
2. **Ask**: "Create as subtask of T-2025-029? (yes/no)"
3. **User says yes** → generate subtask ID
4. **Find next child**: `ls vault/pm/tasks/ | grep 'T-2025-029\.'` → none exist → **T-2025-029.1**
5. **Create subtask file**: `vault/pm/tasks/T-2025-029.1-fix-validation-bug.md`
   - Set `parent: T-2025-029` in frontmatter
6. **Update parent file**: Add to children array and Subtasks section
7. **Append to parent's context doc**: `vault/pm/_context/T-2025-029-context.md`
8. **Update PROJECT_STATUS.md**: Add under parent with indent
9. **Commit**
10. **Output**:

```
Created Subtask T-2025-029.1-fix-validation-bug

Type: Subtask of T-2025-029
Files:
- vault/pm/tasks/T-2025-029.1-fix-validation-bug.md
- Context: Using parent's vault/pm/_context/T-2025-029-context.md

Parent updated:
- Added to T-2025-029 children array
- Added to T-2025-029 Subtasks section

Next: Continue on current branch (no /s needed for subtasks)
```
