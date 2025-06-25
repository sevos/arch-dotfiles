#!/bin/bash
# Build final Niri configuration for Tuxedo
# Combines base config with tuxedo display configuration

set -euo pipefail

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find the dotfiles directory - this script could be stowed or in the repo
DOTFILES_DIR="$HOME/.dotfiles"
BASE_CONFIG="$DOTFILES_DIR/user-common/.config/niri/base.kdl"
TUXEDO_CONFIG="$SCRIPT_DIR/tuxedo-outputs.kdl"
OUTPUT_CONFIG="$SCRIPT_DIR/config.kdl"

# Check if base config exists
if [[ ! -f "$BASE_CONFIG" ]]; then
    echo "Error: Base configuration not found at $BASE_CONFIG" >&2
    exit 1
fi

# Check if tuxedo config exists
if [[ ! -f "$TUXEDO_CONFIG" ]]; then
    echo "Error: Tuxedo display configuration not found at $TUXEDO_CONFIG" >&2
    exit 1
fi

echo "Building Niri config for Tuxedo..."

# Create temporary file for building config
TEMP_CONFIG=$(mktemp)
trap "rm -f $TEMP_CONFIG" EXIT

# Combine base config with tuxedo-specific config
{
    echo "// Generated Niri configuration for Tuxedo"
    echo "// Built on: $(date)"
    echo ""
    
    # Include base configuration
    cat "$BASE_CONFIG"
    
    echo ""
    echo "// Tuxedo-specific display configuration"
    cat "$TUXEDO_CONFIG"
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