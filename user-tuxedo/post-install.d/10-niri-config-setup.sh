#!/bin/bash
# Initialize Niri configuration for Tuxedo

set -euo pipefail

echo "Setting up Niri configuration for Tuxedo..."

# Configuration paths
NIRI_CONFIG_DIR="$HOME/.config/niri"
BUILD_SCRIPT="$NIRI_CONFIG_DIR/build-config.sh"

# Ensure niri config directory exists
mkdir -p "$NIRI_CONFIG_DIR"

# Build initial configuration
if [[ -x "$BUILD_SCRIPT" ]]; then
    echo "Building Niri configuration..."
    "$BUILD_SCRIPT"
else
    echo "Warning: Build script not found or not executable: $BUILD_SCRIPT"
fi

echo "Niri configuration setup completed"