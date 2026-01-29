# /ralph - PRD to JSON Conversion Skill

## Description

Convert a PRD markdown document into the `prd.json` format required by the Ralph Loop autonomous agent system.

## Trigger Phrases

- "convert this prd"
- "create prd.json"
- "convert prd to json"
- "ralph json"
- "/ralph"

## Instructions

When the user asks you to convert a PRD to JSON format, follow this process:

### Step 1: Locate the PRD

1. Ask the ticket number that the user is working on (it will be AP-XXXX, TKT-XXXX something like that)
2. If a file path is provided, read that file
3. Otherwise, look in `tasks/` for PRD files (`prd-*.md`)
4. If multiple PRDs exist, ask the user which one to convert

### Step 2: Parse User Stories

Extract all user stories from the PRD. For each story:

1. **Assign an ID**: Use format `US-001`, `US-002`, etc.
2. **Extract title**: The story heading
3. **Extract description**: The "As a... I want... So that..." text
4. **Extract acceptance criteria**: The checkbox items
5. **Determine priority**: Based on dependencies and logical order

### Step 3: Order by Dependencies

Organize stories so that dependencies come first:

1. **Schema/Database changes** (priority 1-2)
2. **Backend/API work** (priority 3-5)
3. **Frontend/UI work** (priority 6-8)
4. **Integration/Polish** (priority 9-10)
   1

### Step 4: Ensure Atomic Stories

Each story should be completable in a single Ralph Loop iteration (roughly 1 focused task). If a story is too large:

- Split it into smaller stories
- Maintain the dependency order
- Update priorities accordingly

### Step 5: Generate prd.json

Create the JSON structure:

```json
{
  "project": "[ProjectName from PRD]",
  "ticketNumber": "[ticket number that we asked on step 1.1]",
  "branchName": "ralph/[ticket-number]_[feature-name-kebab-case]",
  "description": "[Overview from PRD]",
  "targetDirectory": "[Ask user or infer from context]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[Story title]",
      "description": "[Full story description]",
      "acceptanceCriteria": ["[Criterion 1]", "[Criterion 2]"],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Step 6: Handle Previous Runs

Check if `prd.json` already exists:

1. If branch names differ, archive the old run:
   - Move `progress.txt` to `.ralph-archive/[old-branch]_[timestamp]/`
   - Copy old `prd.json` to the archive as well
2. Then write the new `prd.json`

### Step 7: Save and Confirm

1. Save to `./prd.json` in the current project directory
2. Show a summary:
   - Number of stories
   - Branch name
   - Priority order
3. Suggest running: `ralph` to start the loop

## JSON Schema Reference

```json
{
  "project": "string - Project or feature name",
  "ticketNumber": "string - APP-1234",
  "branchName": "string - Git branch name (ralph/feature-name format)",
  "description": "string - Brief description of the feature",
  "targetDirectory": "string - Path to the project being modified",
  "userStories": [
    {
      "id": "string - Unique story ID (US-001 format)",
      "title": "string - Short story title",
      "description": "string - Full story description",
      "acceptanceCriteria": ["string array - List of acceptance criteria"],
      "priority": "number - Lower = higher priority (1 is highest)",
      "passes": "boolean - false until story is complete",
      "notes": "string - Implementation notes, blockers, etc."
    }
  ]
}
```

## Tips for Good Stories

- **Atomic**: Each story should be one focused change
- **Testable**: Acceptance criteria should be verifiable
- **Independent**: Minimize dependencies between stories when possible
- **Ordered**: Database/schema first, then backend, then frontend

## Example Output

```json
{
  "project": "UserAuthentication",
  "ticketNumber": "APP-1234",
  "branchName": "ralph/user-auth",
  "description": "Implement user authentication with JWT tokens",
  "targetDirectory": "/Users/lucas/www/myapp",
  "userStories": [
    {
      "id": "US-001",
      "title": "Create users table migration",
      "description": "Create database migration for users table with email, password_hash, and timestamps",
      "acceptanceCriteria": [
        "Migration file exists",
        "Up migration creates users table",
        "Down migration drops users table",
        "Unique index on email column"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "Implement user model",
      "description": "Create User model with validation and password hashing",
      "acceptanceCriteria": [
        "User model exists",
        "Email validation",
        "Password is hashed before save",
        "Unit tests pass"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    }
  ]
}
```
