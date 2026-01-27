# Ralph Loop

An autonomous AI agent system that runs Claude Code repeatedly to complete PRD items.

## Overview

Ralph Loop takes a structured PRD (Product Requirements Document) in JSON format and autonomously implements each user story one at a time. It runs Claude Code in a loop, with each iteration:

1. Reading the current PRD and progress
2. Picking the highest priority incomplete story
3. Implementing the story
4. Running quality checks (typecheck, lint, tests)
5. Committing changes
6. Updating progress

## Quick Start

```bash
# 1. Navigate to your project
cd ~/www/edvisor/inventory-service

# 2. Create a PRD using the /prd skill
/prd

# 3. Convert it to prd.json using the /ralph skill
/ralph

# 4. Run the loop
ralph.sh
```

## Usage

```bash
# Run from your project directory
cd ~/www/edvisor/my-project
ralph.sh                    # Default 10 iterations
ralph.sh 5                  # 5 iterations
ralph.sh --max 20           # 20 iterations
ralph.sh --help             # Show help
```

## Multi-Project Support

Ralph is designed for multiple projects. Each project has its own isolated context:

```
~/www/edvisor/inventory-service/
├── prd.json              # Project-specific PRD
├── progress.txt          # Project-specific progress
└── .ralph-archive/       # Project-specific archives

~/www/edvisor/billing-service/
├── prd.json              # Completely separate
├── progress.txt          # No cross-contamination
└── .ralph-archive/       # Isolated archives
```

**No context leakage**: Each Claude invocation is stateless. The only "memory" is what's in that project's `prd.json` and `progress.txt`.

## Files

**Shared (in ~/www/scripts/ralph/):**
| File | Description |
|------|-------------|
| `ralph.sh` | Main bash loop script |
| `CLAUDE.md` | Prompt template for each iteration |
| `prd.json.example` | Example PRD structure |

**Per-project (in your project directory):**
| File | Description |
|------|-------------|
| `prd.json` | Your PRD (required) |
| `progress.txt` | Progress log (auto-created) |
| `.ralph-archive/` | Previous runs (auto-created)

## PRD Format

```json
{
  "project": "MyFeature",
  "branchName": "ralph/my-feature",
  "description": "Feature description",
  "targetDirectory": "/path/to/project",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a user, I want...",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Story Fields

| Field | Description |
|-------|-------------|
| `id` | Unique identifier (e.g., `US-001`) |
| `title` | Short descriptive title |
| `description` | Full story description |
| `acceptanceCriteria` | List of acceptance criteria |
| `priority` | Lower number = higher priority (1 is highest) |
| `passes` | `false` until implemented, then `true` |
| `notes` | Implementation notes or blockers |

## Skills

### /prd

Generates a structured PRD markdown document through interactive clarification.

```
/prd user authentication with JWT
```

Saves to: `tasks/prd-[feature-name].md`

### /ralph

Converts a PRD markdown document to `prd.json` format.

```
/ralph
```

- Parses user stories from the PRD
- Orders by dependencies (schema → backend → UI)
- Ensures stories are atomic (one per iteration)
- Archives previous runs if branch changed

## How It Works

1. **Loop Start**: `ralph.sh` reads `prd.json` and initializes `progress.txt`
2. **Each Iteration**: Claude reads the PRD, picks the next story, implements it
3. **Quality Checks**: Typecheck, lint, and tests must pass
4. **Progress Update**: Story marked `passes: true`, progress logged
5. **Completion**: Loop exits when all stories pass or max iterations reached

## Completion Signal

When all stories are complete, Claude outputs:

```
<promise>COMPLETE</promise>
```

This signals the loop to exit successfully.

## Branch Management

- Branch name comes from `prd.json` field `branchName`
- On first run, creates/checks out the branch
- If branch changes between runs, previous `progress.txt` is archived

## Tips

- **Small stories**: Keep stories atomic - one focused change per story
- **Priority order**: Use priority to control implementation order
- **Dependencies**: Lower priority numbers for foundational work (schema, models)
- **Notes field**: Claude adds implementation notes here
- **Review progress**: Check `progress.txt` for detailed logs
