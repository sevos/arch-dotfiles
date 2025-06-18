#!/bin/bash
# Configure Docker daemon and user permissions

set -euo pipefail

echo "Configuring Docker daemon and user permissions..."

# Enable docker service
sudo systemctl enable docker.service

# Try to start docker service with timeout
echo "Starting Docker service..."
if timeout 30 sudo systemctl start docker.service; then
    echo "✓ Docker service started successfully"
else
    echo "⚠ Docker service start timed out or failed"
    echo "Service will be enabled and should start on next boot"
    # Don't exit - continue with user group setup
fi

# Check if service is running (non-blocking)
if systemctl is-active --quiet docker.service; then
    echo "✓ Docker service is running"
else
    echo "⚠ Docker service not currently running (will start on boot)"
fi

# Add user to docker group if SUDO_USER is set
if [ -n "${SUDO_USER:-}" ]; then
    echo "Adding user $SUDO_USER to docker group..."
    sudo usermod -aG docker "$SUDO_USER"
    echo "✓ User $SUDO_USER added to docker group"
    echo "Note: User needs to log out and back in for group membership to take effect"
else
    echo "Warning: SUDO_USER not set, skipping user group addition"
fi

# Verify docker group exists
if getent group docker > /dev/null 2>&1; then
    echo "✓ Docker group exists"
else
    echo "✗ Docker group not found"
    exit 1
fi