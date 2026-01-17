# Project Status

**Last Updated**: 2026-01-16
**Project**: Gridroom

---

## Current Focus

**Active Task**: None
**Branch**: main
**Goal**: Ready for new task

---

## Next Up (Top 3 Priorities)

1. [[T-2025-019-corridor-navigation]] - Corridor navigation system (Severance-style)
2. [[T-2025-007-grid-territories-classification]] - Grid territories & classification
3. [[T-2025-009-idle-kick-mechanic]] - Idle kick mechanic

## Backlog (Prioritized)

### High Priority (P1)
- [[T-2025-019-corridor-navigation]] - Corridor navigation system
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

- [[T-2025-018-grok-api-trend-nodes]] - Grok API integration for trend-based node generation
- [[T-2025-017-resonance-presence-node-decay]] - Resonance meter, toasts, glyph effects, node decay
- [[T-2025-016-grid-canvas-navigation]] - Grid canvas navigation (click to select, zoom limits)

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
- **Node decay**: Inactive nodes fade (1-7d quiet, 7-14d fading, 14d+ gone), activity revives them

---

## Notes

- This file is the **single source of truth** for project status
- Kept in sync with `vault/pm/` via hooks and slash commands
- Read this file first before asking "what's the status?"
