# Multi-Language Support

Balustrade works with **any programming language or tech stack**.

The meta-framework (`.claude/` and `vault/`) is language-agnostic.

---

## How It Works

Balustrade provides:
- Git hooks (work with any language)
- Slash commands (manage tasks, not code)
- Documentation patterns (language-independent)
- PROJECT_STATUS.md tracking (works everywhere)

Your actual code can be anything.

---

## Examples By Language

### Node.js / JavaScript
```bash
rm -rf example-app/
npm init
npm install express
# Add your Node code
# Hooks still validate commits, docs, tasks
```

### Python
```bash
rm -rf example-app/
python -m venv venv
pip install flask
# Add your Python code
# Framework works the same
```

### Ruby / Rails
```bash
rm -rf example-app/
rails new my-app
# Add your Rails code
# Balustrade validates docs and tasks
```

### Go
```bash
rm -rf example-app/
go mod init myapp
# Add your Go code
# Hooks check git commits regardless of language
```

### Rust
```bash
rm -rf example-app/
cargo init
# Add your Rust code
# Documentation patterns remain the same
```

### Elixir / Phoenix
```bash
rm -rf example-app/
mix phx.new my_app
# Add your Phoenix code
# Task lifecycle works identically
```

### Mobile (iOS, Android, Flutter)
```bash
rm -rf example-app/
# iOS
xcodegen generate
# Or Flutter
flutter create my_app
# Or React Native
npx react-native init MyApp

# Balustrade tracks tasks and docs, not your mobile code
```

---

## What Stays The Same

Regardless of language:

**✅ Git hooks** - Validate commits, docs, task structure
**✅ Slash commands** - `/p`, `/s`, `/c`, `/ctx`, `/status`, `/wrap`
**✅ Vault structure** - product/, architecture/, features/, pm/
**✅ PROJECT_STATUS.md** - Single source of truth
**✅ Task lifecycle** - Plan, start, work, close, PR

---

## What Changes

Per language:

**Build commands** - Update `.devcontainer/devcontainer.json`
**Dependencies** - Your package manager (npm, pip, cargo, etc.)
**Testing** - Your test framework
**Deployment** - Your deployment process

---

## Customizing For Your Stack

### 1. Update Dev Container

Edit `.devcontainer/devcontainer.json`:

```json
{
  "name": "my-python-project",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  // Add your language/tools
}
```

### 2. Add Language-Specific Hooks (Optional)

Edit `.claude/hooks/pre-commit.sh`:

```bash
# Example: Check Python import order
if [ -n "$(find . -name '*.py')" ]; then
    # Add your Python-specific checks
fi
```

### 3. Update Documentation

Update `vault/architecture/` for your stack:
- Database choices
- Framework decisions
- Deployment architecture

---

## The Point

Balustrade is **not** a Node.js tool or Python tool.

It's a **meta-framework** for deterministic project management that works with anything.

The example todo app happens to be Node. Delete it. Use your language.

The `.claude/` patterns and `vault/` structure remain valuable regardless.
