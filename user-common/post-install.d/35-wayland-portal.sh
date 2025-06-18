#!/bin/bash
# Configure Wayland desktop portals for screen recording and other desktop integration

set -euo pipefail

echo "Configuring Wayland desktop portals..."

# Start xdg-desktop-portal-wlr for screen recording support in Wayland
echo "Starting xdg-desktop-portal-wlr service..."
systemctl --user start xdg-desktop-portal-wlr 2>/dev/null || true

echo "Wayland portal configuration completed."