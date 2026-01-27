#!/bin/bash

# Ralph Install Script
# Creates a symlink at /usr/local/bin/ralph for global access

set -euo pipefail

# Resolve the actual script location, following symlinks
resolve_script_path() {
    local source="${BASH_SOURCE[0]}"
    local dir

    while [[ -L "$source" ]]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done

    cd -P "$(dirname "$source")" && pwd
}

SCRIPT_DIR="$(resolve_script_path)"
RALPH_SCRIPT="$SCRIPT_DIR/ralph.sh"
INSTALL_PATH="/usr/local/bin/ralph"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_usage() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Install or uninstall the ralph command globally."
    echo ""
    echo "Options:"
    echo "  --uninstall    Remove the ralph symlink from $INSTALL_PATH"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Installation:"
    echo "  Creates a symlink at $INSTALL_PATH pointing to ralph.sh"
    echo "  May require sudo for write access to /usr/local/bin"
}

# Check if we need sudo for the target directory
needs_sudo() {
    local target_dir
    target_dir="$(dirname "$INSTALL_PATH")"

    # Check if we can write to the directory
    if [[ -w "$target_dir" ]]; then
        return 1  # No sudo needed
    else
        return 0  # Sudo needed
    fi
}

# Run a command with sudo if needed
run_with_sudo_if_needed() {
    if needs_sudo; then
        log_info "Requesting sudo access..."
        sudo "$@"
    else
        "$@"
    fi
}

install_ralph() {
    log_info "Installing ralph..."

    # Verify ralph.sh exists
    if [[ ! -f "$RALPH_SCRIPT" ]]; then
        log_error "ralph.sh not found at $RALPH_SCRIPT"
        exit 1
    fi

    # Ensure target directory exists
    local target_dir
    target_dir="$(dirname "$INSTALL_PATH")"
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating directory $target_dir"
        run_with_sudo_if_needed mkdir -p "$target_dir"
    fi

    # Check if symlink already exists
    if [[ -L "$INSTALL_PATH" ]]; then
        local current_target
        current_target="$(readlink "$INSTALL_PATH")"

        if [[ "$current_target" == "$RALPH_SCRIPT" ]]; then
            log_success "ralph is already installed and pointing to the correct location"
            return 0
        else
            log_warning "Existing symlink points to: $current_target"
            log_info "Updating symlink to point to: $RALPH_SCRIPT"
            run_with_sudo_if_needed rm "$INSTALL_PATH"
        fi
    elif [[ -e "$INSTALL_PATH" ]]; then
        log_error "$INSTALL_PATH already exists and is not a symlink"
        log_error "Please remove it manually before installing"
        exit 1
    fi

    # Create symlink
    log_info "Creating symlink: $INSTALL_PATH -> $RALPH_SCRIPT"
    run_with_sudo_if_needed ln -s "$RALPH_SCRIPT" "$INSTALL_PATH"

    # Verify installation
    if command -v ralph &> /dev/null; then
        log_success "Installation complete!"
        log_info "You can now run 'ralph' from any directory"
        log_info "Test it with: ralph --help"
    else
        log_warning "Symlink created, but 'ralph' not found in PATH"
        log_info "You may need to add $target_dir to your PATH"
        log_info "Or restart your terminal session"
    fi
}

uninstall_ralph() {
    log_info "Uninstalling ralph..."

    if [[ ! -e "$INSTALL_PATH" && ! -L "$INSTALL_PATH" ]]; then
        log_warning "ralph is not installed at $INSTALL_PATH"
        return 0
    fi

    if [[ -L "$INSTALL_PATH" ]]; then
        log_info "Removing symlink: $INSTALL_PATH"
        run_with_sudo_if_needed rm "$INSTALL_PATH"
        log_success "Uninstallation complete!"
    else
        log_error "$INSTALL_PATH exists but is not a symlink"
        log_error "Please remove it manually if you want to uninstall"
        exit 1
    fi
}

# Parse arguments
UNINSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main
if [[ "$UNINSTALL" == true ]]; then
    uninstall_ralph
else
    install_ralph
fi
