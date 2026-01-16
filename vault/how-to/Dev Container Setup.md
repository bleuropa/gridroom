# Dev Container Setup

Balustrade includes a minimal dev container configuration for multi-agent workflows.

---

## What's A Dev Container?

A Docker container configured for development:
- Consistent environment across machines
- No "works on my machine" problems
- Pre-installed tools and dependencies
- VS Code integration

---

## Balustrade's Dev Container

Located in `.devcontainer/devcontainer.json`.

**Minimal by default**: Just a base Ubuntu image.

**Why minimal?** Works with any language/stack. Customize for your project.

---

## Multi-Agent Pattern

Dev containers enable Claude Code's multi-agent workflows:

### How It Works

1. **Container isolation** - Each service in its own environment
2. **Port forwarding** - Access services from host machine
3. **Shared workspace** - All agents see same codebase
4. **Coordinated work** - Agents can work on different services simultaneously

### Example: Full-Stack App

```json
{
  "name": "my-app",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "forwardPorts": [3000, 5432, 6379],
  // Port 3000: API
  // Port 5432: Postgres
  // Port 6379: Redis
}
```

Agents can:
- Backend agent works on API (port 3000)
- Database agent manages schema (port 5432)
- Cache agent optimizes Redis (port 6379)
- Coordinator orchestrates between them

---

## Customizing For Your Stack

### Node.js Project

```json
{
  "name": "node-app",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:20",
  "forwardPorts": [3000],
  "postCreateCommand": "npm install"
}
```

### Python Project

```json
{
  "name": "python-app",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "forwardPorts": [8000],
  "postCreateCommand": "pip install -r requirements.txt"
}
```

### Full-Stack (Node + Postgres)

```json
{
  "name": "fullstack-app",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "forwardPorts": [3000, 5432],
  "postCreateCommand": "npm install && npm run db:migrate"
}
```

With `docker-compose.yml`:
```yaml
services:
  app:
    image: mcr.microsoft.com/devcontainers/javascript-node:20
    volumes:
      - .:/workspace
    ports:
      - "3000:3000"

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: dev
    ports:
      - "5432:5432"
```

---

## Configurable Ports Pattern

From Flojo (reference implementation):

**Key idea**: Make ports configurable via environment variables.

**Why?** Different developers might have port conflicts.

**How**:

`.env`:
```
API_PORT=3000
DB_PORT=5432
REDIS_PORT=6379
```

`devcontainer.json`:
```json
{
  "forwardPorts": [
    "${localEnv:API_PORT}",
    "${localEnv:DB_PORT}",
    "${localEnv:REDIS_PORT}"
  ]
}
```

Now each developer can customize ports without conflicts.

---

## Benefits For Claude Code

Dev containers enable:

1. **Consistent environment** - Claude sees same setup as you
2. **Multi-service coordination** - Multiple agents, multiple services
3. **Isolated testing** - Test changes without affecting host
4. **Easy onboarding** - New contributors just open in container

---

## Getting Started

### 1. Install Docker Desktop
Download from [docker.com](https://docker.com)

### 2. Install VS Code Extension
"Dev Containers" extension by Microsoft

### 3. Open in Container
- Command Palette (Cmd/Ctrl+Shift+P)
- "Dev Containers: Reopen in Container"
- Wait for build (first time only)

### 4. Verify
- Terminal opens inside container
- Ports forwarded to localhost
- Extensions installed
- Ready to work

---

## Common Issues

### Port Already in Use
Change ports in `.devcontainer/devcontainer.json` or use environment variables.

### Slow Build
First build takes time. Subsequent opens are fast (cached).

### Changes Not Reflected
Rebuild container: Command Palette → "Dev Containers: Rebuild Container"

---

## The Point

Dev containers are optional but powerful:
- Not required for Balustrade
- Highly recommended for teams
- Essential for multi-agent workflows
- Customize for your stack

See Flojo (reference repo) for advanced multi-service setup.
