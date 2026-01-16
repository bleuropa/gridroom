# Meta-Framework: Deterministic Project Management

This document describes the meta-framework for deterministic project management with Claude Code.

## Overview

The meta-framework combines strict enforcement (hooks) with token-efficient context tracking (PROJECT_STATUS.md) to ensure consistent workflow while minimizing context window usage.

## Core Components

### 1. PROJECT_STATUS.md

**Location**: `/workspaces/your-project/PROJECT_STATUS.md` (root)

**Purpose**: Single source of truth for project state

**Benefits**:
- Read this ONE file instead of scanning vault (~500 tokens vs 5000+)
- Always current (auto-updated by hooks and slash commands)
- Clear view of: current focus, recent work, next priorities, blockers

**When to read**:
- Start of every session
- Before asking "what's the status?"
- Before planning next work

### 2. Git Hooks (Enforcement)

**pre-commit.sh** - Blocks commits that violate standards:
- ❌ **Temporal language** in evergreen docs (vault/product, vault/architecture, vault/features)
- ❌ **Invalid task status** (must be: backlog, in-progress, completed, blocked)
- ❌ **Missing required task fields** (status, priority, created, updated)
- ❌ **Debugger statements** in code
- ❌ **Merge conflict markers**
- ⚠️  **Console.log statements** (warns)
- ⚠️  **Task size >7 checklist items** (warns - consider splitting)
- ⚠️  **Branch-task misalignment** (warns)
- ⚠️  **PROJECT_STATUS.md not updated** when task files change (warns)

**commit-msg.sh** - Validates commit message format:
- ✅ Conventional commits: `type(scope): description`
- ✅ Valid types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert

**post-commit.sh** - Auto-updates after successful commit:
- ✅ Updates PROJECT_STATUS.md "Last Updated" timestamp
- ✅ Updates "Files Recently Modified" section

### 3. Claude Code Hooks

**PreCompact** - Runs before memory compaction:
- ✅ Saves current state to task context doc
- ✅ Appends recent commits to context
- ✅ Prevents loss of important decisions

### 4. Slash Commands (Guided Workflows)

All slash commands maintain PROJECT_STATUS.md automatically:

**`/p <description>`** - Plan new task
- Creates task file and context doc
- Adds to "Next Up" in PROJECT_STATUS.md
- Commits all changes

**`/s <TASK-ID>`** - Start task
- Creates feature branch
- Updates task status to in-progress
- Updates "Current Focus" in PROJECT_STATUS.md
- Commits all changes

**`/c`** - Close task
- Reviews completion
- Updates task status to completed
- Moves task to "Recently Completed" in PROJECT_STATUS.md
- Optionally creates PR

**`/ctx <note>`** - Update context
- Appends note to context doc
- Updates PROJECT_STATUS.md if significant decision
- Commits changes

**`/status`** - Quick status check
- Reads PROJECT_STATUS.md ONLY (~500 tokens)
- Returns concise summary
- No vault scanning or exploration

**`/wrap`** - End-of-session summary
- Captures key decisions from session
- Updates context doc
- Updates PROJECT_STATUS.md if needed
- Commits all changes

## Workflow Patterns

### Starting a Session

```bash
/status
```

Get quick overview of project state (token-efficient).

### Working on a Task

```bash
# Start
/s T-2025-XXX

# Work on implementation...
# Use /ctx for significant decisions

# End session
/wrap
```

PROJECT_STATUS.md stays in sync automatically.

### Planning New Work

```bash
# Plan task
/p Implement user authentication

# Review task doc created
# Adjust as needed

# Start work
/s T-2025-XXX
```

### Token-Efficient Context

**Instead of**:
```
User: "What's the current status?"
Claude: *reads 10+ vault files, scans git history* [5000+ tokens]
```

**Do this**:
```
User: "/status"
Claude: *reads PROJECT_STATUS.md only* [500 tokens]
```

## Task Size Guidelines

**Enforced by pre-commit hook**: Tasks with >7 checklist items trigger warning.

**Rationale**:
- Tasks should be completable in one session (2-4 hours)
- Large tasks are hard to track and review
- Small tasks enable faster iteration and feedback

**When to split a task**:
- Checklist has >7 items
- Task takes multiple sessions
- Subtask has multiple approaches to debate
- Subtask blocks other work

## Determinism Philosophy

### What Hooks Enforce

**Code quality**:
- No debug statements in production
- No merge conflicts
- Proper commit format

**PM discipline**:
- Task files have required structure
- No temporal language in evergreen docs
- Branch-task alignment
- PROJECT_STATUS.md sync

**Context preservation**:
- State saved before compaction
- Recent files tracked
- Timestamps maintained

### What Slash Commands Guide

**Task lifecycle**:
- Consistent branch creation
- Status transitions
- Context doc management
- PROJECT_STATUS.md updates

**Session management**:
- Quick status checks
- End-of-session wraps
- Context preservation

### What Remains Human Judgment

**Product decisions**:
- What to build next
- How to prioritize work
- When to refactor vs move forward

**Technical decisions**:
- Architecture choices
- Library selection
- Implementation approaches

**Task breakdown**:
- How to split large tasks
- What scope makes sense
- Dependencies and ordering

## Benefits

**Consistency**: Same workflow every time, enforced by automation

**Token efficiency**: PROJECT_STATUS.md minimizes context scanning (~10x reduction)

**Context preservation**: Hooks and /wrap prevent loss of important decisions

**Fast feedback**: Pre-commit hook catches violations immediately

**Clear state**: Always know what's in progress, what's next, what's blocking

## Related Documentation

- [[Hooks and Automation]] - Detailed hook documentation
- [[Git Workflow]] - Commit and branch conventions
- [[Using Obsidian Vault]] - PM workflow and vault structure
- [[Vault Writing Guidelines]] - Documentation standards
