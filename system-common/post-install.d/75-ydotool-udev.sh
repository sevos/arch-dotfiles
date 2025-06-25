#!/bin/bash

# Setup udev rules for ydotool uinput device access
# This script reloads udev rules to apply ydotool permissions

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Setting up ydotool udev rules"

# Reload udev rules to apply new permissions
if udevadm control --reload-rules; then
    success "udev rules reloaded"
else
    error "Failed to reload udev rules"
    exit 1
fi

# Trigger udev to apply rules to existing devices
if udevadm trigger --subsystem-match=misc --attr-match=name=uinput; then
    success "udev rules applied to uinput device"
else
    warn "Failed to trigger udev for uinput device (device may not exist yet)"
fi

success "ydotool udev setup completed"
info "The uinput device will have proper permissions after next boot or manual trigger"