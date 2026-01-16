# Context: T-2025-015 Energy/Reputation System

**Task**: [[T-2025-015-energy-reputation-system]]
**Created**: 2026-01-16
**Status**: Design Phase

## Overview

A Lumon-inspired energy system that creates organic community moderation. Good contributions build energy, trolling depletes it. Low energy = consequences (kicked from chats, restricted access). High energy = subtle benefits.

## Design Philosophy

The system should feel **mysterious and ambient**, not gamified:
- No visible scores or leaderboards
- Energy is felt, not displayed numerically
- Effects are subtle (glyph brightness, access permissions)
- Matches Severance aesthetic: corporate wellness meets eerie undertones

## Naming Exploration

### Energy Unit
| Option | Pros | Cons |
|--------|------|------|
| **Refinement** | Fits Lumon vibe, suggests growth | May need verb form |
| **Resonance** | Ethereal, fits grid aesthetic | Abstract |
| **Wellness** | Direct Lumon reference | Too on-the-nose? |
| **Standing** | Clear meaning | Too generic |
| **Quota** | Lumon reference | Implies work/grind |

**Recommendation**: "Refinement" - "Your refinement has increased" feels Lumon

### Feedback Actions
Instead of Like/Dislike:
| Positive | Negative | Notes |
|----------|----------|-------|
| Affirm | Dismiss | Corporate, clear |
| Resonate | Dissonance | Musical/ethereal |
| Acknowledge | Question | Subtle, less binary |
| Accord | Discord | Formal, balanced |

**Recommendation**: "Affirm" / "Dismiss" - feels corporate and Lumon-like

## Energy Mechanics Brainstorm

### Earning Energy

1. **Chat Quality**
   - Affirmed messages: +2 refinement
   - Messages that get replies: +1 refinement
   - Extended conversation participation: +1/minute (capped)

2. **Node Creation**
   - Create a node: 0 (neutral)
   - Someone visits your node: +1
   - Conversation happens in your node: +2 per unique visitor who chats
   - Your node becomes popular (5+ visitors): +10 bonus

3. **Social**
   - Being "remembered" by someone: +5
   - Returning daily: +3 (login bonus)
   - First message in quiet node: +2 (icebreaker)

4. **Exploration**
   - Visiting a new node: +1
   - Traveling 100+ grid units: +1

### Losing Energy

1. **Chat Quality**
   - Dismissed message: -3 refinement
   - Multiple dismisses quickly: -5 each (accelerating)
   - Reported message: -20

2. **Spam Detection**
   - 3+ messages in 10 seconds: -5
   - Repeated similar messages: -10

3. **Abandonment**
   - Create node, never visited after 24h: -2
   - Enter node, spam, leave quickly: -15

### Energy Decay
- Slow decay over time if inactive: -1/day after 3 days
- Prevents energy hoarding
- Encourages ongoing participation

## Energy States & Effects

### Energy Levels (Hidden Thresholds)

| State | Range | Visual Effect | Access Effect |
|-------|-------|--------------|---------------|
| Depleted | 0-10 | Dimmed glyph, flickering | Kicked from busy nodes, cooldown |
| Low | 11-30 | Slightly faded | Cannot enter popular nodes |
| Normal | 31-70 | Standard | Full access |
| Elevated | 71-100 | Subtle glow | Priority entry, can create more nodes |
| Radiant | 100+ | Warm aura | Visible distinction, trusted status |

### Visual Treatment (Lumon Style)
- No numbers displayed
- Glyph brightness correlates to energy
- Low energy: glyph has slight static/flicker
- High energy: glyph has warm ember glow
- Ambient text: "Your refinement feels [strong/steady/wavering]"

## Moderation Effects

### Auto-Kick Mechanic
When user drops below 10 refinement in a node:
1. Message appears: "Your refinement has become unstable."
2. 30-second warning with visual dimming
3. "You have been redirected for recalibration."
4. User is sent back to grid, blocked from that node for 10 minutes

### Recovery
- User must go elsewhere to rebuild energy
- Visiting quiet nodes, participating positively
- "Cooling off" naturally resets over time

## UI Integration Points

### Profile Sidebar
- Ambient energy indicator (not numeric)
- "Refinement: Steady" / "Refinement: Wavering"
- Recent energy events (subtle)

### Presence Diamonds
- Brightness reflects energy
- Low energy users appear dimmer
- High energy users have subtle glow

### Message Interaction
- Hover message → show Affirm/Dismiss options
- Subtle icons, not prominent buttons
- Rate limited: can only give feedback every 30 seconds

## Database Schema Ideas

```sql
-- Energy balance
ALTER TABLE users ADD COLUMN refinement INTEGER DEFAULT 50;

-- Energy transactions for audit/history
CREATE TABLE energy_transactions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  amount INTEGER,
  reason VARCHAR(50),  -- 'affirm_received', 'dismiss_received', 'node_visited', etc.
  source_user_id UUID,  -- who caused this (if applicable)
  node_id UUID,
  created_at TIMESTAMP
);

-- Rate limiting for feedback
CREATE TABLE feedback_cooldowns (
  user_id UUID,
  target_user_id UUID,
  last_feedback_at TIMESTAMP,
  PRIMARY KEY (user_id, target_user_id)
);
```

## Open Questions

1. **Visibility**: Should users see their own refinement level?
   - Option A: Completely hidden, only felt through effects
   - Option B: Ambient indicator ("Your refinement feels strong")
   - Option C: Subtle meter in profile

2. **Decay Rate**: How fast should energy decline when inactive?
   - Aggressive: -5/day (forces daily engagement)
   - Moderate: -1/day after 3 days inactive
   - None: Only lose through negative actions

3. **Energy Zones**: Should some grid areas require minimum energy?
   - "Premium" nodes that require elevated refinement
   - Creates natural social stratification
   - May feel exclusionary

4. **Gifting**: Can users transfer energy to others?
   - Interesting social mechanic
   - Could be abused for boosting

5. **Node Creator Rewards**: How prominent?
   - Small passive income feels right
   - Too much incentivizes low-quality node spam

## Implementation Phases

### Phase 1: Foundation
- Add refinement field to users
- Create energy_transactions table
- Basic earn/lose mechanics (affirm/dismiss)

### Phase 2: Visual Integration
- Glyph brightness tied to energy
- Ambient status text in profile
- Affirm/Dismiss UI on messages

### Phase 3: Moderation Effects
- Auto-kick for depleted users
- Node access restrictions
- Cooldown/recovery mechanics

### Phase 4: Advanced
- Node creator rewards
- Exploration bonuses
- Energy decay system

## Next Steps

1. Decide on naming (Refinement? Resonance?)
2. Decide on feedback verbs (Affirm/Dismiss?)
3. Design minimal viable version
4. Run `/s T-2025-015` to start implementation

## Auto-saved State (2026-01-16 15:23)

Recent commits:
- feat: Resonance system foundation (T-2025-015)
- chore: start work on T-2025-015
- chore: complete T-2025-014, update status

**Note**: This entry was auto-generated before memory compaction.

