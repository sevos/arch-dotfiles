#!/bin/bash
# Install development tools via mise (idempotent)

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Installing development tools via mise"

# Ensure mise environment is loaded
eval "$(mise activate bash)"

# Install Python 3.13
substep "Installing Python 3.13"
if mise list python | grep -q "python.*3\.13\."; then
    info "Python 3.13 is already installed"
else
    mise install python@3.13
    success "Python 3.13 installed"
fi

# Install Node 24
substep "Installing Node 24"
if mise list node | grep -q "node.*24\."; then
    info "Node 24 is already installed"
else
    mise install node@24
    success "Node 24 installed"
fi

# Install Ruby 3
substep "Installing Ruby 3"
if mise list ruby | grep -q "ruby.*3\."; then
    info "Ruby 3 is already installed"
else
    mise install ruby@3
    success "Ruby 3 installed"
fi

# Set all tools as global defaults
substep "Setting tools as global defaults"
mise use --global python@3.13
mise use --global node@24
mise use --global ruby@3

substep "Verifying tool installations"
mise list --current

success "Mise tools installation completed"