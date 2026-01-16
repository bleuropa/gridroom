---
tags:
  - meta
  - documentation
  - guidelines
related:
  - "[[Meta]]"
  - "[[Documentation Strategy]]"
---

# Vault Writing Guidelines

This page defines the definitive standards for writing effective vault documentation.

## Core Principles

### Atomic Pages
- **One topic per page** - Each page covers a single, specific concept
- **Concise and focused** - No rambling or excessive detail
- **Complete within scope** - Cover the topic thoroughly but don't exceed boundaries

### Rich Inner-Linking
- **Link to related concepts** using `[[Page Title]]` syntax
- **Avoid redundancy** - Don't repeat information covered elsewhere, link to it
- **Build knowledge graph** - Create natural discovery paths between related topics

### Focus on "Why" and "What"
- **Explain purpose and rationale** - Why does this exist? What problem does it solve?
- **Describe behavior and outcomes** - What does this do? How does it work from a user perspective?
- **Avoid implementation details** - The code shows "how", documentation explains context

## Content Balance

### Include Both Product and Technical Context
- **UX reasoning** - Why the user experience works this way
- **Business requirements** - What the feature needs to accomplish
- **Technical architecture** - How the system is structured to support requirements
- **Integration points** - How this connects to other parts of the system

### Product/UX Documentation
When documenting user-facing features:
- **User goals and workflows** - What users are trying to accomplish
- **Interface design decisions** - Why certain UX patterns were chosen
- **Behavior expectations** - How the feature should work from user perspective

### Technical Documentation  
When documenting code architecture:
- **System design rationale** - Why this architectural approach
- **Component relationships** - How pieces fit together
- **Data flow patterns** - How information moves through the system
- **Integration strategies** - How external services are incorporated

## What to Exclude

### Generic Sections
Remove these unless uniquely relevant to your specific topic:
- **Performance considerations** (unless performance is uniquely important)
- **Error handling** (unless error handling is uniquely complex)
- **Security implications** (unless security requirements are unique)
- **Testing approaches** (unless testing needs special consideration)

### Temporal References
- **Avoid "recently", "will be", "next steps"** - Focus on current state
- **Don't discuss future plans** - Document what exists now
- **Remove historical context** - Explain current rationale, not evolution
- See [[Avoiding Temporal Language in Documentation]] for comprehensive guidelines

### Implementation Noise
- **No code samples** unless absolutely necessary for understanding
- **No step-by-step procedures** - Link to relevant code or other docs
- **No configuration details** - Keep at architectural level

## Page Structure

### Recommended Format
```markdown
# Page Title

Brief description of what this covers.

## Core Concept

Main explanation of what this is and why it exists.

## Key Architecture/Behavior Points

Specific unique aspects that matter for understanding.

## Integration/Related Systems  

How this connects to other parts of the system.

## Related Documentation

- [[Related Page]] - Brief description of relevance
```

### Headings
- **Use descriptive headings** - "Expert Setup System" not "Setup"  
- **Avoid generic headings** - "Core Functionality" not "Overview"
- **Match content scope** - Heading should precisely describe what's covered

## Writing Style

### Current State Focus
- **Describe what is** - "The dashboard provides..." not "The dashboard will provide..."
- **Present tense** - "Users access..." not "Users will access..."
- **Definitive statements** - Avoid hedging language unless genuinely uncertain

### Precision
- **Be specific** - "Setup completion uses weighted scoring" not "Setup completion is sophisticated"
- **Use precise terms** - Technical accuracy matters
- **Avoid marketing language** - Focus on facts and functionality

### Conciseness
- **Remove filler words** - "in order to" → "to"
- **Eliminate redundancy** - Don't repeat points
- **Use active voice** - "The system validates" not "Validation is performed"

## When to Break the Rules

These guidelines optimize for clarity and maintainability, but exceptions are appropriate when they serve understanding:

### Temporal Language Exceptions
- **Migration guides** where transitions are the core topic
- **Historical context** when essential for understanding current design decisions
- **Explicit comparison** between approaches when alternatives are genuinely relevant

### Implementation Detail Exceptions  
- **Critical architecture patterns** where code examples clarify complex interactions
- **Integration points** where specific implementation affects other teams
- **Edge cases** where behavior isn't obvious from high-level description

### Generic Section Exceptions
- **Security** when approach is novel or has significant implications
- **Performance** when characteristics are unusual or critical to understanding
- **Error handling** when patterns are unique or affect user experience

**Rule of thumb**: Break guidelines when following them would reduce clarity or understanding. Document why the exception serves the reader better than following the standard approach.

## Quality Checklist

Before publishing, verify:

- [ ] **Single topic focus** - Page covers one specific concept
- [ ] **No generic sections** - Removed performance/error/security unless uniquely relevant
- [ ] **Rich linking** - Connected to related concepts
- [ ] **Current state** - No temporal language or future plans  
- [ ] **Balanced context** - Includes both product and technical perspective
- [ ] **No redundancy** - Information not duplicated elsewhere
- [ ] **Actionable links** - Related documentation is genuinely relevant
- [ ] **Exception justification** - Any rule breaks serve clarity over convention

## Anti-Patterns

### Avoid These Common Mistakes
- **Generic performance sections** - "This loads data efficiently"
- **Boilerplate error handling** - "Errors are handled gracefully"  
- **Future-focused content** - "We plan to enhance this"
- **Code implementation details** - Step-by-step procedures
- **Marketing language** - "Powerful", "robust", "seamless"
- **Historical narrative** - "We originally built this because..."

## Examples

### Good Opening
> "The dashboard implements a dual-role architecture that adapts to users who may be learners, experts, or both simultaneously."

### Poor Opening  
> "The dashboard is a powerful and flexible interface that will provide users with comprehensive functionality for managing their experience on the platform."

### Good Section
> "Setup status integrates with external services for accuracy:
> - Stripe API: Verifies actual payout readiness, not just account existence
> - Acuity API: Confirms calendar has real availability slots"

### Poor Section
> "Performance Considerations: The dashboard loads data efficiently using optimized queries and caching strategies to ensure fast response times."

## Related Documentation

- [[Documentation Strategy]] - Overall documentation approach
- [[Avoiding Temporal Language in Documentation]] - Detailed guide on writing timeless documentation
- [[Meta]] - Hub for all meta-documentation