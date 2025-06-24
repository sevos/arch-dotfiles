#!/bin/bash
# Initialize Niri GPU switching configuration for PEON

set -euo pipefail

echo "Setting up Niri GPU switching configuration for PEON..."

# Configuration paths
NIRI_CONFIG_DIR="$HOME/.config/niri"
GPU_ACTIVE_SYMLINK="$NIRI_CONFIG_DIR/gpu-active.kdl"
BUILD_SCRIPT="$NIRI_CONFIG_DIR/build-config.sh"

# Ensure niri config directory exists
mkdir -p "$NIRI_CONFIG_DIR"

# Create initial symlink to NVIDIA (default)
if [[ ! -L "$GPU_ACTIVE_SYMLINK" ]]; then
    echo "Creating initial GPU configuration symlink (defaulting to NVIDIA)..."
    ln -sf "gpu-nvidia.kdl" "$GPU_ACTIVE_SYMLINK"
else
    echo "GPU configuration symlink already exists"
fi

# Build initial configuration
if [[ -x "$BUILD_SCRIPT" ]]; then
    echo "Building initial Niri configuration..."
    "$BUILD_SCRIPT"
else
    echo "Warning: Build script not found or not executable: $BUILD_SCRIPT"
fi

echo "Niri GPU switching setup completed"