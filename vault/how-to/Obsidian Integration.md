# Obsidian Integration: Why It Works So Well With Claude Code

Balustrade works with any text editor, but Obsidian's design philosophy aligns perfectly with how Claude Code manages context.

---

## You Don't Need Obsidian

The `vault/` folder works with:
- **VS Code** - Built-in markdown preview, file explorer
- **Any text editor** - Vim, Emacs, Sublime, etc.
- **Terminal** - `grep`, `rg`, `find` for searching
- **Web browser** - View markdown files directly

Obsidian is optional enhancement, not a requirement.

---

## Why Obsidian + Claude Code Work So Well Together

### The Context Management Problem

**Challenge**: Claude Code has a limited context window. Reading everything is expensive (~5000+ tokens for a vault scan).

**Solution**: Follow the knowledge graph only as deep as needed.

### Obsidian Community Best Practices = Great Claude Code Context

The Obsidian community has developed patterns that happen to be perfect for AI agents:

#### 1. Atomic Notes
**Obsidian Principle**: Each note covers one concept, fully.

**Why Claude Code Loves This**:
- Agent reads [[Product Vision]] → Gets complete product context in ~500 tokens
- Agent reads [[System Architecture]] → Gets full technical context in ~800 tokens
- **No need to read 10 files** to understand one concept

**Example**:
```markdown
# Product Vision
Complete vision in one file.

Related:
- [[Core Features]] - See specific features
- [[Target Users]] - See user personas
```

Claude only follows links if it needs more detail.

#### 2. Rich Inner-Linking
**Obsidian Principle**: Connect related concepts with `[[wiki links]]`.

**Why Claude Code Loves This**:
- Agent can traverse the knowledge graph selectively
- Starts at high-level doc → follows links to details as needed
- **Minimal context usage** - only reads what's necessary

**Example Flow**:
```
1. User: "How does authentication work?"
2. Claude reads PROJECT_STATUS.md (500 tokens) → sees [[Auth Feature]]
3. Claude reads [[Auth Feature]] (600 tokens) → sees [[System Architecture#Auth]]
4. Claude reads Architecture section (400 tokens) → has full context

Total: ~1500 tokens vs 5000+ for full vault scan
```

#### 3. Knowledge Graph Structure
**Obsidian Principle**: Documents form a navigable graph, not a hierarchy.

**Why Claude Code Loves This**:
- Agent doesn't need to understand folder hierarchies
- Can jump directly from PM task → relevant feature doc → architecture decision
- **Graph traversal is explicit** via wiki links

**Example**:
```
[[T-2025-007-user-auth]]
  → Links to [[US-2025-003-login-flow]]
    → Links to [[Auth Feature]]
      → Links to [[System Architecture]]
        → Links to [[ADR-005-jwt-vs-sessions]]

Claude follows this path as needed, stopping when it has enough context.
```

### The Balustrade + Obsidian Advantage

**Balustrade provides**:
1. **Clear structure** - Where to put things (product/, pm/, architecture/)
2. **Naming conventions** - Task IDs, wiki links, file organization
3. **Automated maintenance** - Hooks keep it consistent
4. **Context docs** - Working notes that link to evergreen docs

**Obsidian provides**:
1. **Visual graph** - See the knowledge structure
2. **Backlinks** - Discover what references current doc
3. **Fast search** - Find anything instantly
4. **Easy navigation** - Click links, no path memorization

**Together**:
- **Humans** get visual graph and fast navigation
- **Claude** gets minimal-context traversal via wiki links
- **Both** benefit from atomic, well-linked documentation
- **Project** stays organized as it grows

---

## Context Management in Practice

### Scenario: Claude Needs to Implement Auth Feature

**Without Balustrade + Obsidian patterns**:
```
1. Claude scans entire vault (5000+ tokens)
2. Finds auth mentioned in 12 different files
3. Reads all 12 files to get complete picture
4. Still might miss some context
5. Total: ~8000 tokens just for context gathering
```

**With Balustrade + Obsidian patterns**:
```
1. Claude reads PROJECT_STATUS.md (500 tokens)
   → Sees current task: [[T-2025-007-user-auth]]

2. Claude reads T-2025-007-user-auth.md (600 tokens)
   → Links to [[US-2025-003-login-flow]]
   → Links to [[T-2025-007-context]]

3. Claude reads US-2025-003-login-flow.md (700 tokens)
   → Links to [[Auth Feature]]
   → Has acceptance criteria

4. Claude reads Auth Feature.md (800 tokens)
   → Links to [[System Architecture#Authentication]]
   → Has feature spec

5. Claude reads Architecture section (500 tokens)
   → Links to [[ADR-005-jwt-tokens]]
   → Has technical approach

6. Reads ADR-005 if needed (400 tokens)
   → Decision rationale and implementation details

Total: ~3500 tokens for complete, precise context
```

