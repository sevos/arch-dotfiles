#!/bin/bash
# Configure Docker daemon and user permissions

set -euo pipefail

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring Docker daemon and user permissions"

# Enable docker service
sudo systemctl enable docker.service

# Try to start docker service with timeout
substep "Starting Docker service"
if timeout 30 sudo systemctl start docker.service; then
    success "Docker service started successfully"
else
    warn "Docker service start timed out or failed"
    info "Service will be enabled and should start on next boot"
    # Don't exit - continue with user group setup
fi

# Check if service is running (non-blocking)
if systemctl is-active --quiet docker.service; then
    success "Docker service is running"
else
    warn "Docker service not currently running (will start on boot)"
fi

# Add user to docker group if SUDO_USER is set
if [ -n "${SUDO_USER:-}" ]; then
    substep "Adding user $SUDO_USER to docker group"
    sudo usermod -aG docker "$SUDO_USER"
    success "User $SUDO_USER added to docker group"
    info "Note: User needs to log out and back in for group membership to take effect"
else
    warn "SUDO_USER not set, skipping user group addition"
fi

# Verify docker group exists
if getent group docker > /dev/null 2>&1; then
    success "Docker group exists"
else
    error "Docker group not found"
    exit 1
fi