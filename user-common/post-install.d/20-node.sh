#!/bin/bash
# Install Node 24 via mise (idempotent)

set -e

echo "Checking Node 24 installation via mise..."

# Check if Node 24 is already installed
if mise list node | grep -q "node.*24\."; then
    echo "Node 24 is already installed"
else
    echo "Installing Node 24 via mise..."
    mise install node@24
    echo "Node 24 installed"
fi

# Check if Node 24 is set as global default
if mise list --current node | grep -q "node.*24\."; then
    echo "Node 24 is already set as global default"
else
    echo "Setting Node 24 as global default..."
    mise use --global node@24
    echo "Node 24 set as global default"
fi

# Ensure mise environment is loaded for subsequent commands
eval "$(mise activate bash)"

# Check if claude command is available
if command -v claude >/dev/null 2>&1; then
    echo "Claude CLI is already installed"
else
    echo "Installing Claude CLI globally..."
    npm install -g @anthropic-ai/claude-code
    echo "Claude CLI installed"
fi