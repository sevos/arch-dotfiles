#!/bin/bash
# Configure VS Code to use GNOME Keyring for password storage

set -euo pipefail

echo "Configuring VS Code GNOME Keyring integration..."

# Define VS Code config directory
VSCODE_DIR="$HOME/.vscode"
ARGV_JSON="$VSCODE_DIR/argv.json"

# Create VS Code config directory if it doesn't exist
if [ ! -d "$VSCODE_DIR" ]; then
    echo "Creating VS Code config directory..."
    mkdir -p "$VSCODE_DIR"
fi

# Configure argv.json with keyring integration
if [ -f "$ARGV_JSON" ]; then
    echo "Updating existing argv.json..."
    
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed"
        exit 1
    fi
    
    # Create temporary file
    tmp_result=$(mktemp)
    
    # Strip comments and blank lines, then use jq to add/update the password-store setting
    sed 's#//.*##g; /^[[:space:]]*$/d' "$ARGV_JSON" | jq '. + {"password-store": "gnome-libsecret"}' > "$tmp_result"
    
    # Replace the original file with the updated version
    mv "$tmp_result" "$ARGV_JSON"
    
else
    echo "Creating new argv.json with keyring configuration..."
    jq -n '{"password-store": "gnome-libsecret"}' > "$ARGV_JSON"
fi

echo "VS Code GNOME Keyring configuration completed."
echo "VS Code will now use GNOME keyring for password storage."