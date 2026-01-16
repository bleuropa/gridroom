# Project Status

**Last Updated**: 2025-01-15
**Project**: Gridroom

---

## Current Focus

**Active Task**: [[T-2025-004-grid-ux-polish]] - Camera, fog of war, activity viz
**Branch**: feat/T-2025-004-grid-ux-polish
**Goal**: Camera following, fog of war, activity visualization improvements

**Recent Progress**:
- WASD/Arrow key player movement
- Dwell mechanic for node entry (1.5s to enter)
- Visual progress ring while dwelling
- Fluid ripple transitions when entering nodes
- Activity tracking on nodes
- Return positioning (spawn near last node)

---

## Next Up (Top 3 Priorities)

1. [[T-2025-005-username-password-auth]] - Simple username/password auth (no email)
2. AI content seeding with xAI/Grok
3. Deploy to production

---

## Recently Completed (Last 3)

- Dwell mechanic with visual progress ring
- Fluid ripple transition animations
- WASD movement independent of viewport

---

## Open Questions / Blockers

- Camera follow speed - how fast/slow feels right?
- Fog of war persistence - session vs permanent?
- Activity thresholds - what defines "active"?
- Can you see activity through fog?

---

## Key Decisions

- **Phoenix LiveView**: Real-time updates for presence and conversations
- **Aesthetic**: Severance meets fantasy tavern - clean, minimal, mysterious, warm
- **No streaming**: Focus on interaction layer only
- **Anonymous first**: Session-based identity, optional accounts later
- **SVG rendering**: Using SVG for grid, nodes, and user glyphs

---

## Task Breakdown (T-2025-004 Planning)

**T-2025-004**: Grid UX Polish
- [ ] Camera following player during WASD
- [ ] Fog of war system
- [ ] Activity visualization redesign

---

## Notes

- This file is the **single source of truth** for project status
- Kept in sync with `vault/pm/` via hooks and slash commands
- Read this file first before asking "what's the status?"
