#!/bin/bash
set -e

echo "Setting up greetd display manager..."

# Enable greetd service
systemctl enable greetd.service

# Set proper permissions for greetd config files
chmod 644 /etc/greetd/config.toml
chmod 644 /etc/greetd/regreet.toml
chmod 644 /etc/greetd/environments

# Ensure greeter user is in required groups (might already be done by package)
if ! groups greeter 2>/dev/null | grep -q video; then
    usermod -a -G video greeter
fi

if ! groups greeter 2>/dev/null | grep -q users; then
    usermod -a -G users greeter
fi

# Fix permissions for session directories
chmod 755 /usr/share/wayland-sessions/
chmod 644 /usr/share/wayland-sessions/*.desktop 2>/dev/null || true
chmod 755 /usr/share/xsessions/ 2>/dev/null || true
chmod 644 /usr/share/xsessions/*.desktop 2>/dev/null || true

echo "Greetd setup complete!"