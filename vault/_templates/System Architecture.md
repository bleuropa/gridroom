---
tags: [architecture, system]
status: current
updated: YYYY-MM-DD
---

# System Architecture

## Overview

This document describes how the major system components interact. Update this when adding new services or changing data flows.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Browser   │  │   Mobile    │  │    CLI      │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                      API LAYER                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              [Framework] (Next.js/Express/etc)       │   │
│  │                                                      │   │
│  │   /api/[endpoint]    /api/[endpoint]                │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                            │
│                                                              │
│   ┌───────────┐   ┌───────────┐   ┌───────────┐           │
│   │  Service  │   │  Service  │   │  Service  │           │
│   │    A      │   │    B      │   │    C      │           │
│   └─────┬─────┘   └─────┬─────┘   └─────┬─────┘           │
│         │               │               │                  │
└─────────┼───────────────┼───────────────┼──────────────────┘
          │               │               │
          ▼               ▼               ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATA LAYER                               │
│                                                              │
│   ┌───────────┐   ┌───────────┐   ┌───────────┐           │
│   │ Database  │   │   Cache   │   │  Storage  │           │
│   │(Postgres) │   │  (Redis)  │   │   (S3)    │           │
│   └───────────┘   └───────────┘   └───────────┘           │
└─────────────────────────────────────────────────────────────┘
```

---

## Key Components

### API Layer

**Technology**: [Framework name]

**Responsibilities**:
- Request validation
- Authentication/Authorization
- Route handling
- Response formatting

**Key files**:
- `src/app/api/` - API routes
- `src/lib/auth.ts` - Authentication

---

### Service Layer

**[Service A]**

- **Purpose**: [What it does]
- **Location**: `src/lib/[service].ts`
- **Dependencies**: [What it needs]

**[Service B]**

- **Purpose**: [What it does]
- **Location**: `src/lib/[service].ts`
- **Dependencies**: [What it needs]

---

### Data Layer

**Primary Database**: [PostgreSQL/MySQL/etc]
- **ORM**: [Prisma/Drizzle/etc]
- **Schema**: `prisma/schema.prisma`
- **See**: [[Data Model]]

**Cache** (if applicable):
- **Technology**: [Redis/Memory/etc]
- **Purpose**: [Session storage, rate limiting, etc]

---

## External Services

| Service | Purpose | SDK/Integration |
|---------|---------|-----------------|
| [Auth Provider] | Authentication | [SDK name] |
| [Payment Provider] | Billing | [SDK name] |
| [AI Provider] | [Purpose] | [SDK name] |
| [Email Provider] | Transactional email | [SDK name] |

---

## Data Flows

### [Flow Name] (e.g., User Authentication)

```
1. Client → POST /api/auth/signin
2. API validates credentials
3. Session created in [store]
4. Token returned to client
5. Client stores token
```

### [Flow Name] (e.g., Main Feature)

```
1. Client → POST /api/[endpoint]
2. Auth middleware validates session
3. Service [A] processes request
4. Service [B] called if needed
5. Data persisted to database
6. Response returned to client
```

---

## Background Jobs

### Job Queue System

**Technology**: [Inngest/BullMQ/etc]

**Jobs**:

| Job | Trigger | Purpose |
|-----|---------|---------|
| [job-name] | [Schedule/Event] | [What it does] |
| [job-name] | [Schedule/Event] | [What it does] |

---

## Security Model

### Authentication

- **Method**: [JWT/Session/OAuth]
- **Provider**: [NextAuth/Auth0/etc]
- **Session duration**: [Time]

### Authorization

- **Model**: [RBAC/ABAC/etc]
- **Roles**: [List roles]
- **Permission checks**: [Where enforced]

### Data Protection

- **At rest**: [Encryption method]
- **In transit**: [TLS version]
- **Secrets management**: [How secrets are stored]

---

## Deployment

### Infrastructure

- **Hosting**: [Vercel/AWS/etc]
- **Database**: [Managed service name]
- **CDN**: [Provider if any]

### Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| Development | localhost:3000 | Local dev |
| Staging | staging.[domain] | Testing |
| Production | [domain] | Live |

---

## Observability

### Logging

- **Provider**: [Service name]
- **Log levels**: [What's logged where]

### Monitoring

- **Uptime**: [Service]
- **Performance**: [Service]
- **Errors**: [Service]

---

## Related

- [[Data Model]] - Database schema
- [[Technical Architecture]] - Detailed technical decisions
- [[Deployment Guide]] - How to deploy
