---
type: task
id: T-2025-005
status: done
priority: p1
created: 2025-01-15
updated: 2026-01-16
---

# Task: Username/Password Authentication (No Email)

## Task Details
**Task ID**: T-2025-005-username-password-auth
**Status**: Done
**Priority**: P1
**Branch**: feat/T-2025-005-username-password-auth
**Created**: 2025-01-15
**Started**: 2025-01-15
**Completed**: 2026-01-16

## Description
Add simple username/password authentication to Gridroom without requiring email. This aligns with the product philosophy of pseudonymous, low-friction identity. Users can pick any username and create an account instantly - no verification step, no email collection.

Key decisions:
- No email required (matches anonymous-first philosophy)
- Pseudonymous by design
- Accept that password reset won't be available (accounts are disposable)
- Use `mix phx.gen.auth` as starting point, then customize

## Acceptance Criteria
- [x] Users can register with username + password only
- [x] Users can log in with username + password
- [x] No email field in registration/login forms
- [x] Existing session-based users can optionally create accounts
- [x] User glyph (shape/color) persists across sessions when logged in
- [x] Graceful handling of duplicate usernames

## Checklist
- [x] Add bcrypt_elixir dependency for password hashing
- [x] Create migration for username/hashed_password fields
- [x] Make session_id nullable for registered users
- [x] Update User schema with registration_changeset
- [x] Add authenticate_user/2 to Accounts context
- [x] Create UserRegistrationLive
- [x] Create UserLoginLive
- [x] Create UserSessionController for session management
- [x] Add login/register UI to grid view
- [x] Test registration flow
- [x] Test login flow
- [x] Auto-login after registration

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
- [x] Registration with valid username/password
- [x] Registration with duplicate username (should fail gracefully)
- [x] Login with correct credentials
- [x] Login with wrong credentials
- [x] Session persistence across page loads
- [x] Logout functionality

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
