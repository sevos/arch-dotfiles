#!/bin/bash
# Enable and start Bluetooth service

set -euo pipefail

echo "Enabling and starting Bluetooth service..."

# Enable and start bluetooth service
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

# Check if service is running
if systemctl is-active --quiet bluetooth.service; then
    echo "✓ Bluetooth service is running successfully"
else
    echo "✗ Failed to start Bluetooth service"
    exit 1
fi