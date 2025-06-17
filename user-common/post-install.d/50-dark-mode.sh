#!/bin/bash
#
# Configure system-wide dark mode preference
# This setting is respected by Chrome, Electron apps (Slack, VS Code), and GTK applications
#

set -euo pipefail

echo "Configuring dark mode preference..."

# Check current color scheme setting
current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")

if [[ "$current_scheme" != "'prefer-dark'" ]]; then
    echo "Setting color scheme to prefer dark mode"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    echo "Dark mode preference configured"
else
    echo "Dark mode already configured"
fi