#!/bin/bash

# Post-commit hook for your-project
# Auto-updates PROJECT_STATUS.md after commits

set -e

GIT_ROOT=$(git rev-parse --show-toplevel)
STATUS_FILE="$GIT_ROOT/PROJECT_STATUS.md"

# Only proceed if PROJECT_STATUS.md exists
if [ ! -f "$STATUS_FILE" ]; then
    exit 0
fi

# Get today's date
TODAY=$(date +%Y-%m-%d)

# Update "Last Updated" timestamp
sed -i.bak "s/\*\*Last Updated\*\*:.*/\*\*Last Updated\*\*: $TODAY/" "$STATUS_FILE" && rm -f "$STATUS_FILE.bak"

# Update "Files Recently Modified" section
# Get last 10 unique changed files across recent commits
RECENT_FILES=$(git log -10 --name-only --pretty=format: | grep -v '^$' | grep -v '^PROJECT_STATUS.md$' | sort -u | head -10)

# Find the "Files Recently Modified" section and replace content until next section
if grep -q "^## Files Recently Modified" "$STATUS_FILE"; then
    # Use awk to replace just the file list between sections
    awk -v files="$RECENT_FILES" '
    BEGIN {
        split(files, file_array, "\n")
    }
    /^## Files Recently Modified/ {
        print $0
        print ""
        print "<!-- Auto-updated by post-commit hook -->"
        for (i in file_array) {
            if (file_array[i] != "") {
                print "- " file_array[i]
            }
        }
        print ""
        skip = 1
        next
    }
    /^## / && skip {
        skip = 0
    }
    !skip {
        print
    }
    ' "$STATUS_FILE" > "$STATUS_FILE.tmp"

    # Replace if awk succeeded
    if [ -s "$STATUS_FILE.tmp" ]; then
        mv "$STATUS_FILE.tmp" "$STATUS_FILE"
    else
        rm -f "$STATUS_FILE.tmp"
    fi
fi

# Stage the updated PROJECT_STATUS.md (don't commit it automatically)
git add "$STATUS_FILE" 2>/dev/null || true

exit 0
