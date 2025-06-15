#!/bin/bash
set -e

echo "Setting up greetd display manager..."

# Enable greetd service
systemctl enable greetd.service

# Set proper permissions for greetd config files
chmod 644 /etc/greetd/config.toml
chmod 644 /etc/greetd/regreet.toml
chmod 644 /etc/greetd/environments

# Ensure greeter user is in video group (might already be done by package)
if ! groups greeter 2>/dev/null | grep -q video; then
    usermod -a -G video greeter
fi

echo "Greetd setup complete!"