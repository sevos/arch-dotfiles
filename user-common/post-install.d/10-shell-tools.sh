#!/bin/bash
# Set up shell tools (idempotent)

set -e

echo "Setting up shell tools..."

# Initialize zoxide database if it doesn't exist
if [ ! -f "$HOME/.local/share/zoxide/db.zo" ]; then
    echo "Initializing zoxide database..."
    mkdir -p "$HOME/.local/share/zoxide"
    # Add current directory to zoxide
    zoxide add "$PWD" 2>/dev/null || true
    echo "Zoxide database initialized"
else
    echo "Zoxide database already exists"
fi

# Ensure proper permissions for shell files
echo "Setting proper permissions for shell configuration files..."
chmod 644 "$HOME/.bashrc" 2>/dev/null || true
chmod 644 "$HOME/.bash_aliases" 2>/dev/null || true
chmod 644 "$HOME/.profile" 2>/dev/null || true

echo "Shell tools setup completed"