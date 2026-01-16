#!/bin/bash
# UserPromptSubmit hook - Auto-creates tasks for new work
# Injects system reminders using the official hookSpecificOutput format

# Read the user's prompt from stdin
PROMPT=$(cat)

# Always pass through slash commands unchanged
if echo "$PROMPT" | grep -qE '^/'; then
  echo "$PROMPT"
  exit 0
fi

# Check if prompt suggests starting new work
# Keywords: "let's", "proceed", "start", "implement", "add", "create", "build", "fix"
if echo "$PROMPT" | grep -qiE "(let'?s|proceed|start|implement|add|create|build|work on|next|begin|fix)"; then
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

  # Check for active task context from multiple sources:
  # 1. Current Focus in PROJECT_STATUS.md (includes hierarchical task tree)
  ACTIVE_TASK=$(grep -A 1 "## Current Focus" "$GIT_ROOT/PROJECT_STATUS.md" 2>/dev/null | tail -1)

  # 2. Git branch (e.g., feat/T-2025-029-validate-nike → T-2025-029 is active parent)
  BRANCH_TASK=$(git branch --show-current 2>/dev/null | grep -oE 'T-[0-9]+-[0-9]+' | head -1)

  # If no active task in either PROJECT_STATUS.md OR git branch, require task creation
  # Note: Being on a task branch (T-2025-029) means we're in parent task context
  # and can create subtasks via /p without needing a new root task
  HAS_ACTIVE_CONTEXT=false
  if [ -n "$BRANCH_TASK" ]; then
    HAS_ACTIVE_CONTEXT=true
  elif [ -n "$ACTIVE_TASK" ] && ! echo "$ACTIVE_TASK" | grep -qiE "(none|setting up|no active)"; then
    HAS_ACTIVE_CONTEXT=true
  fi

  if [ "$HAS_ACTIVE_CONTEXT" = false ]; then
    # Output JSON with hookSpecificOutput (the documented way to inject context)
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "🔔 **Auto-Task Creation Required**\n\nThe user is starting new work without an active task. Before responding:\n\n1. Run `/p` with a description based on their request\n2. Wait for the task to be created (files + commit)\n3. Then proceed with their actual request\n\nThis is REQUIRED - do not skip task creation for non-trivial work."
  }
}
EOF
    exit 0
  fi
fi

# Pass through normally if active task exists or not starting work
echo "$PROMPT"
