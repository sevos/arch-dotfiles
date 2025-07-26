#!/bin/bash
# Enable and start Ollama service for local LLM serving

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring Ollama service"

# Enable Ollama service
if systemctl is-enabled ollama.service >/dev/null 2>&1; then
    substep "Ollama service is already enabled"
else
    processing "Enabling Ollama service"
    systemctl enable ollama.service
    success "Ollama service enabled"
fi

# Start Ollama service
if systemctl is-active ollama.service >/dev/null 2>&1; then
    substep "Ollama service is already running"
else
    processing "Starting Ollama service"
    systemctl start ollama.service
    success "Ollama service started"
fi

# Verify service status
if systemctl is-active ollama.service >/dev/null 2>&1; then
    success "Ollama service is running and ready"
else
    error "Failed to start Ollama service"
    exit 1
fi