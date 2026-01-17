# Context: T-2025-023 Gemini Google Search Grounding

**Task**: [[T-2025-023-gemini-google-search-grounding]]
**Created**: 2026-01-17
**Status**: Planning

## Overview

Add Gemini with Google Search grounding as a second source of trending topics for the folder system. This complements the existing Grok/X-search integration.

**Sources**:
- Grok/X-search: Twitter/X trending topics (existing)
- Gemini/Google: Google Search grounded topics (new)

## Gemini API Details

### Endpoint
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent
```

### Request Format
```json
{
  "contents": [
    {
      "parts": [
        {"text": "What are the top 4 trending topics in sports news today? Return as JSON array with title and description."}
      ]
    }
  ],
  "tools": [
    {
      "google_search": {}
    }
  ]
}
```

### Response Structure
```json
{
  "candidates": [
    {
      "content": {
        "parts": [{"text": "response text..."}],
        "role": "model"
      },
      "groundingMetadata": {
        "webSearchQueries": ["search query 1", "search query 2"],
        "groundingChunks": [
          {"web": {"uri": "https://...", "title": "source title"}}
        ],
        "groundingSupports": [
          {
            "segment": {"startIndex": 0, "endIndex": 85, "text": "..."},
            "groundingChunkIndices": [0]
          }
        ]
      }
    }
  ]
}
```

## Key Decisions

- Use `gemini-3-flash-preview` model for speed and cost
- Fetch 3-4 topics per folder from Gemini (vs 7-9 from Grok)
- Store grounding chunk URIs as node sources
- Run Gemini calls sequentially after Grok to avoid rate limiting
- Mark nodes with source (grok vs gemini) for analytics

## Implementation Plan

1. **Create Gemini client** (`lib/gridroom/gemini/client.ex`)
   - HTTP client using Tesla or Req
   - API key configuration
   - Rate limiting

2. **Create Gemini folder fetcher** (`lib/gridroom/gemini/folder_fetcher.ex`)
   - System prompts adapted for Gemini
   - Parse grounding metadata
   - Extract topics and sources

3. **Update FolderScheduler** (`lib/gridroom/grok/folder_scheduler.ex`)
   - Add Gemini fetching after Grok
   - Merge results
   - Handle failures gracefully (one source failing shouldn't break the other)

4. **Add configuration**
   - GEMINI_API_KEY environment variable
   - Enable/disable toggle
   - Topics count per folder

## Open Questions

- Should we add a `source` field to nodes to track origin (grok/gemini)?
- Should Gemini prompts be different from Grok prompts?
- How to handle duplicate topics between sources?

## Next Steps

1. Run `/s T-2025-023` to start work
2. Create Gemini client module
3. Create folder fetcher
4. Update scheduler
