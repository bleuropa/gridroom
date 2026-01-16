# Project Status

**Last Updated**: 2026-01-16
**Project**: Gridroom

---

## Current Focus

**Active Task**: [[T-2025-015-energy-reputation-system]]
**Branch**: feat/T-2025-015-energy-reputation-system
**Goal**: Design and implement Lumon-style energy/reputation system

---

## Next Up (Top 3 Priorities)

1. [[T-2025-013-share-nodes-via-url]] - Share nodes via URL (viral growth)
2. [[T-2025-010-enhanced-node-chat-viz]] - Enhanced chat room viz (diamond avatars)
3. [[T-2025-006-node-creation-system]] - User node creation

## Backlog (Prioritized)

### High Priority (P1)
- [[E-2025-002-social-friends-system]] - Epic: Social & Friends System
- [[T-2025-015-energy-reputation-system]] - Energy/Reputation system (Lumon-style moderation)
- [[T-2025-013-share-nodes-via-url]] - Share nodes via URL
- [[T-2025-010-enhanced-node-chat-viz]] - Enhanced chat room visualization
- [[T-2025-006-node-creation-system]] - Node creation system

### Medium Priority (P2)
- [[T-2025-007-grid-territories-classification]] - Grid territories & node classification
- [[T-2025-009-idle-kick-mechanic]] - Idle kick mechanic
- [[T-2025-011-portal-system]] - Portal system with energy cost
- [[T-2025-012-node-creation-cost-proximity]] - Node creation cost by proximity

### Low Priority (P3)
- [[T-2025-008-ai-avatar-generation]] - AI avatar generation for auth users

### Future (from VISION.md)
- AI content seeding with xAI/Grok
- Deploy to production

---

## Recently Completed (Last 3)

- [[T-2025-014-user-profile-sidebar-friending]] - User profile sidebar, friending, recognition highlighting
- [[T-2025-005-username-password-auth]] - Username/password auth (no email)
- [[T-2025-004-grid-ux-polish]] - Camera, lighting, activity viz

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

---

## Notes

- This file is the **single source of truth** for project status
- Kept in sync with `vault/pm/` via hooks and slash commands
- Read this file first before asking "what's the status?"
