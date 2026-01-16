---
description: Escape hatch - bypass PM hooks for this prompt
---

# Escape Hatch Mode

This command signals that the current work should NOT trigger project management workflows.

The user invoked `/x` - this is their escape hatch. Do NOT:
- Suggest creating a task
- Run the `/p` command
- Remind them about task tracking
- Inject PM-related guidance

Instead, just help them with whatever follows the `/x` command directly.

## When Users Use This

- Quick analysis or exploration
- Ideation and brainstorming
- One-off questions
- Research that doesn't need tracking
- Ad-hoc debugging or investigation

## Behavior

1. The user-prompt-submit hook recognizes `/x` and passes through without task-enforcement
2. You proceed normally with Claude Code assistance
3. Next prompt returns to normal PM tracking (this is per-prompt only)

## What to Do Now

Check `<command-args>` for what the user wants help with and assist them directly. No task creation needed.
