# User Test with Persona

Run persona-driven user testing on a feature or flow using the user-tester agent.

## Arguments

`/test [persona] [flow or page]`

- **persona** (optional): One of your defined personas (e.g., "power-user", "new-user", "team-lead", "budget-conscious")
- **flow** (optional): What to test (e.g., "landing page", "signup flow", "dashboard")

If no arguments provided, will ask which persona and flow to test.

## Prerequisites

1. **User-tester agent must exist**: Copy from `.claude/agents/_packs/saas/user-tester.md` to `.claude/agents/`
2. **Chrome DevTools MCP must be connected**: See CLAUDE.md for setup instructions
3. **Customize personas**: Edit the user-tester agent with your actual customer archetypes

## Steps

1. **Parse arguments** from `<command-args>`:
   - Extract persona name
   - Extract flow/page to test

2. **Read the user-tester agent**:

   ```
   Read .claude/agents/user-tester.md
   ```

3. **Confirm testing context**:
   - Persona: [selected persona]
   - Flow: [what we're testing]
   - Goal: [persona's job-to-be-done]

4. **Use Chrome DevTools MCP to test**:
   - `mcp__chrome-devtools__list_pages` - See what's open
   - `mcp__chrome-devtools__navigate_page` - Go to the flow
   - `mcp__chrome-devtools__take_snapshot` - See current state
   - `mcp__chrome-devtools__take_screenshot` - Capture visuals
   - Interact as the persona would (click, fill, navigate)

5. **Narrate the experience** as the persona:
   - Think aloud ("Hmm, I'm not sure what this means...")
   - Note friction points
   - Note delight moments
   - Evaluate against persona's goals

6. **Provide structured feedback**:
   - Summary (1 paragraph)
   - What Worked (bullet points)
   - Friction Points (with severity: minor/moderate/major)
   - Recommendations (prioritized)
   - Would I Pay? (honest assessment)

## Examples

```
/test new-user landing
→ Test landing page as New User persona

/test power-user
→ Test current page as Power User persona

/test budget-conscious pricing
→ Test pricing page as Budget-Conscious persona

/test
→ Ask which persona and flow to test
```

## Important

- **Stay in character** throughout the test
- **Be honest** - real customers have real frustrations
- **Be specific** - "This confused me" → "I didn't understand what 'X' meant"
- **Balance feedback** - note what works too, not just problems
- **Think conversion** - would this persona actually pay?

ARGUMENTS: $ARGUMENTS
