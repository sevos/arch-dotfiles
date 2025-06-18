#!/bin/bash
# Install development tools via mise (idempotent)

set -e

echo "Installing development tools via mise..."

# Ensure mise environment is loaded
eval "$(mise activate bash)"

# Install Python 3.13
echo "Installing Python 3.13..."
if mise list python | grep -q "python.*3\.13\."; then
    echo "Python 3.13 is already installed"
else
    mise install python@3.13
    echo "Python 3.13 installed"
fi

# Install Node 24
echo "Installing Node 24..."
if mise list node | grep -q "node.*24\."; then
    echo "Node 24 is already installed"
else
    mise install node@24
    echo "Node 24 installed"
fi

# Install Ruby 3
echo "Installing Ruby 3..."
if mise list ruby | grep -q "ruby.*3\."; then
    echo "Ruby 3 is already installed"
else
    mise install ruby@3
    echo "Ruby 3 installed"
fi

# Set all tools as global defaults
echo "Setting tools as global defaults..."
mise use --global python@3.13
mise use --global node@24
mise use --global ruby@3

echo "Verifying tool installations..."
mise list --current

echo "Mise tools installation completed"