#!/bin/bash
# Install Node packages (idempotent)

set -e

echo "Installing Node packages..."

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

# Check if gemini command is available
if command -v gemini >/dev/null 2>&1; then
    echo "Gemini CLI is already installed"
else
    echo "Installing Gemini CLI globally..."
    npm install -g @google/gemini-cli
    echo "Gemini CLI installed"
fi

# Check if md-tree command is available
if command -v md-tree >/dev/null 2>&1; then
    echo "md-tree is already installed"
else
    echo "Installing md-tree globally..."
    npm install -g @kayvan/markdown-tree-parser
    echo "md-tree installed"
fi