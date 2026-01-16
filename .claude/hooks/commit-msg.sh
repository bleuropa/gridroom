#!/bin/bash

# Commit message hook for your-project
# Validates commit message format (conventional commits)

set -e

# Get the commit message
COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Extract first line (subject)
SUBJECT=$(echo "$COMMIT_MSG" | head -n 1)

# Conventional commit pattern
# type(optional-scope): description
PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)(\(.+\))?: .{1,50}"

if ! echo "$SUBJECT" | grep -qE "$PATTERN"; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Expected format: type(scope): description"
    echo ""
    echo "Valid types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert"
    echo "Example: feat(auth): add login form"
    echo "Example: fix: resolve dark mode toggle bug"
    echo ""
    echo "Your message:"
    echo "$SUBJECT"
    echo ""
    echo "See vault/how-to/Git Workflow.md for details"
    exit 1
fi

echo "✅ Commit message format valid"
exit 0
