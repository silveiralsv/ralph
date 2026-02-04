#!/bin/bash

# Ralph Loop - Autonomous AI Agent System
# Runs Claude Code repeatedly to complete PRD items

set -euo pipefail

# Resolve the actual script location, following symlinks
# This works on both macOS (which lacks readlink -f) and Linux
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local dir

    # Resolve symlinks until we get to the actual file
    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        # If source is a relative symlink, resolve it relative to the symlink's directory
        [[ "$source" != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(resolve_script_path)"
PROJECT_DIR="$(pwd)"

# Project-specific files (in current working directory)
PRD_FILE="$PROJECT_DIR/prd.json"
PROGRESS_FILE="$PROJECT_DIR/progress.txt"
ARCHIVE_DIR="$PROJECT_DIR/.ralph-archive"

# Shared template (in script directory)
CLAUDE_MD="$SCRIPT_DIR/CLAUDE.md"

# Default max iterations
MAX_ITERATIONS=10

# Debug mode (disabled by default)
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: ralph [OPTIONS] [MAX_ITERATIONS]"
    echo ""
    echo "Run Claude Code in a loop to complete PRD items autonomously."
    echo "Run this from any project directory that contains a prd.json file."
    echo ""
    echo "Options:"
    echo "  --max N, -m N    Set maximum iterations (default: 10)"
    echo "  --verbose, -v    Enable debug logging"
    echo "  --help, -h       Show this help message"
    echo ""
    echo "Arguments:"
    echo "  MAX_ITERATIONS   Positional arg for max iterations (alternative to --max)"
    echo ""
    echo "Project Files (in current directory):"
    echo "  prd.json         PRD with user stories (required)"
    echo "  progress.txt     Progress log (auto-created)"
    echo "  .ralph-archive/  Archived runs (auto-created)"
    echo ""
    echo "Examples:"
    echo "  cd ~/my-project && ralph         # Run from any project directory"
    echo "  ralph 5                          # Run with 5 iterations max"
    echo "  ralph --max 20                   # Run with 20 iterations max"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Global variables for Claude output capture
CLAUDE_OUTPUT=""
CLAUDE_EXIT_CODE=0

# Run Claude with streaming output (verbose mode)
# Streams output to terminal in real-time while capturing to temp file
run_claude_streaming() {
    local input_file="$1"
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/ralph-claude.XXXXXX")

    # Cleanup function for temp file
    cleanup_tmpfile() {
        rm -f "$tmpfile"
    }
    trap cleanup_tmpfile EXIT INT TERM

    log_debug "Claude output will stream in real-time..."
    log_debug "Temp file: $tmpfile"

    set +e
    claude --dangerously-skip-permissions --print --no-session-persistence \
        < "$input_file" 2>&1 | tee "$tmpfile"
    local pipe_status=("${PIPESTATUS[@]}")
    set -e

    CLAUDE_EXIT_CODE="${pipe_status[0]}"
    CLAUDE_OUTPUT=$(<"$tmpfile")

    cleanup_tmpfile
    trap - EXIT INT TERM
}

# Show progress spinner while Claude runs (non-verbose mode)
# Displays elapsed time to indicate progress
run_claude_with_progress() {
    local input_file="$1"
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/ralph-claude.XXXXXX")
    local pid
    local start_time
    start_time=$(date +%s)

    # Cleanup function
    cleanup_progress() {
        # Kill background process if running
        if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
        rm -f "$tmpfile"
        # Clear spinner line
        printf "\r\033[K" >&2
    }
    trap cleanup_progress EXIT INT TERM

    # Start Claude in background, capturing output to temp file
    claude --dangerously-skip-permissions --print --no-session-persistence \
        < "$input_file" > "$tmpfile" 2>&1 &
    pid=$!

    # Show spinner while waiting
    local spinner_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local spinner_idx=0

    while kill -0 "$pid" 2>/dev/null; do
        local elapsed=$(($(date +%s) - start_time))
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        local time_str
        if [[ $mins -gt 0 ]]; then
            time_str="${mins}m ${secs}s"
        else
            time_str="${secs}s"
        fi

        printf "\r${BLUE}[RUNNING]${NC} Claude working... %s [%s] " \
            "${spinner_chars:spinner_idx:1}" "$time_str" >&2
        spinner_idx=$(( (spinner_idx + 1) % ${#spinner_chars} ))
        sleep 0.1
    done

    # Get exit code
    wait "$pid"
    CLAUDE_EXIT_CODE=$?

    # Clear spinner line
    printf "\r\033[K" >&2

    # Read captured output
    CLAUDE_OUTPUT=$(<"$tmpfile")

    local elapsed=$(($(date +%s) - start_time))
    log_info "Claude finished in ${elapsed}s (exit code: $CLAUDE_EXIT_CODE)"

    rm -f "$tmpfile"
    trap - EXIT INT TERM
}

# Dispatcher: choose streaming vs progress based on verbose mode
run_claude_iteration() {
    local input_file="$1"
    local stories_remaining="$2"

    log_debug "=== Claude Iteration Start ==="
    log_debug "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    log_debug "Stories remaining: $stories_remaining"
    log_debug "Input file: $input_file"

    if [[ "$VERBOSE" == "true" ]]; then
        run_claude_streaming "$input_file"
    else
        run_claude_with_progress "$input_file"
    fi

    log_debug "=== Claude Iteration End ==="
    log_debug "Exit code: $CLAUDE_EXIT_CODE"
    log_debug "Output length: ${#CLAUDE_OUTPUT} characters"

    if [[ -z "$CLAUDE_OUTPUT" ]]; then
        log_warning "Claude output is EMPTY!"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --max|-m)
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            # Positional argument for max iterations
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                MAX_ITERATIONS="$1"
            else
                log_error "Unknown option: $1"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate max iterations is a number
if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
    log_error "Max iterations must be a number"
    exit 1
fi

# Check required files exist
if [[ ! -f "$PRD_FILE" ]]; then
    log_error "prd.json not found in current directory: $PROJECT_DIR"
    log_info "Run this from your project directory, or use /prd and /ralph skills to generate prd.json"
    exit 1
fi

if [[ ! -f "$CLAUDE_MD" ]]; then
    log_error "CLAUDE.md not found at $CLAUDE_MD"
    exit 1
fi

# Get branch name from PRD
get_prd_branch() {
    jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo ""
}

# Archive previous run if branch changed
archive_if_branch_changed() {
    local prd_branch
    prd_branch=$(get_prd_branch)

    if [[ -z "$prd_branch" ]]; then
        log_warning "No branchName found in prd.json"
        return
    fi

    # Check if progress file exists and has content
    if [[ -f "$PROGRESS_FILE" && -s "$PROGRESS_FILE" ]]; then
        # Extract branch from progress file (first line after "Branch:")
        local progress_branch
        progress_branch=$(grep -m1 "^Branch:" "$PROGRESS_FILE" 2>/dev/null | sed 's/Branch: *//' || echo "")

        if [[ -n "$progress_branch" && "$progress_branch" != "$prd_branch" ]]; then
            local timestamp
            timestamp=$(date +"%Y%m%d_%H%M%S")
            local archive_name="${progress_branch//\//_}_${timestamp}"

            log_info "Branch changed from '$progress_branch' to '$prd_branch'"
            log_info "Archiving previous run to .ralph-archive/$archive_name/"

            mkdir -p "$ARCHIVE_DIR/$archive_name"
            mv "$PROGRESS_FILE" "$ARCHIVE_DIR/$archive_name/"

            # Also archive the old prd.json if it exists in progress
            if [[ -f "$ARCHIVE_DIR/$archive_name/progress.txt" ]]; then
                cp "$PRD_FILE" "$ARCHIVE_DIR/$archive_name/prd.json.archived" 2>/dev/null || true
            fi
        fi
    fi
}

# Initialize progress file
init_progress() {
    local prd_branch
    prd_branch=$(get_prd_branch)
    local project_name
    project_name=$(jq -r '.project // "Unknown"' "$PRD_FILE")

    if [[ ! -f "$PROGRESS_FILE" ]]; then
        log_info "Initializing progress.txt"
        cat > "$PROGRESS_FILE" << EOF
# Ralph Loop Progress Log
Project: $project_name
Branch: $prd_branch
Started: $(date +"%Y-%m-%d %H:%M:%S")

---

EOF
    fi
}

# Count incomplete stories
count_incomplete() {
    jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null || echo "0"
}

# Check if all stories are complete
check_all_complete() {
    local incomplete
    incomplete=$(count_incomplete)
    [[ "$incomplete" == "0" ]]
}

# Main loop
main() {
    log_info "Starting Ralph Loop"
    log_info "Project: $PROJECT_DIR"
    log_info "Max iterations: $MAX_ITERATIONS"

    # Archive if branch changed
    archive_if_branch_changed

    # Initialize progress file
    init_progress

    # Check if already complete
    if check_all_complete; then
        log_success "All stories already complete!"
        exit 0
    fi

    local iteration=1

    while [[ $iteration -le $MAX_ITERATIONS ]]; do
        log_debug "Starting iteration $iteration, incomplete stories: $(count_incomplete)"

        # Check if already complete before running Claude
        log_debug "Pre-iteration completion check..."
        if check_all_complete; then
            log_debug "check_all_complete() returned TRUE - exiting loop"
            echo ""
            log_success "=========================================="
            log_success "All stories marked as passing!"
            log_success "=========================================="
            exit 0
        fi
        log_debug "check_all_complete() returned FALSE - continuing"

        echo ""
        log_info "=========================================="
        log_info "Iteration $iteration of $MAX_ITERATIONS"
        log_info "=========================================="
        echo ""

        # Run Claude with the prompt (streaming in verbose mode, progress spinner otherwise)
        local stories_remaining
        stories_remaining=$(count_incomplete)
        run_claude_iteration "$CLAUDE_MD" "$stories_remaining"

        # In non-verbose mode, display the captured output now
        if [[ "$VERBOSE" != "true" ]]; then
            echo "$CLAUDE_OUTPUT"
        fi

        # Check for completion signal
        if echo "$CLAUDE_OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
            log_debug "COMPLETE signal found in output - exiting"
            echo ""
            log_success "=========================================="
            log_success "All PRD items completed!"
            log_success "=========================================="
            exit 0
        else
            log_debug "No COMPLETE signal in output"
        fi

        # Check if all stories are now complete
        local remaining_count
        remaining_count=$(count_incomplete)
        log_debug "Post-Claude check: $remaining_count stories with passes=false"
        if check_all_complete; then
            log_debug "Post-check: ALL COMPLETE - exiting"
            echo ""
            log_success "=========================================="
            log_success "All stories marked as passing!"
            log_success "=========================================="
            exit 0
        fi
        log_debug "Post-check: NOT all complete, continuing loop"

        ((iteration++))
        log_debug "Incremented iteration to $iteration, looping back..."
    done

    echo ""
    log_warning "=========================================="
    log_warning "Max iterations ($MAX_ITERATIONS) reached"
    log_warning "Some stories may still be incomplete"
    log_warning "=========================================="

    # Show remaining stories
    local remaining
    remaining=$(jq -r '[.userStories[] | select(.passes == false) | .id] | join(", ")' "$PRD_FILE" 2>/dev/null || echo "unknown")
    log_info "Remaining stories: $remaining"

    exit 1
}

main
