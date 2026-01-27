# PRD: Global Executable for Ralph

## Overview
Make the Ralph Loop script (`ralph.sh`) available as a global command (`ralph`) that can be executed from any directory without specifying the full path.

## Problem Statement
Currently, users must run `ralph.sh` by navigating to the script directory or using the full path. This adds friction to the workflow, especially when switching between multiple projects that use the Ralph Loop.

## Target Users
- Developers using the Ralph Loop autonomous AI agent system
- Anyone who wants to run `ralph` from any project directory

## Goals
- Enable running `ralph` from any terminal session
- Provide a simple one-command installation
- Support easy uninstallation
- Maintain automatic updates (symlink approach)

## Non-Goals / Out of Scope
- Package manager distribution (homebrew, apt, etc.)
- Windows support
- Auto-update mechanisms beyond symlink

## User Stories

### US-001: Install Ralph Globally
**As a** developer
**I want** to run a single install command
**So that** I can use `ralph` from anywhere on my system

**Acceptance Criteria:**
- [ ] Running `./install.sh` creates a symlink at `/usr/local/bin/ralph`
- [ ] The symlink points to the actual `ralph.sh` script
- [ ] Installation prompts for sudo if needed
- [ ] Installation verifies success by checking if `ralph` is accessible

### US-002: Run Ralph from Any Directory
**As a** developer
**I want** to type `ralph` in any project directory
**So that** I can quickly start the Ralph Loop without remembering paths

**Acceptance Criteria:**
- [ ] `ralph` command works from any directory
- [ ] All existing flags work (`--help`, `--max`, `-m`, positional args)
- [ ] Script correctly resolves its own directory for CLAUDE.md
- [ ] Script correctly uses current working directory for project files (prd.json, progress.txt)

### US-003: Uninstall Ralph
**As a** developer
**I want** to easily remove the global `ralph` command
**So that** I can cleanly uninstall if needed

**Acceptance Criteria:**
- [ ] Running `./install.sh --uninstall` or `./uninstall.sh` removes the symlink
- [ ] Uninstall confirms the symlink was removed
- [ ] Uninstall handles case where symlink doesn't exist gracefully

### US-004: Update Help Text
**As a** developer
**I want** the help text to reflect the new `ralph` command name
**So that** documentation is accurate after installation

**Acceptance Criteria:**
- [ ] Help text shows `ralph` instead of `ralph.sh` in usage examples
- [ ] Examples show running `ralph` from project directories

## Technical Considerations
- Use symlink to `/usr/local/bin/ralph` for automatic updates
- The script already uses `SCRIPT_DIR` to resolve its location, which works with symlinks via `readlink`
- Need to update `SCRIPT_DIR` resolution to follow symlinks: `SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"`
- macOS `readlink` doesn't support `-f`, need to use alternative approach or check for `greadlink`
- Installation should be idempotent (safe to run multiple times)

## Dependencies
- `/usr/local/bin` must exist and be in PATH (standard on macOS/Linux)
- User needs write access to `/usr/local/bin` (may require sudo)

## Open Questions
- None at this time

## Timeline
- Single implementation phase
- Estimated: 4 user stories
