#!/usr/bin/env bash

# Repair iedit package corruption in Doom Emacs
# Removes cached iedit repo and re-syncs Doom configuration

set -euo pipefail

# Color codes and icons
INFO="ℹ️"
SUCCESS="✅"
ERROR="❌"
WARN="⚠️"
LOADING="⏳"
PROC="🔧"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${INFO} $1"
}

success() {
    echo -e "${GREEN}${SUCCESS} $1${NC}"
}

error() {
    echo -e "${RED}${ERROR} $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}${WARN} $1${NC}"
}

loading() {
    echo -e "${LOADING} $1"
}

# Exit handler
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        error "Script failed with exit code $exit_code"
    fi
    return $exit_code
}

trap cleanup EXIT

# Main script
echo ""
info "Starting iedit package repair..."
echo ""

# Verify emacs.d exists
if [[ ! -d "$HOME/.emacs.d" ]]; then
    error "Emacs config directory not found: $HOME/.emacs.d"
    exit 1
fi

# Change to emacs directory
info "Navigating to $HOME/.emacs.d"
if ! cd "$HOME/.emacs.d" 2>/dev/null; then
    error "Failed to change to $HOME/.emacs.d"
    exit 1
fi

# Remove cached iedit repository
loading "Removing cached iedit repository..."
if [[ -d ".local/straight/repos/iedit" ]]; then
    if rm -rf ".local/straight/repos/iedit" 2>/dev/null; then
        success "Cleaned iedit cache"
    else
        error "Failed to remove iedit cache directory"
        exit 1
    fi
else
    warn "iedit cache not found (already cleaned?)"
fi

echo ""

# Run doom upgrade
loading "Running doom upgrade..."
if command -v doom &>/dev/null; then
    if doom upgrade; then
        success "Doom upgrade completed"
    else
        error "Doom upgrade failed"
        exit 1
    fi
else
    error "Doom command not found. Is Doom Emacs installed?"
    exit 1
fi

echo ""

# Run doom sync
loading "Running doom sync..."
if doom sync; then
    success "Doom sync completed"
else
    error "Doom sync failed"
    exit 1
fi

echo ""

# Restart Emacs service
echo "${PROC} Restarting Emacs service..."
loading "Killing existing Emacs processes..."
pkill -9 emacs || true # Don't fail if no process found
sleep 1

loading "Starting Emacs service..."
if systemctl --user start emacs 2>/dev/null; then
    sleep 2
    
    # Check status
    if systemctl --user is-active --quiet emacs; then
        success "Emacs service started successfully"
        systemctl --user status emacs
    else
        error "Emacs service failed to start"
        systemctl --user status emacs
        exit 1
    fi
else
    error "Failed to start Emacs service"
    exit 1
fi

echo ""
success "iedit repair complete!"
exit 0
