**Task**: Review and address PR feedback

## Workflow

### 1. Work Locally First

**Before** checking GitHub PR:
- Review your changes in editor
- Run tests locally
- Run formatter/linter
- Self-review for obvious issues

### 2. Fetch PR Feedback (If PR Exists)

```bash
gh pr view --json number,title,comments,reviews
```

If no PR exists yet, keep working locally.

### 3. Think Critically About Feedback

✅ **Implement immediately**:
- Security vulnerabilities
- Clear bugs
- Pattern violations

⚠️ **Consider carefully**:
- Stylistic preferences
- Suggestions conflicting with patterns
- Scope creep

❌ **May push back on**:
- Feedback contradicting project docs
- Subjective opinions without rationale

### 4. Address Feedback Locally

1. Make fixes
2. Update context doc with what you addressed
3. Run tests
4. Commit changes

### 5. Push to PR

**CRITICAL**: Don't forget to push!

```bash
git push
```

Then update PR description with "Updates" section.

## Context Doc Tracking

Add to existing context doc:
```markdown
## PR Review Feedback - [Date]

**Addressed**:
- ✅ [Issue]: [What was done]

**Not addressed**:
- ⏭️ [Issue]: [Why not]

**Files changed**: [list]
**Tests**: [results]
```

## PR Description Update

Add "Updates" section:
```markdown
## Updates

### [Date] - Addressed Code Review Feedback
- Fixed [issue]: [description]
- Not addressed: [issue] - [rationale]

See context: vault/pm/_context/[TASK-ID]-context.md
```

## Key Principles

- **Think critically** - Reviewers can be wrong
- **Document reasoning** - Explain what you did and didn't do
- **Work locally first** - Fix, test, then push
- **Update docs** - Keep context doc and PR description current

## Remember

This is a workflow nudge for "check PR feedback and address thoughtfully."

Use specialists if needed (full-stack-dev, bug-hunter, code-reviewer).
