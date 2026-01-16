---
type: epic
id: E-2025-002
status: planning
priority: p1
created: 2026-01-16
updated: 2026-01-16
---

# Epic: Social & Friends System

## Overview
**Epic ID**: E-2025-002-social-friends-system
**Status**: Planning
**Priority**: P1
**Created**: 2026-01-16
**Target Completion**: TBD

## Description
Build a social layer on top of Gridroom's anonymous-first experience. Users who have interacted in node discussions can form connections ("friends" or "gridmates"), see each other on the grid, and travel to find each other. This maintains the mysterious vibe while adding meaningful social presence.

## Goals
- Enable organic relationship formation through discussions
- Make the grid feel more alive with visible social connections
- Support "regulars" culture where you recognize shapes before names
- Fast travel to friends reduces friction in finding meaningful conversations

## Success Criteria
- [ ] Users can form friend connections from within nodes
- [ ] Friends are visible on the infinite grid (highlighted or findable)
- [ ] Fast travel or "warp" to friend's location works smoothly
- [ ] Clicking a user in a node shows their recent activity
- [ ] Node rooms display all present users visually

## User Value
**As a** regular Gridroom visitor
**I want** to connect with people I've had good conversations with
**So that** I can find them again and continue building relationships across the grid

## Scope
### In Scope
- Friend/connection system (mutual or one-way follow)
- Friend presence visualization on grid
- Fast travel / warp to friend's location
- User activity sidebar (recent nodes visited)
- Presence display in node rooms (diamond avatars at bottom)

### Out of Scope
- Chat/DM between friends (keep it spatial)
- Friend lists / social graph UI
- Notifications (keep it pull-based, discovery-driven)

### Dependencies
- **Requires**: User authentication (T-2025-005 ✅)
- **Related**: User glyph system (existing)

## Child Tasks
- [[T-2025-006-friends-from-discussions]] - Add friend from node discussion
- [[T-2025-007-fast-travel-to-friends]] - Warp to friend's grid location
- [[T-2025-008-friends-visible-on-grid]] - See friends highlighted on grid
- [[T-2025-009-user-activity-sidebar]] - Click user → see recent nodes
- [[T-2025-010-node-room-presence-display]] - Diamond avatars in node rooms

## Technical Requirements
### Architecture Impact
- New `friendships` or `connections` table
- Presence tracking needs friend filtering
- Grid rendering needs friend highlighting layer
- Activity tracking (which nodes user visited)

### Performance Requirements
- Friend presence updates should be real-time (Phoenix Presence)
- Fast travel animation should feel smooth (<500ms)
- Activity sidebar should load quickly (<200ms)

### Security Considerations
- Privacy: should users be able to hide their location?
- Blocking: if someone is harassing, can you block them?
- Activity visibility: opt-in or opt-out?

## Risk Assessment
| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| Stalking concern | High | Low | Add ability to go "invisible" or block |
| Performance with many friends | Medium | Low | Paginate friend lists, limit visible friends on grid |
| Breaks anonymous vibe | Medium | Medium | Keep friend system subtle, opt-in |

## Related Documents
- Vision: [[VISION.md]] (Phase 2: Identity & Persistence, Phase 6: Discovery)
- Context: [[E-2025-002-context]]

## Notes
### Key Decisions
- Friends = people you've interacted with in a node (not arbitrary follow)
- Keep visual treatment subtle (glowing outline, not friend avatar)
- Activity sidebar fits the "discovering connections" vibe from Severance

### Open Questions
- One-way follow vs mutual friendship?
- Should friends see each other's paths/trails?
- How prominent should fast-travel be (button vs keyboard shortcut)?
