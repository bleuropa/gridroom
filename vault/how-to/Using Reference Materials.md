# Using Reference Materials

The `_reference/` directory pattern provides a standardized way to keep context materials accessible to Claude Code without committing them to the repository.

## The Pattern

Create a `_reference/` directory at project root for materials you want Claude Code to read but not track in git:

```
your-project/
├── _reference/           # Ignored by git, read by Claude Code
│   ├── competitor-app/   # Cloned repo for inspiration
│   ├── screenshots/      # UI mockups or reference images
│   ├── docs/             # PDFs, PRDs, external documentation
│   └── notes.md          # Personal working notes
├── src/                  # Your tracked code
├── vault/                # Your tracked documentation
└── .gitignore            # Contains: _reference/
```

## Use Cases

### Cloned Repositories

Reference other codebases without submodules or vendoring:

```bash
mkdir -p _reference
git clone https://github.com/example/inspiration-app.git _reference/inspiration-app
```

Claude Code can read the code for patterns, but it stays out of your git history.

### Screenshots and Mockups

Store design references, competitor screenshots, or UI inspiration:

```
_reference/
├── screenshots/
│   ├── competitor-dashboard.png
│   ├── figma-export.png
│   └── mobile-flow/
│       ├── step1.png
│       ├── step2.png
│       └── step3.png
```

### External Documentation

Keep PDFs, exported PRDs, or reference docs accessible:

```
_reference/
├── docs/
│   ├── api-spec.pdf
│   ├── brand-guidelines.pdf
│   └── requirements.docx
```

### Working Notes

Personal notes that inform your work but aren't part of the project:

```
_reference/
├── notes.md              # Your scratchpad
├── meeting-notes/        # Meeting transcripts
└── research/             # Background research
```

## Why Underscore Prefix?

The underscore prefix (`_`) signals "ignored/private" following common conventions:

- `_reference/` - Reference materials (ignored)
- `_context/` - Working notes in vault (tracked but ephemeral)
- `_templates/` - Templates in vault (tracked)
- `_meta/` - Meta-documentation (tracked)

The underscore distinguishes special directories from regular project folders.

## Implementation

Add to `.gitignore`:

```gitignore
# Reference materials (not tracked)
_reference/
```

That's it. The directory exists locally, Claude Code can read it, git ignores it.

## Best Practices

### Keep It Organized

Use subdirectories for different types of reference materials:

```
_reference/
├── repos/          # Cloned repositories
├── images/         # Screenshots, mockups
├── docs/           # PDFs, specifications
└── notes/          # Working notes
```

### Document What's There

Consider a `_reference/README.md` (also ignored) that explains what you've stored:

```markdown
# Reference Materials

## repos/
- **inspiration-app**: Cloned from github.com/example/app - using for auth patterns
- **design-system**: Company design system reference

## docs/
- **api-spec.pdf**: External API we're integrating with
- **brand-guidelines.pdf**: Marketing's brand requirements
```

### Don't Rely on It

Reference materials are local-only. They won't exist for other developers or in CI/CD. Use them for inspiration and context, but ensure your project works without them.

### Clean Up Periodically

Reference materials accumulate. Review periodically and remove what you no longer need:

```bash
# Check what's in there
du -sh _reference/*

# Remove stale references
rm -rf _reference/old-project/
```

## Relationship to Vault

| Directory | Purpose | Tracked | Audience |
|-----------|---------|---------|----------|
| `vault/` | Project documentation | Yes | Team + Claude |
| `_reference/` | Working context | No | You + Claude |

- **Vault**: Permanent knowledge that should persist and be shared
- **Reference**: Temporary context that helps you work right now

## Examples

### Learning from a Reference Implementation

```bash
# Clone a well-architected project for reference
git clone https://github.com/example/clean-arch.git _reference/clean-arch

# Now you can ask Claude Code:
# "Look at how _reference/clean-arch handles authentication and apply similar patterns"
```

### Sharing Design Context

```bash
# Export Figma frames to _reference
# Then ask Claude Code:
# "Match the UI in _reference/screenshots/dashboard.png"
```

### Referencing External Specs

```bash
# Download API documentation
curl -o _reference/docs/partner-api.pdf https://partner.example.com/api-spec.pdf

# Then ask Claude Code:
# "Implement the integration following the spec in _reference/docs/partner-api.pdf"
```

## Summary

The `_reference/` pattern gives you a clean way to provide context to Claude Code without polluting your git history. Use it for cloned repos, screenshots, PDFs, and working notes that inform your development but shouldn't be committed.
