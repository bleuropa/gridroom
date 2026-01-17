---
type: task
id: T-2025-023
status: backlog
priority: p1
created: 2026-01-17
updated: 2026-01-17
---

# Task: Gemini Google Search Grounding for Folder Topics

## Task Details
**Task ID**: T-2025-023
**Status**: Todo
**Priority**: P1 (High)
**Branch**: feat/T-2025-023-gemini-google-search-grounding
**Created**: 2026-01-17
**Started**:
**Completed**:

## Description
Enhance the folder scheduler to fetch 3-4 additional topics per folder using Gemini's Google Search grounding feature. This diversifies topic sources beyond Grok/X-search, providing better coverage and real-time web information from Google Search.

Gemini's grounding with Google Search:
- Connects Gemini to real-time web content
- Increases factual accuracy by basing responses on real-world information
- Provides citations with verifiable sources
- Works with gemini-3-flash-preview model

## Checklist
- [ ] Add Gemini API client module
- [ ] Create Gemini-specific folder fetcher
- [ ] Update FolderScheduler to call both Grok and Gemini
- [ ] Parse Gemini grounding metadata for sources/citations
- [ ] Store source URLs from grounding chunks
- [ ] Update config for Gemini API key and settings
- [ ] Add rate limiting between Gemini calls

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
- [ ] Code review completed
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debugger statements
- [ ] Security considerations addressed

## Notes
- Gemini 3 billing for Grounding with Google Search starts January 5, 2026
- Each search query the model executes is billed separately
- Model may execute multiple search queries per prompt
