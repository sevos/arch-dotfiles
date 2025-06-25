#!/bin/bash
# Configure Wayland desktop portals for screen recording and other desktop integration

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring Wayland desktop portals..."

# Enable xdg-desktop-portal-wlr for automatic startup
substep "Enabling xdg-desktop-portal-wlr service for auto-start..."
if systemctl --user enable xdg-desktop-portal-wlr 2>/dev/null; then
    success "xdg-desktop-portal-wlr enabled for auto-start"
else
    warn "Failed to enable xdg-desktop-portal-wlr (may already be enabled)"
fi

# Start xdg-desktop-portal-wlr for screen recording support in Wayland
substep "Starting xdg-desktop-portal-wlr service..."
if systemctl --user start xdg-desktop-portal-wlr 2>/dev/null; then
    success "xdg-desktop-portal-wlr started successfully"
else
    warn "xdg-desktop-portal-wlr may already be running"
fi

success "Wayland portal configuration completed"