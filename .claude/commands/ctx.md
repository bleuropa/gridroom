# Update Context

Quickly append to the current task's context document.

## Steps

1. **Identify current task**:
   - Run `git branch --show-current` to get branch name
   - Extract task ID from branch (format: `type/T-YYYY-NNN-slug`)
   - If not on task branch, ask user which task

2. **Read context doc** at `vault/pm/_context/{TASK-ID}-context.md`
   - If doesn't exist, inform user and offer to create it

3. **Determine what to update**:
   - If user provided specific note: append to relevant section
   - If user just said `/ctx`: ask what to add or summarize recent work

4. **Update context doc**:
   - Add timestamp entry to appropriate section:
     - Decisions → "Key Decisions"
     - Problems/solutions → "Challenges & Solutions"
     - General progress → "Implementation Notes"
     - Questions → "Open Questions"
   - Format:
     ```markdown
     - **{timestamp}**: {note}
     ```

5. **Update PROJECT_STATUS.md (if significant decision)**:
   - If note is a key architectural or product decision, add to "Key Decisions" section
   - Update "Last Updated" timestamp
   - Otherwise, skip (not all context updates are project-level decisions)

6. **Commit update**:
   ```bash
   # Only add PROJECT_STATUS.md if it was updated
   git add vault/pm/_context/{TASK-ID}-context.md
   [git add PROJECT_STATUS.md]  # if updated
   git commit -m "docs: update {TASK-ID} context

   {Brief description of update}

   ```

7. **Confirm to user**: "✓ Updated context for {TASK-ID}"

## Usage Patterns

### Add decision
```
User: /ctx Decided to use JWT tokens over sessions for stateless scaling
You: Append to "Key Decisions" section with timestamp
```

### Add challenge/solution
```
User: /ctx Had issues with database migrations, solved by using transactions properly
You: Append to "Challenges & Solutions" section
```

### Add question
```
User: /ctx Should we use sessions or JWT tokens for auth?
You: Append to "Open Questions" section
```

### Quick update
```
User: /ctx
You: "What would you like to add to the context?" or auto-generate from recent work
```

## Important Rules
- Keep updates concise (1-3 sentences)
- Always include timestamp or date
- Organize by section type (decisions vs notes vs questions)
- Commit immediately after update
- Be FAST - this should take < 5 seconds

## Auto-generation (advanced)

If user runs `/ctx` without note and there's significant uncommitted work:
1. Check git status for modified files
2. Summarize changes in 1-2 sentences
3. Append to "Implementation Notes"
4. Ask user to review before committing

## Example

User: `/ctx Implemented basic review interval calculation`

You:
1. Current branch: feat/T-2025-003-spaced-repetition
2. Task ID: T-2025-003
3. Append to Implementation Notes:
   ```markdown
   - **2025-11-18 14:30**: Implemented basic review interval calculation
   ```
4. Commit: "docs: update T-2025-003 context"
5. Output: "✓ Updated context for T-2025-003"
