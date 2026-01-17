---
type: task
id: T-2025-022
status: in-progress
priority: p1
created: 2026-01-17
updated: 2026-01-17
---

# Task: MDR Folder System for Discussion Categories

## Task Details
**Task ID**: T-2025-022
**Status**: In Progress
**Priority**: P1 (High)
**Branch**: feat/T-2025-022-mdr-folder-system
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**:

## Description
Implement a Macro Data Refinement-inspired folder system for organizing discussions by category on the terminal emergence page. Folders represent different topic areas (sports, gossip, tech, politics, etc.) and are displayed at the top of the interface. Users can cycle through folders one at a time, refining discussions within each folder via spacebar or x. When all topics in a folder are refined, it displays a completed visual state with a Lumon wellness message thanking the innie.

## Checklist
- [ ] Design folder data model and database schema
- [ ] Create Oban jobs for each folder category to fetch daily topics via Grok X-search
- [ ] Create system prompts specific to each folder category
- [ ] Build folder display UI at top of terminal emergence page
- [ ] Implement folder cycling navigation (one at a time)
- [ ] Track refinement progress per folder per user
- [ ] Design and implement folder completion visual state
- [ ] Create Lumon wellness messages for each folder category
- [ ] Wire up spacebar/x refinement to folder progress tracking

## Technical Details
### Approach
- Add `folders` table with categories, system prompts, completion messages
- Add `folder_discussions` join table linking discussions to folders
- Add `user_folder_progress` table tracking completion state per user
- Create per-folder Oban workers that run daily to populate 7-9 topics
- Modify emergence page to show folder nav at top with active folder highlighted
- Folder cycling: left/right arrows or dedicated keys
- On folder completion: trigger celebration visual + wellness message

### Files to Modify
- Database migrations (new tables)
- `lib/gridroom/discussions/` - folder context and schemas
- `lib/gridroom_web/live/emergence_live.ex` - folder UI and cycling
- `lib/gridroom/workers/` - Oban job workers per folder
- `lib/gridroom/grok/` - system prompts per folder
- CSS/styling for folder completion visual

### Testing Required
- [ ] Unit tests for folder completion tracking
- [ ] Integration tests for Oban jobs populating folders
- [ ] Manual testing of folder cycling UX
- [ ] Manual testing of completion celebration

## Dependencies
### Blocked By
- None (builds on existing emergence interface)

### Blocks
- None

## Context
See [[T-2025-022-context]] for detailed implementation notes.

## Commits
-

## Review Checklist
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debugger statements
- [ ] Security considerations addressed

## Notes
- Inspired by Severance's Macro Data Refinement aesthetic
- Each folder should feel like a distinct "bin" of data to refine
- Wellness messages should match Lumon's corporate wellness tone
