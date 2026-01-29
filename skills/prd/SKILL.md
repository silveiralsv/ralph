# /prd - PRD Generation Skill

## Description
Generate a structured Product Requirements Document (PRD) for a feature through interactive clarification.

## Trigger Phrases
- "create a prd"
- "write prd for"
- "generate prd"
- "new prd"
- "/prd"

## Instructions

When the user asks you to create a PRD, follow this process:

### Step 1: Gather Context

Ask clarifying questions to understand the feature. Use lettered options (a, b, c, d) for multiple choice questions. Key areas to clarify:

1. **Feature Overview**
   - What is the feature/project name?
   - What problem does it solve?
   - Who is the target user?

2. **Scope**
   - What are the must-have requirements?
   - What is explicitly out of scope?
   - Are there any technical constraints?

3. **Technical Details**
   - What tech stack will be used?
   - Are there existing patterns to follow?
   - What integrations are needed?

4. **Success Criteria**
   - How will we know the feature is complete?
   - What metrics matter?
   - Are there performance requirements?

### Step 2: Generate PRD

Create a markdown PRD with this structure:

```markdown
# PRD: [Feature Name]

## Overview
[2-3 sentence summary of the feature]

## Problem Statement
[What problem this solves and why it matters]

## Target Users
[Who will use this feature]

## Goals
- [Goal 1]
- [Goal 2]

## Non-Goals / Out of Scope
- [What this feature will NOT do]

## User Stories

### US-001: [Story Title]
**As a** [user type]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

### US-002: [Story Title]
...

## Technical Considerations
- [Tech stack details]
- [Architecture notes]
- [Integration requirements]

## Dependencies
- [External dependencies]
- [Blocked by]

## Open Questions
- [Any unresolved questions]

## Timeline
- [Rough phases if known]
```

### Step 3: Save the PRD

Save the PRD to: `tasks/prd-[feature-name-kebab-case].md`

Create the `tasks/` directory if it doesn't exist.

### Step 4: Suggest Next Steps

After saving, suggest:
1. Review and refine the PRD
2. Use `/ralph` to convert it to `prd.json` for the Ralph Loop
3. Share with stakeholders for feedback

## Example Interaction

User: "create a prd for user authentication"
