# Context: T-2025-005 Username/Password Auth

**Task**: [[T-2025-005-username-password-auth]]
**Created**: 2025-01-15
**Completed**: 2026-01-16
**Status**: Done

## Overview

Added simple username/password authentication without email. This matches Gridroom's philosophy of pseudonymous, low-friction identity. Users can persist their identity (and glyph) across sessions without requiring personal data.

## Key Decisions

- **No email**: Aligns with anonymous-first approach, reduces friction
- **No password reset**: Accept this limitation - accounts are cheap to create
- **Username uniqueness**: Enforced at DB level with clear error messaging
- **Glyph persistence**: Logged-in users keep their shape/color across sessions
- **Manual implementation**: Did not use `mix phx.gen.auth` to avoid conflicts with existing User schema
- **Auto-login on register**: Registration automatically logs user in and redirects to grid

## Implementation Summary

### Files Created
- `lib/gridroom_web/live/user_registration_live.ex` - Registration form
- `lib/gridroom_web/live/user_login_live.ex` - Login form
- `lib/gridroom_web/controllers/user_session_controller.ex` - Session management

### Files Modified
- `lib/gridroom/accounts/user.ex` - Added registration_changeset, valid_password?
- `lib/gridroom/accounts.ex` - Added register_user, authenticate_user, get_user_by_username
- `lib/gridroom_web/router.ex` - Added auth routes
- `lib/gridroom_web/live/grid_live.ex` - Check for logged-in user, show auth UI
- `lib/gridroom_web/live/node_live.ex` - Check for logged-in user

### Migrations
- `20260116025720_add_auth_to_users.exs` - Add username, hashed_password fields
- `20260116144838_make_session_id_nullable.exs` - Allow null session_id for registered users

### Dependencies
- Added `bcrypt_elixir ~> 3.0` for password hashing

## Technical Details

### Auth Flow
1. **Registration**: POST to `/register` → Create user with bcrypt password → Set session → Redirect to grid
2. **Login**: POST to `/login` → Verify password with bcrypt → Set session → Redirect to grid
3. **Logout**: DELETE to `/logout` → Clear session → Redirect to grid

### User Resolution in LiveViews
```elixir
user =
  case session["user_id"] do
    nil ->
      # Anonymous user from CSRF token
      {:ok, user} = Accounts.get_or_create_user(session_id)
      user
    user_id ->
      # Logged-in user
      Accounts.get_user(user_id)
  end
```

### Glyph Inheritance
When an anonymous user registers, their existing glyph (shape/color) is preserved in the new account.

## Resolved Questions

1. **Glyph claiming**: Yes, anonymous users keep their glyph when registering
2. **Password length**: 8 characters minimum, 72 max
3. **Username constraints**: Alphanumeric + underscore, 3-20 chars
4. **Rate limiting**: Not implemented yet (future enhancement)

