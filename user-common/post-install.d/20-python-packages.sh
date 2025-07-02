#!/bin/bash
# Install Python packages using mise Python

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Installing Python packages with mise Python..."

# Install pikepdf using mise's Python pip
processing "Installing pikepdf..."
mise exec python -- pip install --user pikepdf
success "pikepdf installed successfully"