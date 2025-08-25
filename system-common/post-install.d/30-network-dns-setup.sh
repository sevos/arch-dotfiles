#!/bin/bash
# Ensure proper DNS resolution setup with systemd-resolved

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring DNS resolution for systemd-resolved..."

# Remove static resolv.conf if it exists and isn't a symlink
if [[ -f /etc/resolv.conf && ! -L /etc/resolv.conf ]]; then
    processing "Removing static /etc/resolv.conf"
    rm -f /etc/resolv.conf
    success "Static resolv.conf removed"
fi

# Create symlink to systemd-resolved stub resolver if not present
if [[ ! -L /etc/resolv.conf ]]; then
    processing "Creating systemd-resolved symlink"
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    success "systemd-resolved symlink created"
else
    substep "resolv.conf symlink already exists"
fi

# Restart systemd-resolved to ensure clean state
processing "Restarting systemd-resolved"
systemctl restart systemd-resolved

# Wait for systemd-resolved to be ready
sleep 2

# Flush DNS caches
processing "Flushing DNS caches"
resolvectl flush-caches

success "DNS resolution configured with systemd-resolved"
info "DNS resolution now managed by systemd-resolved with fallback servers"