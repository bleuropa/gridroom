# Project Status

**Last Updated**: 2026-01-17
**Project**: Gridroom (Innie Chat)

---

## Current Focus

**Active Task**: None
**Branch**: main
**Goal**: Select next task from backlog

---

## Next Up (Top 3 Priorities)

1. [[T-2025-007-grid-territories-classification]] - Grid territories & classification
2. [[T-2025-009-idle-kick-mechanic]] - Idle kick mechanic
3. [[T-2025-011-portal-system]] - Portal system with energy cost

## Backlog (Prioritized)

### High Priority (P1)
- [[E-2025-002-social-friends-system]] - Epic: Social & Friends System

### Medium Priority (P2)
- [[T-2025-007-grid-territories-classification]] - Grid territories & node classification
- [[T-2025-009-idle-kick-mechanic]] - Idle kick mechanic
- [[T-2025-011-portal-system]] - Portal system with energy cost
- [[T-2025-012-node-creation-cost-proximity]] - Node creation cost by proximity

### Low Priority (P3)
- [[T-2025-008-ai-avatar-generation]] - AI avatar generation for auth users

### Future (from VISION.md)
- Deploy to production

---

## Recently Completed (Last 3)

- [[T-2025-025-discussion-pods]] - Private pods for group messaging within discussions
- [[T-2025-024-streaming-messages-pagination]] - Streaming messages with LiveView streams for lazy loading
- [[T-2025-023-gemini-google-search-grounding]] - Gemini Google Search grounding + decay/scheduler cleanup

---

## Open Questions / Blockers

- None currently

---

## Key Decisions

- **Phoenix LiveView**: Real-time updates for presence and conversations
- **Aesthetic**: Severance meets fantasy tavern - clean, minimal, mysterious, warm
- **No streaming**: Focus on interaction layer only
- **Anonymous first**: Session-based identity, optional accounts
- **Auth without email**: Username/password only, no password reset, accounts are disposable
- **SVG rendering**: Using SVG for grid, nodes, and user glyphs
- **Node decay**: Inactive nodes fade (1-3d quiet, 3-5d fading, 5d+ vaulted/gone), activity revives them
- **Glyph system**: 682 surreal designations (like "the goat" from Severance)

---

## Notes

- This file is the **single source of truth** for project status
- Kept in sync with `vault/pm/` via hooks and slash commands
- Read this file first before asking "what's the status?"
