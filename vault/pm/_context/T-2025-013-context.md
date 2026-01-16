# Context: T-2025-013 Share Nodes via URL

**Task**: [[T-2025-013-share-nodes-via-url]]
**Created**: 2026-01-16
**Status**: In Progress

## Overview

Enable sharing node URLs so users can invite others to join conversations. Critical for viral growth.

## Key Decisions

- URL format: `/node/:id` (using existing ID, simple and already works)
- Share button: Copy to clipboard with toast confirmation
- OG tags: Dynamic based on node title/description

## Implementation Notes

- Nodes already accessible at `/node/:id`
- Just need to add share button UI and OG meta tags
- New visitors get session created automatically (existing flow)

## Next Steps

1. Add share button to node room UI
2. Copy-to-clipboard functionality
3. Add OG meta tags for social previews