**Key Difference**: Claude follows the graph **only as deep as needed** for the specific task.

### Scenario: Understanding Impact of Change

**Human with Obsidian**:
- Opens [[System Architecture]]
- Clicks "Backlinks" panel
- Sees all 15 docs that reference this architecture
- Understands impact visually

**Claude with Obsidian-Style Links**:
- Reads [[System Architecture]]
- Sees wiki links to dependent features
- Can follow links if change impacts them
- Understands impact programmatically

**Both benefit** from the same linking structure.

---

## Atomic Notes Best Practices

### What Makes a Good Atomic Note

**Do**:
✅ One concept per file
✅ Complete within itself (no "continued in Part 2")
✅ Link heavily to related concepts
✅ Use descriptive titles
✅ Include summary at top

**Don't**:
❌ Split single concept across multiple files
❌ Require reading 3 other files to understand this one
❌ Use relative file paths instead of wiki links
❌ Create deeply nested hierarchies

### Example: Good Atomic Note

```markdown
# JWT Token Authentication

**Summary**: We use JWT tokens for stateless authentication.

## Decision
Using JWT tokens instead of sessions for authentication.

**Rationale**:
- Stateless scaling
- No session store needed
- Mobile-friendly

**Trade-offs**:
- Tokens can't be invalidated immediately
- Slightly larger request size

## Implementation
See [[System Architecture#Auth]] for technical details.

## Related
- [[ADR-005-jwt-vs-sessions]] - Why we chose this
- [[Auth Feature]] - User-facing feature
- [[T-2025-007-user-auth]] - Implementation task
```

**What makes this atomic**:
- Complete understanding of JWT decision in one file
- Links provide paths to more detail if needed
- Claude can read just this (400 tokens) and understand JWT approach
- Human can click links to explore further

---

## Rich Linking Patterns

### Link Types

**Product → Architecture**:
```markdown
# Product Vision
Our auth system provides [[Auth Feature]].

# Auth Feature
Implemented via [[System Architecture#Authentication]].

# System Architecture
Authentication uses [[ADR-005-jwt-tokens]].
```

**PM → Product**:
```markdown
# Task: T-2025-007
Implementing [[Auth Feature]] per [[US-2025-003-login-flow]].

# Story: US-2025-003
User story for [[Auth Feature]].

# Feature: Auth
Referenced by tasks: [[T-2025-007-user-auth]].
```

**Context → Everything**:
```markdown
# Context: T-2025-007
Key decision: Using JWT tokens (see [[ADR-005]]).
Blocked on: [[T-2025-006-database-schema]].
Feature spec: [[Auth Feature]].
Architecture: [[System Architecture#Auth]].
```

### Linking Strategy

**Start broad, link deep**:
- High-level docs link to detailed docs
- Claude starts at PROJECT_STATUS.md
- Follows links as deep as needed
- Stops when it has sufficient context

