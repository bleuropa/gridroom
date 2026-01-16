---
tags: [architecture, data-model]
status: current
updated: YYYY-MM-DD
---

# Data Model

## Overview

This document describes the database schema and data relationships. Keep this in sync with the actual schema.

---

## Entity Relationship Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    User      │────<│   [Entity]   │>────│   [Entity]   │
│              │     │              │     │              │
│ id           │     │ id           │     │ id           │
│ email        │     │ userId       │     │ [field]      │
│ name         │     │ [field]      │     │ [field]      │
│ createdAt    │     │ createdAt    │     │ createdAt    │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## Core Entities

### User

**Purpose**: [User account and profile]

| Field | Type | Description |
|-------|------|-------------|
| id | String | Primary key (cuid) |
| email | String | Unique, required |
| name | String? | Display name |
| createdAt | DateTime | Account creation |
| updatedAt | DateTime | Last modification |

**Relations**:
- Has many [Entity]
- Has many [Entity]

---

### [Entity Name]

**Purpose**: [What this entity represents]

| Field | Type | Description |
|-------|------|-------------|
| id | String | Primary key |
| userId | String | Foreign key to User |
| [field] | [Type] | [Description] |
| [field] | [Type] | [Description] |
| createdAt | DateTime | Creation timestamp |
| updatedAt | DateTime | Last update |

**Relations**:
- Belongs to User
- Has many [Entity]

**Indexes**:
- `userId` - Query by owner
- `[field]` - [Why indexed]

---

### [Entity Name]

**Purpose**: [What this entity represents]

| Field | Type | Description |
|-------|------|-------------|
| id | String | Primary key |
| [parentId] | String | Foreign key to [Parent] |
| [field] | [Type] | [Description] |

**Relations**:
- Belongs to [Parent]

---

## Enums

### [EnumName]

| Value | Description |
|-------|-------------|
| VALUE_1 | [What it means] |
| VALUE_2 | [What it means] |
| VALUE_3 | [What it means] |

---

## Key Relationships

### [Relationship Name]

```
User --1:N--> [Entity] --1:N--> [Entity]
```

**Description**: [How these entities relate and why]

---

## Access Patterns

### Common Queries

1. **Get user's [entities]**
   ```
   [Entity].findMany({ where: { userId } })
   ```

2. **Get [entity] with [relations]**
   ```
   [Entity].findUnique({ where: { id }, include: { [relation]: true } })
   ```

---

## Soft Delete Strategy

[Describe if/how soft deletes are implemented]

- **Entities with soft delete**: [Entity], [Entity]
- **Hard delete**: [Entity]
- **Cascade behavior**: [Describe]

---

## Migration Notes

[Any notes about schema migrations or data transformations]

---

## Related

- [[System Architecture]] - How data flows through the system
- [[Prisma Schema]] - `prisma/schema.prisma`
