---
type: task
id: T-2025-023
status: completed
priority: p1
created: 2026-01-17
updated: 2026-01-17
completed: 2026-01-17
---

# Task: Gemini Google Search Grounding for Folder Topics

## Task Details
**Task ID**: T-2025-023
**Status**: Completed
**Priority**: P1 (High)
**Branch**: feat/T-2025-023-gemini-google-search-grounding
**Created**: 2026-01-17
**Started**: 2026-01-17
**Completed**: 2026-01-17

## Description
Enhance the folder scheduler to fetch 3-4 additional topics per folder using Gemini's Google Search grounding feature. This diversifies topic sources beyond Grok/X-search, providing better coverage and real-time web information from Google Search.

Gemini's grounding with Google Search:
- Connects Gemini to real-time web content
- Increases factual accuracy by basing responses on real-world information
- Provides citations with verifiable sources
- Works with gemini-3-flash-preview model

## Checklist
- [x] Add Gemini API client module
- [x] Create Gemini-specific folder fetcher
- [x] Update FolderScheduler to call both Grok and Gemini
- [x] Parse Gemini grounding metadata for sources/citations
- [x] Store source URLs from grounding chunks
- [x] Update config for Gemini API key and settings
- [x] Add rate limiting between Gemini calls
- [x] Swap model to gemini-3-flash-preview
- [x] Remove legacy 4-hour trending scheduler
- [x] Update decay threshold to 5 days (vaulting)
- [x] Add bootstrap fetch on first deploy

## Technical Details
### Approach
- Create `Gridroom.Gemini.Client` module for API interaction
- Create `Gridroom.Gemini.FolderFetcher` for grounded topic queries
- Modify FolderScheduler to orchestrate both sources
- Use gemini-3-flash-preview with google_search tool
- Extract groundingChunks URIs as source citations
- Merge results from both APIs before creating nodes

### API Integration
```elixir
# REST call to Gemini with grounding
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent
Headers: x-goog-api-key, Content-Type: application/json
Body: {
  "contents": [{"parts": [{"text": "prompt"}]}],
  "tools": [{"google_search": {}}]
}
```

### Files to Modify
- `lib/gridroom/gemini/client.ex` (new)
- `lib/gridroom/gemini/folder_fetcher.ex` (new)
- `lib/gridroom/grok/folder_scheduler.ex` - add Gemini calls
- `config/config.exs` - Gemini API configuration
- `config/runtime.exs` - GEMINI_API_KEY env var

### Testing Required
- [ ] Unit tests for Gemini client
- [ ] Manual testing of grounded responses
- [ ] Verify citations are captured correctly

## Dependencies
### Blocked By
- None (extends existing T-2025-022 folder system)

### Blocks
- None

## Context
See [[T-2025-023-context]] for detailed implementation notes.

## Commits
-

## Review Checklist
- [x] Code review completed
- [ ] Tests written and passing
- [x] Documentation updated
- [x] No debugger statements
- [x] Security considerations addressed

## Notes
- Gemini 3 billing for Grounding with Google Search starts January 5, 2026
- Each search query the model executes is billed separately
- Model may execute multiple search queries per prompt
