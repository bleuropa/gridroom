# Vault Audit

Run a comprehensive audit of the vault documentation using the vault-organizer agent.

## Instructions

Use the `vault-organizer` agent to perform a documentation audit. The audit should check:

1. **Broken Links** - Wiki links `[[...]]` pointing to non-existent documents
2. **Orphaned Documents** - Files not referenced from anywhere
3. **Temporal Language** - Violations in evergreen docs (architecture, features, product, how-to)
4. **Frontmatter Issues** - Missing or inconsistent YAML frontmatter
5. **Content Quality** - Stub documents, overly long docs, missing structure
6. **Structure Issues** - Files in wrong directories

## Audit Scope Options

If the user provides a scope argument, limit the audit:

- `/va links` - Only check broken/orphaned links
- `/va temporal` - Only check temporal language violations
- `/va tags` - Only check frontmatter/tag consistency
- `/va quick` - Quick health check (critical issues only)
- `/va` (no args) - Full comprehensive audit

## Output

Produce a structured markdown report with:

- Summary statistics
- Tables of issues with file paths and line numbers
- Specific suggested fixes for each issue
- Prioritized recommendations (Critical → Warning → Info)

After the audit, ask if the user wants to fix any of the issues found.
