# Hooks and Automation

This document describes the automated validation and workflow hooks in your-project.

## Overview

YourProject uses two types of hooks for automation:

1. **Git Hooks** - Run during Git operations (commit, etc.)
2. **Claude Code Hooks** - Run during Claude Code operations (compaction, etc.)

## Git Hooks

Git hooks provide deterministic validation of code quality and commit conventions.

### Installation

```bash
bash .claude/hooks/install-hooks.sh
```

This creates symlinks in `.git/hooks/` pointing to `.claude/hooks/` scripts.

### Available Git Hooks

#### pre-commit

**When it runs**: Before creating a commit (after `git commit`, before message is written)

**What it validates**:

**Code quality** (blocks):
- No `debugger` statements in code
- No merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)

**Code quality** (warns):
- `console.log/debug/info` statements (except in test/debug files)

**PM discipline** (blocks):
- No temporal language in evergreen docs (vault/product, vault/architecture, vault/features)
- Task files must have valid status (backlog, in-progress, completed, blocked)
- Task files must have required fields (status, priority, created, updated)

**PM discipline** (warns):
- Task size >7 checklist items (consider splitting)
- Branch-task alignment (modifying task from wrong branch)
- PROJECT_STATUS.md sync (task files changed but status not updated)

**Files checked**: `*.js`, `*.jsx`, `*.ts`, `*.tsx`, `*.md` (staged files only)

**Location**: `.claude/hooks/pre-commit.sh`

**Example output** (success):
```
✅ Pre-commit checks passed
```

**Example output** (blocking error):
```
❌ Found temporal language in evergreen doc: vault/product/User Journeys.md
   Evergreen docs must describe current state, not temporal changes
   Blocked words: now, currently, recently, soon, will, planned, future, etc.

   See vault/_meta/Vault Writing Guidelines.md for details
```

**Example output** (warning):
```
⚠️  Warning: Task has 9 checklist items: vault/pm/tasks/T-2025-012-user-authentication.md
   Consider breaking this into smaller tasks (recommended max: 7 items)
   Large tasks are harder to complete in one session and track progress

✅ Pre-commit checks passed
```

#### commit-msg

**When it runs**: After commit message is written, before commit is created

**What it validates**:
- Conventional commit format: `type(scope): description`
- Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`
- Subject max length: 50 characters

**Location**: `.claude/hooks/commit-msg.sh`

**Example output**:
```
✅ Commit message format valid
```

or

```
❌ Invalid commit message format!

Expected format: type(scope): description

Valid types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
Example: feat(auth): add login form
Example: fix: resolve dark mode toggle bug

Your message:
Added some stuff

See vault/how-to/Git Workflow.md for details
```

#### post-commit

**When it runs**: After commit is successfully created

**What it does**:
- Updates PROJECT_STATUS.md "Last Updated" timestamp
- Updates "Files Recently Modified" section with recent 10 files
- Stages PROJECT_STATUS.md (doesn't auto-commit)

**Location**: `.claude/hooks/post-commit.sh`

**Example**:
```bash
git commit -m "feat: add user authentication"
# post-commit hook runs automatically
# PROJECT_STATUS.md is updated and staged
# Next commit will include the status update
```

**Note**: This hook keeps PROJECT_STATUS.md timestamps current without requiring manual updates.

## Claude Code Hooks

Claude Code hooks provide automation during AI-assisted development.

### Configuration

Claude Code hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-compaction.sh",
            "statusMessage": "Saving context before compaction..."
          }
        ]
      }
    ]
  }
}
```

### Available Claude Code Hooks

#### PreCompact

**When it runs**: Before Claude Code compacts conversation context (memory compression)

**What it does**:
- Saves current conversation context
- Identifies active task (if any)
- Appends state to task context doc in `vault/pm/_context/`
- Prevents loss of important decisions and progress

**Location**: `.claude/hooks/pre-compaction.sh`

**Example output**:
```
💾 Saving context before compaction...
📝 Active task: T-2025-003
✅ Context saved to vault/pm/_context/T-2025-003-context.md
```

## Hook Types Available

Claude Code supports these hook types (not all currently used):

- **PreToolUse** - Before any tool is called
- **PostToolUse** - After any tool is called
- **PreCompact** - Before context compaction (currently used)
- **PostCompact** - After context compaction
- **PreChat** - Before chat message is processed
- **PostChat** - After chat message is processed

## Deterministic Activities

The hooks system ensures these activities happen automatically:

### Code Quality (Git Hooks)
- ✅ No debug statements reach production
- ✅ No merge conflicts in commits
- ✅ Consistent commit message format
- ✅ Searchable commit history

### Context Preservation (Claude Code Hooks)
- ✅ Important decisions saved before memory compression
- ✅ Task progress preserved across sessions
- ✅ Architectural decisions captured
- ✅ Reduced token burn from re-exploration

## Bypassing Hooks

### Git Hooks

**Not recommended**, but possible:

```bash
# Skip pre-commit (validation still happens on commit-msg)
git commit --no-verify -m "feat: emergency fix"
```

**When to bypass**:
- Emergency hotfixes (fix first, clean later)
- Committing intentional debug code (mark with TODO)
- Temporary WIP commits on feature branch

**Always clean before merging to main!**

### Claude Code Hooks

Claude Code hooks cannot be easily bypassed - they run automatically based on settings.json configuration.

## Maintenance

### Adding New Git Hooks

1. Create script in `.claude/hooks/`
2. Make executable: `chmod +x .claude/hooks/new-hook.sh`
3. Update `install-hooks.sh` to symlink it
4. Document in this file
5. Run `bash .claude/hooks/install-hooks.sh`

### Adding New Claude Code Hooks

1. Create script in `.claude/hooks/`
2. Make executable: `chmod +x .claude/hooks/new-hook.sh`
3. Add to `.claude/settings.json` under appropriate event
4. Document in this file
5. Test by triggering the event

## Troubleshooting

### Git Hooks Not Running

**Check installation**:
```bash
ls -l .git/hooks/pre-commit
ls -l .git/hooks/commit-msg
```

Should show symlinks to `.claude/hooks/` scripts.

**Reinstall**:
```bash
bash .claude/hooks/install-hooks.sh
```

### Claude Code Hooks Not Running

**Check settings.json syntax**:
```bash
cat .claude/settings.json | jq .
```

Should parse without errors.

**Check hook script permissions**:
```bash
ls -l .claude/hooks/*.sh
```

All should be executable (`-rwxr-xr-x` or similar).

### Hooks Failing in Dev Container

Ensure scripts use portable paths:
- ✅ Use `git rev-parse --show-toplevel` for git root
- ✅ Use relative paths from git root
- ❌ Don't use absolute paths like `/Users/...`
- ❌ Don't use `~` for home directory

## Philosophy

### Why Hooks?

**Consistency**: Ensure conventions are followed automatically, not manually remembered.

**Speed**: Catch issues immediately, not during code review.

**Determinism**: Same validation runs every time, regardless of who (human or AI) writes the code.

**Token Efficiency**: Pre-compaction hook reduces need for Claude to re-explore context after memory compression.

### What NOT to Hook

**Avoid hooks that**:
- Take more than 2-3 seconds to run
- Require network access (flaky, slow)
- Make code changes automatically (surprising, hard to debug)
- Duplicate existing tools (linters, formatters - run those separately)

**Good hooks**: Fast, deterministic, read-only validation

**Bad hooks**: Slow, network-dependent, auto-fixing

## Related Documentation

- [[Git Workflow]] - Commit and branch conventions
- [[Development Setup]] - Initial setup including hooks
- [[Code Philosophy]] - Coding standards enforced by hooks
