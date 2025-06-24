#!/bin/bash

# 1Password CLI Post-Install Setup
# This script handles the post-installation configuration for 1Password CLI

set -euo pipefail

echo "Configuring 1Password CLI..."

# Check if op binary exists
if ! command -v op &> /dev/null; then
    echo "Warning: 1Password CLI (op) not found. Make sure to run sync-system.sh first."
    exit 0
fi

# Create onepassword-cli group if it doesn't exist
if ! getent group onepassword-cli &> /dev/null; then
    echo "Creating onepassword-cli group..."
    sudo groupadd onepassword-cli
fi

# Add current user to onepassword-cli group if not already a member
if ! groups "$USER" | grep -q onepassword-cli; then
    echo "Adding $USER to onepassword-cli group..."
    sudo usermod -aG onepassword-cli "$USER"
fi

# Set proper permissions on op binary
OP_PATH=$(which op)
echo "Setting permissions on $OP_PATH..."
sudo chgrp onepassword-cli "$OP_PATH"
sudo chmod g+s "$OP_PATH"

echo "1Password CLI setup completed!"
echo
echo "MANUAL STEPS REQUIRED:"
echo "1. Open 1Password desktop app and sign in"
echo "2. Go to Settings > Security"
echo "3. Enable 'Unlock using system authentication'"
echo "4. Go to Settings > Developer"
echo "5. Enable 'Integrate with 1Password CLI'"
echo
echo "After completing these steps, you can use 'op' commands."
echo "You may need to log out and back in for group changes to take effect."