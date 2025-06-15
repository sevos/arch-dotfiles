#!/bin/bash
# Install Ruby 3 via mise (idempotent)

set -e

echo "Checking Ruby 3 installation via mise..."

# Check if Ruby 3 is already installed
if mise list ruby | grep -q "ruby.*3\."; then
    echo "Ruby 3 is already installed"
else
    echo "Installing Ruby 3 via mise..."
    mise install ruby@3
    echo "Ruby 3 installed"
fi

# Check if Ruby 3 is set as global default
if mise list --current ruby | grep -q "ruby.*3\."; then
    echo "Ruby 3 is already set as global default"
else
    echo "Setting Ruby 3 as global default..."
    mise use --global ruby@3
    echo "Ruby 3 set as global default"
fi