# Context: T-2025-005 Username/Password Auth

**Task**: [[T-2025-005-username-password-auth]]
**Created**: 2025-01-15
**Status**: Planning

## Overview

Add simple username/password authentication without email. This matches Gridroom's philosophy of pseudonymous, low-friction identity. The goal is to let users persist their identity (and glyph) across sessions without requiring personal data.

## Key Decisions

- **No email**: Aligns with anonymous-first approach, reduces friction
- **No password reset**: Accept this limitation - accounts are cheap to create
- **Username uniqueness**: Enforced at DB level with clear error messaging
- **Glyph persistence**: Logged-in users keep their shape/color across sessions

## Implementation Plan

### Phase 1: Generate Auth Scaffolding
```bash
mix phx.gen.auth Accounts User users
```

This generates:
- User schema with password hashing
- Registration/login LiveViews
- Session management
- Plugs for authentication

### Phase 2: Customize for Username-Only

1. **Modify User schema**:
   - Remove `email` field
   - Add `username` field (unique, required)
   - Keep `hashed_password`
   - Keep existing `glyph_shape`, `glyph_color` fields

2. **Update changeset**:
   - Validate username (alphanumeric, 3-20 chars)
   - Remove email validations
   - Keep password validations

3. **Update forms**:
   - Registration: username + password + password_confirmation
   - Login: username + password

### Phase 3: Integrate with Existing System

Current flow:
- Anonymous users get session-based identity via CSRF token
- `Accounts.get_or_create_user/1` creates User from session

New flow:
- Anonymous users still work as before
- Registered users bypass session-based lookup
- Login associates existing glyph with account

### Phase 4: UI Integration

- Add discrete login/register links to grid view
- Modal or slide-out panel for auth forms
- Show username in UI when logged in
- Keep anonymous mode as valid option

## Open Questions

1. Should anonymous users be able to "claim" their current glyph when registering?
2. Minimum password length? (suggest 8 chars)
3. Username constraints? (suggest: alphanumeric + underscore, 3-20 chars)
4. Rate limiting on registration to prevent spam?

## Next Steps

1. Run `/s T-2025-005` to start work
2. Generate auth scaffolding
3. Customize for username-only
4. Integrate with existing Accounts context
