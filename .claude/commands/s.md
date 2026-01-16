# Start Task

You are starting work on a task. Follow this workflow:

## Steps

1. **Parse the task ID** from the user's input (format: T-YYYY-NNN)

2. **Read the task file** at `vault/pm/tasks/{TASK-ID}-*.md`
   - If file doesn't exist, inform user and ask if they want to create it with `/p`

3. **Create feature branch**:
   - Extract task type from task file (look for Epic/Story/Task/Bug tag)
   - Generate branch name: `{type}/{TASK-ID}-{slug}`
   - Type mapping: Task→feat, Bug→fix, Epic→feat, Story→feat
   - Slug from task title (kebab-case, 3-5 words max)
   - Create and checkout branch: `git checkout -b {branch-name}`

4. **Update task status**:
   - Change status in frontmatter from current to `in-progress`
   - Update `updated` date to today
   - Save file

5. **Check for context doc**:
   - Look for `vault/pm/_context/{TASK-ID}-context.md`
   - If doesn't exist, create from template:
     ```markdown
     # Context: {TASK-ID} {Title}

     **Task**: [[{TASK-ID}-{slug}]]
     **Created**: {today}
     **Status**: In Progress

     ## Overview
     {Brief description from task}

     ## Key Decisions
     -

     ## Implementation Notes
     -

     ## Next Steps
     -
     ```

6. **Update PROJECT_STATUS.md**:
   - Set "Current Focus" section:
     - Active Task: [[{TASK-ID}-{slug}]]
     - Branch: {branch-name}
     - Goal: {one-line description from task}
   - Update "Last Updated" timestamp to today
   - If task was in "Next Up", remove it from that list

7. **Commit the changes**:
   ```bash
   git add vault/pm/tasks/{TASK-ID}*.md \
           vault/pm/_context/{TASK-ID}*.md \
           PROJECT_STATUS.md
   git commit -m "chore: start work on {TASK-ID}

   ```

8. **Brief summary** (1-2 lines max):
   - "Started {TASK-ID} on branch {branch-name}"

9. **Immediately begin implementation**:
   - Read the context doc and task acceptance criteria
   - Start working on the first implementation step
   - Do NOT ask "shall I proceed?" or "ready to start?" - just start working
   - The user called `/s` because they want implementation to begin NOW

## Important Rules
- DO NOT ask user for confirmation at each step - execute the workflow
- If task file doesn't exist, STOP and suggest using `/p` to plan first
- Keep branch name short but descriptive
- Always commit the status changes
- Be efficient - this should take < 10 seconds

## Example

User: `/s T-2025-003`

You:
1. Read vault/pm/tasks/T-2025-003-study-sessions.md
2. Create branch: `git checkout -b feat/T-2025-003-study-sessions`
3. Update status to in-progress, updated to 2025-11-18
4. Create vault/pm/_context/T-2025-003-context.md
5. Commit changes
6. Output: "✓ Started T-2025-003 on branch feat/T-2025-003-study-sessions"
