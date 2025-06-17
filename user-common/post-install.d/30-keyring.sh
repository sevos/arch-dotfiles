#!/bin/bash
# Configure GNOME Keyring for Secret Service API without SSH agent conflicts

set -euo pipefail

echo "Configuring GNOME Keyring..."

# Disable gcr-ssh-agent to prevent conflicts with 1Password SSH agent
echo "Disabling gcr-ssh-agent services..."
systemctl --user disable gcr-ssh-agent.socket gcr-ssh-agent.service 2>/dev/null || true
systemctl --user stop gcr-ssh-agent.socket gcr-ssh-agent.service 2>/dev/null || true

# Enable gnome-keyring-daemon socket for Secret Service API
echo "Enabling gnome-keyring-daemon socket..."
systemctl --user enable gnome-keyring-daemon.socket 2>/dev/null || true

echo "GNOME Keyring configuration completed."