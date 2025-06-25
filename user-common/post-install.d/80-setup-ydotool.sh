#!/bin/bash

# Setup ydotool service for input automation
# This script enables the ydotool user service and configures socket access

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Setting up ydotool service"

# Enable and start ydotool user service
if systemctl --user enable ydotool.service; then
    success "ydotool.service enabled"
else
    error "Failed to enable ydotool.service"
    exit 1
fi

if systemctl --user start ydotool.service; then
    success "ydotool.service started"
else
    error "Failed to start ydotool.service"
    exit 1
fi

# Configure socket path for user access
SOCKET_DIR="/run/user/$(id -u)"
SOCKET_PATH="$SOCKET_DIR/.ydotool_socket"

# Create socket directory if it doesn't exist
mkdir -p "$SOCKET_DIR"

# Set YDOTOOL_SOCKET environment variable in user profile
PROFILE_FILE="$HOME/.profile"
if ! grep -q "YDOTOOL_SOCKET" "$PROFILE_FILE" 2>/dev/null; then
    echo "" >> "$PROFILE_FILE"
    echo "# ydotool socket configuration" >> "$PROFILE_FILE"
    echo "export YDOTOOL_SOCKET=\"$SOCKET_PATH\"" >> "$PROFILE_FILE"
    success "Added YDOTOOL_SOCKET to $PROFILE_FILE"
else
    info "YDOTOOL_SOCKET already configured in $PROFILE_FILE"
fi

success "ydotool setup completed"
info "Note: You may need to restart your session for socket configuration to take effect"