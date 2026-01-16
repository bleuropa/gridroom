# Agent Packs

Pre-configured agents for different project types. Copy the ones you need to `.claude/agents/`.

## Usage

```bash
# For a SaaS product:
cp .claude/agents/_packs/saas/* .claude/agents/

# For an open source project:
cp .claude/agents/_packs/oss/* .claude/agents/
```

## Available Packs

### SaaS Pack (`saas/`)

Specialized agents for commercial products with users, pricing, and business goals:

- **product-manager.md** - Product vision, prioritization, specs. Owns the roadmap.
- **ui-ux-designer.md** - UX, visual design, interaction patterns. Owns the experience.
- **user-tester.md** - Persona-driven testing with customer archetypes.

### OSS Pack (`oss/`)

Specialized agents for open source projects with contributors and community:

- **maintainer.md** - Project governance, release management, community health.
- **contributor-onboarder.md** - Helping new contributors get started.

## Core Agents (Always Included)

These agents are in `.claude/agents/` by default:

- **coordinator.md** - Multi-domain task orchestration
- **full-stack-dev.md** - Feature implementation end-to-end
- **code-reviewer.md** - Code quality and best practices
- **bug-hunter.md** - Debugging and root cause analysis

## Customization

After copying, customize the agents for your project:

1. Update context-gathering sections to reference your docs
2. Adjust personas for your target users
3. Modify product principles for your domain

All agents check if referenced docs exist before using them, so they work even before you create all documentation.
