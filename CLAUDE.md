# Ralph Loop Iteration

You are operating as part of the Ralph Loop - an autonomous AI agent system that completes PRD items one at a time.

## Your Task

1. **Read the PRD and Progress**
   - Read `prd.json` in this directory to understand the project and stories
   - Read `progress.txt` to see what has been completed

2. **Set Up Branch**
   - Check out or create the branch specified in `prd.json` field `branchName`
   - If the branch doesn't exist, create it from the current HEAD

3. **Pick the Next Story**
   - Find the user story with `passes: false` and the **lowest priority number** (1 = highest priority)
   - If multiple stories have the same priority, pick the first one in the array
   - **If NO stories have `passes: false`**, all work is done - skip to step 8 and output completion signal

4. **Implement the Story**
   - Implement the story according to its description and acceptance criteria
   - Follow existing code patterns and conventions in the codebase
   - Keep changes focused on this single story

5. **Run Quality Checks**
   - Run typecheck if TypeScript: `npm run typecheck` or `tsc --noEmit`
   - Run linter: `npm run lint` or equivalent
   - Run tests: `npm test` or equivalent. If there are many tests like unity and e2e, run both.
   - Fix any issues before proceeding

6. **Commit Changes**
   - Stage all changes
   - Commit with conventional commit format: `feat(scope): description`
   - Include the story ID in the commit message

7. **Update Progress**
   - Update `prd.json`: Set the story's `passes` field to `true`
   - Add any relevant notes to the story's `notes` field
   - Append to `progress.txt`:
     ```
     ## [STORY_ID] - [TIMESTAMP]
     Status: PASSED
     Summary: [Brief description of what was implemented]
     Commit: [commit hash]
     ```

8. **Check Completion**
   - Re-read `prd.json` and count how many stories still have `passes: false`
   - If ALL stories now have `passes: true` (zero with `passes: false`), output exactly on its own line: `<promise>COMPLETE</promise>`
   - Otherwise, just end your response (the loop will spawn another iteration)

## Important Rules

- **One story per iteration**: Only implement ONE story, then stop
- **Quality first**: Do not mark a story as passing if tests/lint/typecheck fail
- **Atomic commits**: Each story should be a single, focused commit
- **Update files**: Always update both `prd.json` and `progress.txt` after completing a story
- **No skipping**: If a story is blocked, add notes explaining why and move to the next one
- **Be autonomous**: Don't ask questions - make reasonable decisions based on context

## File Locations

- PRD: `./prd.json`
- Progress: `./progress.txt`
- This prompt: `./CLAUDE.md`

Begin by reading the PRD and progress files.
