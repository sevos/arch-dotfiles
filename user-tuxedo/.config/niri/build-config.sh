#!/bin/bash
# Build final Niri configuration for Tuxedo
# Combines base config with tuxedo display configuration and environment.d files

set -euo pipefail

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find the dotfiles directory - this script could be stowed or in the repo
DOTFILES_DIR="$HOME/.dotfiles"
BASE_CONFIG="$DOTFILES_DIR/user-common/.config/niri/base.kdl"
ENV_DIR="$HOME/.config/niri/environment.d"
TUXEDO_CONFIG="$SCRIPT_DIR/tuxedo-outputs.kdl"
OUTPUT_CONFIG="$SCRIPT_DIR/tuxedo-config.kdl"

# Function to generate environment block from environment.d files
generate_environment_block() {
    echo "// Environment variables generated from environment.d/ files"
    echo "environment {"
    
    # Process all .env files in environment.d directory, sorted by name
    if [[ -d "$ENV_DIR" ]]; then
        find "$ENV_DIR" -name "*.env" | sort | while read -r env_file; do
            # Process each line in the environment file
            while IFS='=' read -r key value || [[ -n "$key" ]]; do
                # Skip empty lines and comments
                [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
                
                # Strip leading/trailing whitespace
                key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                
                # Validate key format (uppercase letters, numbers, underscores)
                if [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
                    echo "    $key \"$value\""
                fi
            done < "$env_file"
        done
    else
        echo "    // No environment.d directory found at $ENV_DIR"
    fi
    
    echo "}"
}

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

# Create temporary file for environment block
ENV_BLOCK_FILE=$(mktemp)
trap "rm -f $TEMP_CONFIG $ENV_BLOCK_FILE" EXIT

# Generate environment block
generate_environment_block > "$ENV_BLOCK_FILE"

# Combine base config with tuxedo-specific config
{
    echo "// Generated Niri configuration for Tuxedo"
    echo "// Built on: $(date)"
    echo ""
    
    # Include base configuration with environment block replacement
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "// BUILD_SCRIPT_ENVIRONMENT_BLOCK_PLACEHOLDER" ]]; then
            cat "$ENV_BLOCK_FILE"
        else
            echo "$line"
        fi
    done < "$BASE_CONFIG"
    
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

# Create symlink to config.kdl in the stowed location if we're in the stowed directory
if [[ "$SCRIPT_DIR" == "$HOME/.config/niri" ]]; then
    ln -sf "$(basename "$OUTPUT_CONFIG")" "$SCRIPT_DIR/config.kdl"
    echo "Updated config.kdl symlink to point to $(basename "$OUTPUT_CONFIG")"
fi

# If niri is running, the config will be auto-reloaded
if pgrep -x niri >/dev/null 2>&1; then
    echo "Niri is running - configuration will be auto-reloaded"
fi