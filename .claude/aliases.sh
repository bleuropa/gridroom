#!/bin/bash
# Balustrade Shell Aliases
#
# Makes slash commands faster by creating short aliases.
#
# Usage:
#   source .claude/aliases.sh
#
# Add to your shell rc file (~/.bashrc, ~/.zshrc):
#   source /path/to/project/.claude/aliases.sh
#
# Then use:
#   p "Add user auth"    instead of    /p Add user auth
#   s T-2025-001         instead of    /s T-2025-001
#   c                    instead of    /c
#   status               instead of    /status

# Note: These are shell aliases, not Claude Code commands
# They just make typing faster in your terminal

alias p='echo "Use this in Claude Code: /p"'
alias s='echo "Use this in Claude Code: /s"'
alias c='echo "Use this in Claude Code: /c"'
alias ctx='echo "Use this in Claude Code: /ctx"'
alias status='echo "Use this in Claude Code: /status"'
alias wrap='echo "Use this in Claude Code: /wrap"'

# Actual useful aliases for git
alias gst='git status'
alias glog='git log --oneline -10'

echo "Balustrade aliases loaded!"
echo "Note: p, s, c, ctx, status, wrap are reminders to use /commands in Claude Code"
echo "Actual aliases: gst (git status), glog (git log)"
