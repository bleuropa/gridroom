---
type: task
id: T-2025-005
status: backlog
priority: p1
created: 2025-01-15
updated: 2025-01-15
---

# Task: Username/Password Authentication (No Email)

## Task Details
**Task ID**: T-2025-005-username-password-auth
**Status**: Backlog
**Priority**: P1
**Branch**: feat/T-2025-005-username-password-auth
**Created**: 2025-01-15
**Started**:
**Completed**:

## Description
Add simple username/password authentication to Gridroom without requiring email. This aligns with the product philosophy of pseudonymous, low-friction identity. Users can pick any username and create an account instantly - no verification step, no email collection.

Key decisions:
- No email required (matches anonymous-first philosophy)
- Pseudonymous by design
- Accept that password reset won't be available (accounts are disposable)
- Use `mix phx.gen.auth` as starting point, then customize

## Acceptance Criteria
- [ ] Users can register with username + password only
- [ ] Users can log in with username + password
- [ ] No email field in registration/login forms
- [ ] Existing session-based users can optionally create accounts
- [ ] User glyph (shape/color) persists across sessions when logged in
- [ ] Graceful handling of duplicate usernames

## Checklist
- [ ] Run `mix phx.gen.auth` with customizations
- [ ] Remove email field from User schema
- [ ] Update registration form (username + password only)
- [ ] Update login form (username + password only)
- [ ] Connect auth to existing Accounts context
- [ ] Migrate existing anonymous users to auth system
- [ ] Add login/register UI to grid view
- [ ] Test registration flow
- [ ] Test login flow
- [ ] Test session persistence

## Technical Details
### Approach
- Start with `mix phx.gen.auth Accounts User users`
- Modify generated schema to use username instead of email
- Remove email validation, confirmation, password reset flows
- Keep the secure password hashing (bcrypt)
- Integrate with existing `Gridroom.Accounts` context

### Files to Modify
- `lib/gridroom/accounts/user.ex` - Add username, password fields
- `lib/gridroom_web/controllers/user_*` - Generated auth controllers
- `lib/gridroom_web/live/user_*` - Generated auth LiveViews
- `lib/gridroom_web/router.ex` - Auth routes
- New migration for auth fields

### Testing Required
- [ ] Registration with valid username/password
- [ ] Registration with duplicate username (should fail gracefully)
- [ ] Login with correct credentials
- [ ] Login with wrong credentials
- [ ] Session persistence across page loads
- [ ] Logout functionality

## Dependencies
### Blocked By
- None

### Blocks
- Future features requiring persistent identity

## Context
See [[T-2025-005-context]] for detailed implementation notes.

## Notes
- No password reset - accounts are disposable, make a new one
- Could add optional email later for those who want recovery
- Consider passkeys/WebAuthn as future enhancement
- Username uniqueness enforced at DB level
