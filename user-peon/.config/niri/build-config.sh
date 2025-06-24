#!/bin/bash
# Build final Niri configuration for PEON
# Combines base config with active GPU configuration

set -euo pipefail

# Get the directory this script is in (resolving symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# If we're in the actual home directory (via symlink), use different path
if [[ "$SCRIPT_DIR" == "$HOME/.config/niri" ]]; then
    BASE_CONFIG="$SCRIPT_DIR/base.kdl"
else
    BASE_CONFIG="$SCRIPT_DIR/../../user-common/.config/niri/base.kdl"
fi
GPU_ACTIVE_CONFIG="$SCRIPT_DIR/gpu-active.kdl"
OUTPUT_CONFIG="$SCRIPT_DIR/config.kdl"

# Check if base config exists
if [[ ! -f "$BASE_CONFIG" ]]; then
    echo "Error: Base configuration not found at $BASE_CONFIG" >&2
    exit 1
fi

# Check if GPU active config exists (should be a symlink)
if [[ ! -f "$GPU_ACTIVE_CONFIG" ]]; then
    echo "Error: Active GPU configuration not found at $GPU_ACTIVE_CONFIG" >&2
    echo "This should be a symlink to either gpu-nvidia.kdl or gpu-intel.kdl" >&2
    exit 1
fi

# Determine which GPU config is active
if [[ -L "$GPU_ACTIVE_CONFIG" ]]; then
    ACTIVE_GPU=$(readlink "$GPU_ACTIVE_CONFIG" | sed 's/gpu-\(.*\)\.kdl/\1/')
    echo "Building Niri config for PEON with $ACTIVE_GPU GPU active..."
else
    echo "Warning: $GPU_ACTIVE_CONFIG is not a symlink, using as-is..."
fi

# Create temporary file for building config
TEMP_CONFIG=$(mktemp)
trap "rm -f $TEMP_CONFIG" EXIT

# Combine base config with GPU-specific config
{
    echo "// Generated Niri configuration for PEON"
    echo "// Built on: $(date)"
    echo "// Active GPU: ${ACTIVE_GPU:-unknown}"
    echo ""
    
    # Include base configuration
    cat "$BASE_CONFIG"
    
    echo ""
    echo "// GPU-specific output configuration"
    cat "$GPU_ACTIVE_CONFIG"
} > "$TEMP_CONFIG"

# Validate the generated config
if command -v niri >/dev/null 2>&1; then
    if ! niri validate --config "$TEMP_CONFIG" >/dev/null 2>&1; then
        echo "Error: Generated configuration is invalid" >&2
        echo "Running validation again with details:" >&2
        niri validate --config "$TEMP_CONFIG"
        exit 1
    fi
    echo "Configuration validation: PASSED"
else
    echo "Warning: niri command not found, skipping validation"
fi

# Move the validated config to final location
mv "$TEMP_CONFIG" "$OUTPUT_CONFIG"
echo "Configuration built successfully: $OUTPUT_CONFIG"

# If niri is running, the config will be auto-reloaded
if pgrep -x niri >/dev/null 2>&1; then
    echo "Niri is running - configuration will be auto-reloaded"
fi