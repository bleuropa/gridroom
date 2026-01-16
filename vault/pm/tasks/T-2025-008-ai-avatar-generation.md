---
type: task
id: T-2025-008
status: backlog
priority: p3
created: 2026-01-16
updated: 2026-01-16
---

# Task: AI Avatar Generation for Auth Users

## Task Details
**Task ID**: T-2025-008-ai-avatar-generation
**Status**: Backlog
**Priority**: P3
**Branch**: feat/T-2025-008-ai-avatar-generation
**Created**: 2026-01-16
**Started**:
**Completed**:

## Description
Authenticated users can generate a unique AI-created avatar image. This adds personality and reward for creating an account while maintaining the abstract, mysterious vibe.

Design considerations:
- Stay abstract/geometric (not realistic faces)
- Could be based on user's glyph shape + color
- One-time generation or re-roll options?
- How/where is avatar displayed?

## Acceptance Criteria
- [ ] Auth users can generate an AI avatar
- [ ] Avatar style matches Gridroom aesthetic (abstract, geometric)
- [ ] Avatar stored and associated with user account
- [ ] Avatar displayed somewhere meaningful (profile? sidebar?)

## Checklist
- [ ] Choose AI image generation API (Replicate? OpenAI DALL-E?)
- [ ] Design prompt template for Gridroom-style avatars
- [ ] Add avatar generation endpoint/action
- [ ] Store generated image (S3 or similar)
- [ ] Display avatar in appropriate locations
- [ ] Add rate limiting (prevent abuse)

## Technical Details
### Approach
- Use existing glyph (shape + color) as seed for prompt
- Generate abstract, geometric avatar
- Store URL in user record
- Display in user's sidebar/profile view

### Prompt Ideas
```
"Abstract geometric avatar, [shape] form, [color] tones,
minimalist, mysterious, soft glow, dark background,
digital art, Severance aesthetic"
```

### Files to Modify
- `lib/gridroom/accounts/user.ex` - add avatar_url field
- New: `lib/gridroom/avatars.ex` - generation context
- New controller/live component for generation UI

## Dependencies
### Blocked By
- [[T-2025-005-username-password-auth]] ✅

### Blocks
- None

## Context
See [[T-2025-008-context]] for detailed implementation notes.

## Notes
- Keep costs reasonable - maybe one free generation, pay for re-rolls?
- This is a "delight" feature, not critical path
- Could tie into future premium features
