#!/bin/bash
# Configure emoji fonts and fontconfig for proper emoji display

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring emoji fonts..."

# Enable the font-config rule that promotes color emoji
if [[ -f /usr/share/fontconfig/conf.avail/66-noto-color-emoji.conf ]]; then
    if [[ ! -e /etc/fonts/conf.d/66-noto-color-emoji.conf ]]; then
        substep "Creating symlink for Noto Color Emoji configuration"
        ln -sf /usr/share/fontconfig/conf.avail/66-noto-color-emoji.conf /etc/fonts/conf.d/66-noto-color-emoji.conf
        success "Enabled Noto Color Emoji font configuration"
    else
        info "Noto Color Emoji configuration already enabled"
    fi
else
    warn "Noto Color Emoji configuration not found - ensure noto-fonts-emoji package is installed"
fi

# Remove the bitmap-blocking rule that breaks emoji on fontconfig ≥ 2.15
if [[ -f /etc/fonts/conf.d/70-no-bitmaps.conf ]]; then
    substep "Removing bitmap-blocking rule that breaks emoji"
    rm /etc/fonts/conf.d/70-no-bitmaps.conf
    success "Removed bitmap-blocking rule"
else
    info "Bitmap-blocking rule not present (already removed or not installed)"
fi

# Update font cache
substep "Updating font cache"
fc-cache -f >/dev/null 2>&1
success "Font cache updated"

success "Emoji fonts configuration complete"