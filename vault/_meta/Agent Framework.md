# Agent Framework

This document describes the specialized agents available in the Balustrade meta-framework and when to use each.

## Overview

Agents are specialized prompts that embody specific roles, expertise, and workflows. They live in `.claude/agents/` and can be invoked for focused tasks.

## Core Agents

### Development Agents

| Agent              | Purpose                    | When to Use                           |
| ------------------ | -------------------------- | ------------------------------------- |
| **coordinator**    | Multi-domain orchestration | Complex tasks spanning multiple areas |
| **full-stack-dev** | Feature implementation     | Building features end-to-end          |
| **code-reviewer**  | Code quality review        | Validating code before merge          |
| **bug-hunter**     | Debugging specialist       | Investigating and fixing bugs         |

### Documentation Agents

| Agent              | Purpose                     | When to Use                        |
| ------------------ | --------------------------- | ---------------------------------- |
| **vault-organizer** | Documentation health        | Auditing vault structure           |
| **vault-writer**    | Documentation creation      | Writing quality vault docs         |

## Optional Agents (SaaS Pack)

These agents are useful for SaaS products but may not apply to all projects:

| Agent               | Purpose                    | When to Use                           |
| ------------------- | -------------------------- | ------------------------------------- |
| **product-manager** | Vision & specs             | Defining what to build and why        |
| **ui-ux-designer**  | UX & visual design         | Making things feel magical            |
| **user-tester**     | Voice of customer          | Validating features against personas  |

## Agent: vault-organizer

The vault-organizer agent audits documentation quality and structure.

### Capabilities

- Find broken wiki links
- Identify orphaned documents
- Detect temporal language violations
- Check frontmatter consistency
- Suggest documentation improvements

### Invocation

**Via command:**
```
/va              # Full audit
/va links        # Link check only
/va temporal     # Temporal language scan
```

### When to Use

- Periodic vault health checks
- Before major releases
- When documentation feels disorganized
- To find documentation gaps

## Agent: vault-writer

The vault-writer agent creates high-quality documentation following vault guidelines.

### Capabilities

- Create new documentation
- Review existing docs for quality
- Fix temporal language violations
- Ensure proper linking and structure

### When to Use

- Creating new feature documentation
- Reviewing documentation quality
- Fixing issues found by vault-organizer
- Documenting architectural decisions

## Adding New Agents

To add a new agent:

1. Create `.claude/agents/{agent-name}.md`
2. Include frontmatter:
   ```yaml
   ---
   name: agent-name
   description: One-line description
   tools: Tool1, Tool2, Tool3
   model: sonnet
   ---
   ```
3. Document the agent's role, expertise, and workflow
4. Update coordinator.md to list the new agent
5. Optionally create a `/command` for quick invocation
6. Document in this file

## Agent Selection Guide

| Task Type                    | Recommended Agent    |
| ---------------------------- | -------------------- |
| Multi-domain complex work    | coordinator          |
| Building new features        | full-stack-dev       |
| Code quality review          | code-reviewer        |
| Investigating bugs           | bug-hunter           |
| Documentation audit          | vault-organizer      |
| Writing documentation        | vault-writer         |
| Product decisions (SaaS)     | product-manager      |
| UX design work (SaaS)        | ui-ux-designer       |
| User validation (SaaS)       | user-tester          |

## Related

- `.claude/agents/` - Agent definitions
- `.claude/commands/` - Slash commands
- [[Vault Writing Guidelines]] - Documentation standards
