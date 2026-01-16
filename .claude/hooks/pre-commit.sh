#!/bin/bash

# Pre-commit hook for BunkerOverlay (Elixir/Phoenix)
# Validates code quality and PM discipline before commit

set -e

GIT_ROOT=$(git rev-parse --show-toplevel)
CURRENT_BRANCH=$(git branch --show-current)

# ============================================================================
# Code Quality Checks
# ============================================================================

# Check for common debug statements in staged JavaScript/TypeScript files
STAGED_JS_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|jsx|ts|tsx)$' || true)

if [ -n "$STAGED_JS_FILES" ]; then
    # Check for console.log (but allow in specific files like dev tools)
    for FILE in $STAGED_JS_FILES; do
        if ! echo "$FILE" | grep -qE '(devtools|debug|test|spec)\.(js|ts)'; then
            if grep -nE '^\s*console\.(log|debug|info)' "$FILE" 2>/dev/null; then
                echo "⚠️  Warning: Found console.log in $FILE"
                echo "   Consider removing debug statements before committing"
                # Warning only, don't block
            fi
        fi

        # Check for debugger statements (block these)
        if grep -nE '^\s*debugger' "$FILE" 2>/dev/null; then
            echo "❌ Found debugger statement in $FILE"
            echo "   Remove debugger statements before committing"
            exit 1
        fi
    done
fi

# Check for common debug statements in staged Elixir files
STAGED_EX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ex|exs)$' || true)

if [ -n "$STAGED_EX_FILES" ]; then
    for FILE in $STAGED_EX_FILES; do
        # Skip test files for IO.inspect checks (often intentional in tests)
        if ! echo "$FILE" | grep -qE '_test\.exs$'; then
            # Check for IO.inspect (warning only)
            if grep -nE '^\s*IO\.inspect' "$FILE" 2>/dev/null; then
                echo "Warning: Found IO.inspect in $FILE"
                echo "   Consider removing debug statements before committing"
                # Warning only, don't block
            fi

            # Check for IEx.pry (block these)
            if grep -nE 'IEx\.pry' "$FILE" 2>/dev/null; then
                echo "Found IEx.pry statement in $FILE"
                echo "   Remove IEx.pry statements before committing"
                exit 1
            fi
        fi

        # Check for :dbg (Elixir 1.14+ debugging) - block these
        if grep -nE '^\s*dbg\(' "$FILE" 2>/dev/null; then
            echo "Found dbg() debugging in $FILE"
            echo "   Remove dbg() statements before committing"
            exit 1
        fi
    done
fi

# Check for merge conflict markers
if git diff --cached | grep -qE '^(\+|-)<<<<<<|^(\+|-)======|^(\+|-)>>>>>>'; then
    echo "❌ Found merge conflict markers in staged files"
    echo "   Resolve conflicts before committing"
    exit 1
fi

# ============================================================================
# Vault Documentation Checks
# ============================================================================

# Check for temporal language in evergreen docs
check_temporal_language() {
    local file=$1

    # Only check evergreen docs (product, architecture, features)
    if ! echo "$file" | grep -qE 'vault/(product|architecture|features)/'; then
        return 0
    fi

    # Temporal words to block
    local temporal_words="(now|currently|recently|soon|will|going to|planned|future|next|upcoming|later|eventually|previously|formerly|originally|initially)"

    if grep -inE "\b${temporal_words}\b" "$file" 2>/dev/null; then
        echo ""
        echo "❌ Found temporal language in evergreen doc: $file"
        echo "   Evergreen docs must describe current state, not temporal changes"
        echo "   Blocked words: now, currently, recently, soon, will, planned, future, etc."
        echo ""
        echo "   See vault/_meta/Vault Writing Guidelines.md for details"
        exit 1
    fi
}

# ============================================================================
# Task File Validation
# ============================================================================

validate_task_frontmatter() {
    local file=$1

    # Only check task files
    if ! echo "$file" | grep -qE 'vault/pm/tasks/T-[0-9]{4}-[0-9]{3}'; then
        return 0
    fi

    # Check required fields exist
    if ! grep -q '^status:' "$file"; then
        echo ""
        echo "❌ Task missing 'status' field: $file"
        echo "   Required fields: status, priority, created, updated"
        exit 1
    fi

    if ! grep -q '^priority:' "$file"; then
        echo ""
        echo "❌ Task missing 'priority' field: $file"
        exit 1
    fi

    # Check status is valid
    local status=$(grep '^status:' "$file" | awk '{print $2}')
    if ! echo "$status" | grep -qE '^(backlog|in-progress|completed|blocked)$'; then
        echo ""
        echo "❌ Invalid task status '$status' in: $file"
        echo "   Valid statuses: backlog, in-progress, completed, blocked"
        exit 1
    fi
}

# ============================================================================
# Task Size Validation
# ============================================================================

check_task_size() {
    local file=$1

    # Only check task files
    if ! echo "$file" | grep -qE 'vault/pm/tasks/T-[0-9]{4}-[0-9]{3}'; then
        return 0
    fi

    # Count checklist items (lines starting with - [ ] or - [x])
    local checklist_count=$(grep -cE '^\s*- \[([ x])\]' "$file" 2>/dev/null || echo "0")

    if [ "$checklist_count" -gt 7 ]; then
        echo ""
        echo "⚠️  Warning: Task has $checklist_count checklist items: $file"
        echo "   Consider breaking this into smaller tasks (recommended max: 7 items)"
        echo "   Large tasks are harder to complete in one session and track progress"
        echo ""
        # Warning only, don't block
    fi
}

# ============================================================================
# Branch-Task Alignment Check
# ============================================================================

check_branch_task_alignment() {
    local branch="$CURRENT_BRANCH"

    # Skip if on main branch
    if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
        return 0
    fi

    # Get task IDs from modified files
    local changed_tasks=$(git diff --cached --name-only | grep -oE 'T-[0-9]{4}-[0-9]{3}' | sort -u)

    if [ -z "$changed_tasks" ]; then
        return 0
    fi

    for task_id in $changed_tasks; do
        if ! echo "$branch" | grep -q "$task_id"; then
            echo ""
            echo "⚠️  Warning: Modifying task $task_id from branch: $branch"
            echo "   Best practice: work on tasks from their dedicated branch"
            echo "   Expected branch format: type/T-YYYY-NNN-slug"
            echo ""
            # Warning only, don't block
        fi
    done
}

# ============================================================================
# PROJECT_STATUS.md Sync Check
# ============================================================================

check_project_status_sync() {
    # Check if task files are being modified
    local task_changes=$(git diff --cached --name-only | grep 'vault/pm/tasks/' || true)

    if [ -n "$task_changes" ]; then
        # Check if PROJECT_STATUS.md is also staged
        if ! git diff --cached --name-only | grep -q '^PROJECT_STATUS.md$'; then
            echo ""
            echo "⚠️  Warning: Task files modified but PROJECT_STATUS.md not updated"
            echo "   Consider updating PROJECT_STATUS.md to keep it in sync"
            echo "   (Use slash commands like /s, /c to auto-update both)"
            echo ""
            # Warning only, don't block
        fi
    fi
}

# ============================================================================
# Run All Checks
# ============================================================================

STAGED_MD_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.md$' || true)

if [ -n "$STAGED_MD_FILES" ]; then
    for FILE in $STAGED_MD_FILES; do
        if [ -f "$FILE" ]; then
            check_temporal_language "$FILE"
            validate_task_frontmatter "$FILE"
            check_task_size "$FILE"
        fi
    done
fi

check_branch_task_alignment
check_project_status_sync

echo "✅ Pre-commit checks passed"
exit 0
