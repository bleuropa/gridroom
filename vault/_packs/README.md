# Documentation Packs

Pre-configured documentation templates for different project types. Copy the ones you need to the appropriate vault directories.

## Usage

```bash
# For a SaaS product:
cp vault/_packs/saas/* vault/product/

# For an open source project:
cp vault/_packs/oss/* vault/product/
```

## Available Packs

### SaaS Pack (`saas/`)

Documentation templates for commercial products:

| Template | Purpose | Copy To |
|----------|---------|---------|
| Product Vision.md | Mission, values, target users | vault/product/ |
| Personas and Use Cases.md | Customer archetypes and jobs-to-be-done | vault/product/ |
| Pricing Strategy.md | Tier structure, pricing rationale | vault/product/ |
| Glossary.md | Domain terminology and definitions | vault/product/ |
| Product Learning Journal.md | Evolution of product thinking | vault/product/ |
| Deferred Decisions.md | Decisions blocked on prerequisites | vault/product/ |

### OSS Pack (`oss/`)

Documentation templates for open source projects (coming soon):

| Template | Purpose | Copy To |
|----------|---------|---------|
| Project Vision.md | Why this project exists | vault/product/ |
| Contributing Guide.md | How to contribute | vault/product/ |
| Roadmap.md | What's planned | vault/product/ |

## Core Templates (Always Included)

These templates are in `vault/_templates/` by default:

| Template | Purpose |
|----------|---------|
| Task.md | Work item template |
| Epic.md | Large initiative template |
| Story.md | User story template |
| Bug.md | Bug report template |
| Context.md | Working notes for tasks |
| Feature.md | Feature documentation |
| Data Model.md | Database schema |
| System Architecture.md | System design |

## Customization

After copying, fill in the templates with your project's specifics:

1. Replace placeholder text with your actual content
2. Remove sections that don't apply
3. Add sections specific to your domain

The templates provide structure - you provide the content.
