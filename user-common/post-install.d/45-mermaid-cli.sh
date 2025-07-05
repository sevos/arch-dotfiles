#!/bin/bash
# Install mermaid-cli for diagram generation

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Installing mermaid-cli for diagram generation"

# Check if mermaid-cli is already installed
if command -v mmdc >/dev/null 2>&1; then
    success "mermaid-cli is already installed: $(mmdc --version)"
    exit 0
fi

# Source mise to ensure Node.js/npm are available
if command -v mise >/dev/null 2>&1; then
    substep "Activating mise environment"
    eval "$(mise activate bash)"
fi

# Check if npm is available
if ! command -v npm >/dev/null 2>&1; then
    error "npm not found. Please ensure Node.js and npm are installed first"
    exit 1
fi

processing "Installing @mermaid-js/mermaid-cli globally"

# Install mermaid-cli globally
if npm install -g @mermaid-js/mermaid-cli; then
    success "mermaid-cli installed successfully"
    
    # Verify installation
    if command -v mmdc >/dev/null 2>&1; then
        info "Installed version: $(mmdc --version)"
    else
        warn "mermaid-cli installed but mmdc command not found in PATH"
        info "You may need to restart your shell or update your PATH"
    fi
else
    error "Failed to install mermaid-cli"
    info "You may need to:"
    info "  1. Fix npm permissions: npm config set prefix ~/.local"
    info "  2. Run the installation manually: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

success "mermaid-cli setup completed"