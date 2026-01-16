#!/bin/bash

# Install Git hooks for your-project
# Run this script from anywhere in the repository

set -e

# Get git root directory (works anywhere in repo)
GIT_ROOT=$(git rev-parse --show-toplevel)

cd "$GIT_ROOT"

echo "Installing Git hooks..."

# Make hooks executable
chmod +x .claude/hooks/pre-commit.sh
chmod +x .claude/hooks/commit-msg.sh
chmod +x .claude/hooks/post-commit.sh
chmod +x .claude/hooks/pre-compaction.sh

# Create symlinks in .git/hooks/
ln -sf ../../.claude/hooks/pre-commit.sh .git/hooks/pre-commit
ln -sf ../../.claude/hooks/commit-msg.sh .git/hooks/commit-msg
ln -sf ../../.claude/hooks/post-commit.sh .git/hooks/post-commit

echo "✅ Git hooks installed successfully!"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: Validates code quality, task files, temporal language, PM discipline"
echo "  - commit-msg: Validates conventional commit format"
echo "  - post-commit: Auto-updates PROJECT_STATUS.md timestamp and recent files"
echo ""
echo "Claude Code hooks (in .claude/settings.json):"
echo "  - PreCompact: Saves context before memory compression"
