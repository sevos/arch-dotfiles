#!/bin/bash
# Set up shell tools (idempotent)

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Setting up shell tools"

# Initialize zoxide database if it doesn't exist
if [ ! -f "$HOME/.local/share/zoxide/db.zo" ]; then
    substep "Initializing zoxide database"
    mkdir -p "$HOME/.local/share/zoxide"
    # Add current directory to zoxide
    zoxide add "$PWD" 2>/dev/null || true
    success "Zoxide database initialized"
else
    info "Zoxide database already exists"
fi

# Ensure proper permissions for shell files
substep "Setting proper permissions for shell configuration files"
chmod 644 "$HOME/.bashrc" 2>/dev/null || true
chmod 644 "$HOME/.bash_aliases" 2>/dev/null || true
chmod 644 "$HOME/.profile" 2>/dev/null || true

success "Shell tools setup completed"