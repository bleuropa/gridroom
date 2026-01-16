---
type: task
id: T-2025-015
story:
epic: E-2025-002
status: in-progress
priority: p1
created: 2026-01-16
updated: 2026-01-16
started: 2026-01-16
---

# Task: Energy/Reputation System (Lumon-style)

## Task Details
**Task ID**: T-2025-015-energy-reputation-system
**Epic**: [[E-2025-002-social-friends-system]]
**Status**: Backlog
**Priority**: P1
**Branch**: feat/T-2025-015-energy-reputation-system
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Design and implement a Lumon-inspired energy/reputation system that rewards positive contributions and discourages trolling. Users accumulate or lose "energy" based on their interactions across the platform. Low energy users can be auto-removed from conversations, forcing them to rebuild their standing elsewhere.

### Naming Considerations (Severance Aesthetic)
**Energy unit ideas:**
- "Refinement" - you refine your standing through quality interactions
- "Resonance" - your energy resonates with others
- "Wellness" - Lumon wellness vibes
- "Standing" - your community standing
- "Credit" - Lumon credits

**Feedback actions instead of like/dislike:**
- "Affirm" / "Dismiss"
- "Resonate" / "Dissonance"
- "Acknowledge" / "Question"
- "Accord" / "Discord"

## Ways to Gain Energy

### In-Chat Interactions
- [ ] Receive positive feedback (affirm/resonate) on messages
- [ ] Stay in a conversation for extended time (engagement)
- [ ] Messages that spark replies (conversation contribution)

### Content Creation
- [ ] Create a node that others visit
- [ ] Create a node where conversations happen
- [ ] Node creator gets small energy when others chat in their node

### Community Building
- [ ] Being "remembered" by others (friendship connections)
- [ ] Returning to the platform regularly (consistency bonus)
- [ ] First to speak in a quiet node (icebreaker bonus)

### Exploration
- [ ] Visiting new nodes (discovery bonus)
- [ ] Traveling across the grid (exploration)

## Ways to Lose Energy

### Negative Interactions
- [ ] Receive negative feedback (dismiss/dissonance) on messages
- [ ] Messages flagged/reported
- [ ] Rapid-fire messages (spam detection)

### Abandonment
- [ ] Creating nodes that remain empty
- [ ] Leaving conversations abruptly after causing disruption

## Energy Effects

### Low Energy Consequences
- [ ] Auto-removal from chat when energy drops below threshold
- [ ] Cannot enter busy/popular nodes until energy recovers
- [ ] Visual indicator (dimmed glyph, faded presence)
- [ ] "Cooling off" period required

### High Energy Benefits
- [ ] Brighter/more visible glyph on grid
- [ ] Priority entry to busy nodes
- [ ] Ability to create more nodes
- [ ] Visual "aura" or distinction

## Technical Considerations

### Database
- `user_energy` field or separate energy tracking table
- `energy_transactions` table for history/audit
- Energy decay over time?

### Real-time Updates
- PubSub for energy changes
- Visual feedback when gaining/losing energy
- Animated energy meter in UI?

### Anti-Gaming
- Rate limiting on feedback actions
- Prevent self-boosting via alt accounts
- Decay system to prevent hoarding

## Open Questions
- [ ] Should energy be visible to others or private?
- [ ] How fast should energy accumulate vs deplete?
- [ ] Should there be "energy zones" on the grid?
- [ ] Can you "gift" energy to others?
- [ ] Should node creators see their node's energy contribution?

## Acceptance Criteria
- [ ] Design document approved with naming and mechanics
- [ ] Energy gain/loss mechanics implemented
- [ ] Visual indicators for energy state
- [ ] Auto-moderation (kick low-energy users) working
- [ ] Energy displayed in user profile sidebar

## Context
See [[T-2025-015-context]] for detailed design exploration.

## Notes
- Must feel mysterious and Lumon-like, not gamified
- Energy should be subtle, not a visible "score"
- The goal is organic moderation, not leaderboards
