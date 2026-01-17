# Context: T-2025-022 MDR Folder System

**Task**: [[T-2025-022-mdr-folder-system]]
**Created**: 2026-01-17
**Status**: Planning

## Overview

Build a Macro Data Refinement-inspired folder system that organizes discussions into categorical "bins" (sports, gossip, tech, politics, etc.). Users refine discussions within each folder, and completing a folder triggers a Lumon-style celebration with wellness messaging.

## Key Decisions

- Folders displayed at top of emergence page as horizontal tabs/bins
- One folder active at a time (cycling through them)
- Each folder has its own Oban job to fetch 7-9 daily topics
- Each folder has a custom system prompt for Grok X-search queries
- Progress tracking per user per folder
- Completion triggers visual celebration + wellness message

## Folder Categories (Initial Set)

1. **Sports** - Athletic competitions, scores, player news
2. **Gossip** - Celebrity news, entertainment, pop culture drama
3. **Tech** - Technology trends, product launches, industry news
4. **Politics** - Political news, policy, elections
5. **Finance** - Markets, economy, business news
6. **Science** - Research, discoveries, space, health

## Lumon Wellness Messages (Examples)

- Sports: "Your dedication to athletic data refinement has brought balance to the numbers. Kier smiles upon your efforts."
- Gossip: "The whispers have been sorted. Your work brings harmony to the social frequencies. Rest well, refiner."
- Tech: "The digital frontiers bow to your precision. Kier thanks you for taming the innovation chaos."
- Politics: "The civic patterns are now clear. Your service to the democratic data is noted and appreciated."

## Database Schema

```sql
-- Folders table
CREATE TABLE folders (
  id BIGSERIAL PRIMARY KEY,
  slug VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  system_prompt TEXT NOT NULL,
  completion_message TEXT NOT NULL,
  icon VARCHAR(50),
  sort_order INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Link discussions to folders
CREATE TABLE folder_discussions (
  id BIGSERIAL PRIMARY KEY,
  folder_id BIGINT REFERENCES folders(id),
  discussion_id BIGINT REFERENCES discussions(id),
  date DATE NOT NULL,
  inserted_at TIMESTAMP
);

-- Track user progress per folder
CREATE TABLE user_folder_progress (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  folder_id BIGINT REFERENCES folders(id),
  date DATE NOT NULL,
  refined_count INTEGER DEFAULT 0,
  total_count INTEGER NOT NULL,
  completed_at TIMESTAMP,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(user_id, folder_id, date)
);
```

## Implementation Plan

### Phase 1: Database & Core Infrastructure
1. Create migrations for folders, folder_discussions, user_folder_progress
2. Create Folder schema and context module
3. Seed initial folder categories with system prompts and messages

### Phase 2: Oban Jobs
1. Create base folder worker module
2. Create per-folder workers (or parameterized single worker)
3. Schedule daily runs to fetch 7-9 topics per folder via Grok

### Phase 3: UI Integration
1. Add folder navigation component to emergence page
2. Show active folder's discussions
3. Implement folder cycling (arrow keys or tab)
4. Track refinement actions per folder

### Phase 4: Completion Flow
1. Detect when all discussions in folder are refined
2. Trigger completion visual (folder transforms/animates)
3. Display Lumon wellness message modal/overlay
4. Mark folder as completed for the day

## Open Questions

- Should folders reset daily or persist until all are complete?
- Allow users to manually switch folders or force sequential completion?
- What visual treatment for active vs inactive vs completed folders?

## Next Steps

1. Review plan with user
2. Run `/s T-2025-022` to start work
