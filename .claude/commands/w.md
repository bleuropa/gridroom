# Wrap Session

Alias for `/wrap`. End-of-session summary to preserve context before compaction.

## Steps

1. **Identify current task**:
   - Run `git branch --show-current` to get branch name
   - Extract task ID from branch (format: `type/T-YYYY-NNN-slug`)
   - If on main, check PROJECT_STATUS.md for active task

2. **Read context doc** at `vault/pm/_context/{TASK-ID}-context.md`
   - If doesn't exist, skip (no task in progress)

3. **Summarize this session** (2-4 bullet points):
   - Key decisions made
   - Problems solved
   - Progress on task checklist
   - Important discoveries or changes

4. **Update context doc**:
   - Add entry to "Implementation Notes" or create "Session Notes" section:
     ```markdown
     ## Session Notes

     ### {Date} Session
     - {Decision/progress point 1}
     - {Decision/progress point 2}
     - {Decision/progress point 3}
     ```

5. **Update PROJECT_STATUS.md** (if significant decisions):
   - Add any architectural or product decisions to "Key Decisions"
   - Update "Last Updated" timestamp

6. **Commit updates**:
   ```bash
   git add vault/pm/_context/{TASK-ID}-context.md PROJECT_STATUS.md
   git commit -m "docs: wrap session for {TASK-ID}

   {One-line summary of session progress}

   "
   ```

7. **Confirm to user**:
   - "✓ Session wrapped for {TASK-ID}"
   - Show what was captured (2-3 key points)

## Usage Patterns

### End of coding session
```
User: /w
You: Summarize progress, update context doc, commit
```

### Before context compaction
```
System: Approaching token limit...
User: /w
You: Capture state before compaction happens
```

### Before switching tasks
```
User: /w (then switch to other task)
You: Save current progress, ready for task switch
```

## Important Rules

- **Keep summaries concise**: 2-4 bullets, not paragraphs
- **Focus on decisions and blockers**: What matters for resuming work?
- **Don't rehash obvious progress**: "Fixed bug" is clear from commits
- **Capture non-obvious context**: Why we chose X over Y, what we learned
- **Be FAST**: This should take < 30 seconds to execute

## Example Output

```
✓ Session wrapped for T-2025-007

Captured:
- Decided to use JWT tokens (not sessions) for authentication - stateless scaling
- Discovered connection pooling could improve database throughput, worth exploring later
- Blockers: Need to finalize rate limiting strategy before full implementation

Context saved to vault/pm/_context/T-2025-007-context.md
```
