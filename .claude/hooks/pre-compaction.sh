#!/bin/bash

# Pre-compaction hook for your-project
# Saves state to context document before Claude Code compacts memory

set -e

# Get current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

# Only run on task branches (format: type/T-YYYY-NNN-slug)
if ! echo "$CURRENT_BRANCH" | grep -qE '^(feat|fix|refactor|docs|test|chore)/T-[0-9]{4}-[0-9]{3}'; then
    # Not on a task branch, skip
    exit 0
fi

# Extract task ID from branch
TASK_ID=$(echo "$CURRENT_BRANCH" | grep -oE 'T-[0-9]{4}-[0-9]{3}')

# Find context doc
CONTEXT_DOC=$(find vault/pm/_context -name "${TASK_ID}*.md" | head -n 1)

if [ -z "$CONTEXT_DOC" ]; then
    # No context doc found, skip
    exit 0
fi

# Create timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# Get recent git activity (last 5 commands would be nice but we'll use commits)
RECENT_WORK=$(git log --oneline -3 --pretty=format:"- %s" 2>/dev/null || echo "- Working on $TASK_ID")

# Append to context doc
cat >> "$CONTEXT_DOC" <<EOF

## Auto-saved State ($TIMESTAMP)

Recent commits:
$RECENT_WORK

**Note**: This entry was auto-generated before memory compaction.

EOF

# Stage the update (don't commit - that's too aggressive)
git add "$CONTEXT_DOC" 2>/dev/null || true

echo "✅ Context saved to $CONTEXT_DOC before compaction"
exit 0