**Link to source of truth**:
- Don't duplicate information
- Link to canonical definition
- Keep docs DRY (Don't Repeat Yourself)

**Example**:
```markdown
# Task: T-2025-007
Implementing JWT authentication.

For technical approach, see [[System Architecture#Auth]].
For product requirements, see [[Auth Feature]].
For user stories, see [[US-2025-003-login-flow]].

[Don't repeat the architecture details here - link to them]
```

---

## How Balustrade Maintains This

### Hooks Enforce Structure
- `pre-commit.sh` validates task structure
- Ensures proper frontmatter (for Obsidian properties)
- Checks wiki link format
- Prevents broken patterns

### Slash Commands Create Links
- `/p` creates task + context doc with proper links
- `/s` links task to branch
- `/c` updates all related docs
- Maintains graph integrity automatically

### PROJECT_STATUS.md as Entry Point
- Always start here (500 tokens)
- Links to current work
- Claude knows where to begin traversal
- Humans know what's happening now

### Templates Embed Linking Patterns
- Epic template links to stories
- Story template links to tasks
- Task template links to story/epic/context
- Bug template links to related items
- Consistency by default

---

## Setting Up Obsidian (If You Want)

### 1. Install Obsidian
Download from [obsidian.md](https://obsidian.md) (free)

### 2. Open Vault
- File → Open folder as vault
- Select your project's `vault/` directory
- Obsidian reads the markdown files

### 3. Recommended Settings
**Settings → Files and Links**:
- ✅ Use `[[Wikilinks]]`
- ✅ Automatically update internal links
- ✅ Default location for new notes: root

**Settings → Editor**:
- ✅ Show line numbers
- ✅ Readable line length (easier for humans)

**Settings → Appearance**:
- Choose theme you like
- Enable graph view

### 4. Optional Plugins

**Core Plugins** (built-in):
- ✅ Graph view - Visual knowledge map
- ✅ Backlinks - See what links here
- ✅ Outgoing links - See what this links to
- ✅ Tags - Filter by tag
- ✅ Templates - Use vault/_templates/

**Community Plugins** (optional):
- **Dataview** - Query frontmatter (advanced)
- **Excalidraw** - Diagrams in markdown
- **Git** - Commit from Obsidian

### 5. Explore the Graph
- Cmd/Ctrl+G → Open graph view
- See your knowledge structure
- Hover over nodes → See connections
- Click nodes → Navigate to file

**Example Graph**:
```
[Product Vision] ← links to → [Auth Feature]
                                    ↓
                              [System Architecture]
                                    ↓
                              [ADR-005-jwt]
                                    ↑
                              [T-2025-007]
```

---

## Alternative: VS Code with Foam

If you prefer VS Code:

### 1. Install Foam Extension
- Provides wiki link support
- Graph view (basic)
- Backlinks panel

### 2. Install Supporting Extensions
- Markdown All in One
- Markdown Preview Enhanced

### 3. Configure
- Enable wiki links
- Set up note templates

**Trade-offs**:
- ✅ Stay in your code editor
- ✅ Git integration built-in
- ❌ Less polished graph view
- ❌ Fewer community plugins

---

## The Philosophy

### For Humans
**Obsidian provides**:
- Visual understanding via graph
- Fast navigation via links
- Knowledge discovery via backlinks
- Pleasant writing experience

### For Claude Code
**Wiki links provide**:
- Selective context loading
- Clear traversal paths
- Minimal token usage
- Explicit relationships

### For Projects
**Balustrade + Obsidian patterns provide**:
- Structure that scales
- Consistency through templates
- Automated maintenance via hooks
- Organization as project grows

### The Key Insight

**Obsidian's best practices aren't just good for humans**—they're optimal for AI context management:

1. **Atomic notes** → Minimal context per read
2. **Rich linking** → Selective depth traversal
3. **Knowledge graph** → Explicit relationships
4. **Single source of truth** → No duplication

**Result**: Both humans and AI agents can navigate the same documentation efficiently.

---

## Practical Tips

### For Humans Using Obsidian

**Daily workflow**:
1. Open Obsidian to your vault
2. Check [[PROJECT_STATUS]] for current work
3. Click through to current task
4. Use backlinks to find related context
5. Follow links as deep as needed

**When documenting**:
1. Use templates from `vault/_templates/`
2. Link liberally with `[[wiki links]]`
3. Keep notes atomic (one concept per file)
4. Check graph view to see connections

### For Claude Code

**Context gathering**:
1. Always read PROJECT_STATUS.md first
2. Follow wiki links to related docs
3. Read only as deep as task requires
4. Stop when you have sufficient context

**When creating docs**:
1. Use templates
2. Include wiki links to related docs
3. Keep atomic (complete within file)
4. Link to canonical sources

---

## Common Patterns

### Pattern: Feature Development

**Graph Structure**:
```
[Product Vision]
    ↓
[Auth Feature] ← canonical feature spec
    ↓
[US-2025-003-login-flow] ← user story
    ↓
[T-2025-007-implement-jwt] ← task
    ↓
[T-2025-007-context] ← working notes
    ↓
[System Architecture#Auth] ← technical approach
    ↓
[ADR-005-jwt-tokens] ← decision record
```

**Claude's Path**:
1. Reads PROJECT_STATUS → sees T-2025-007
2. Reads T-2025-007 → sees links to story/feature/context
3. Reads story → gets acceptance criteria
4. Reads feature → gets product requirements
5. Reads architecture → gets technical approach
6. Reads ADR → gets decision rationale

**Total**: ~3000 tokens, complete context

### Pattern: Bug Investigation

**Graph Structure**:
```
[B-2025-010-login-fails]
    ↓
[Auth Feature] ← what's broken
    ↓
[System Architecture#Auth] ← how it should work
    ↓
[T-2025-007-implement-jwt] ← original implementation
    ↓
[ADR-005-jwt-tokens] ← original decision
```

**Claude's Path**:
1. Reads bug report → understands issue
2. Follows link to Auth Feature → understands expected behavior
3. Follows link to Architecture → understands implementation
4. Follows link to original task → sees what was built
5. Compares expected vs actual → identifies root cause

**Total**: ~2500 tokens, precise diagnosis

---

## The Bottom Line

**You don't need Obsidian** - the vault works with any tool.

**But if you use Obsidian** (or follow its best practices):
- Humans get better documentation
- Claude gets better context management
- Projects stay organized as they grow
- Both benefit from the same structure

**The key**: Atomic notes + rich linking = efficient context management for humans and AI.

**Balustrade makes this easy** with templates, hooks, and conventions that maintain the structure automatically.
