#!/bin/bash
# Configure dual network setup for PEON (ethernet for internet, WiFi for smart home)

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring PEON dual network setup..."

# Remove conflicting network managers if they exist
substep "Removing unnecessary network managers"
for pkg in netctl wpa_supplicant impala; do
    if pacman -Qi "$pkg" &>/dev/null; then
        processing "Removing $pkg"
        pacman -Rns --noconfirm "$pkg" || warn "Failed to remove $pkg"
    fi
done

# Remove conflicting systemd-networkd configs
substep "Removing conflicting network configurations"
if [[ -f /etc/systemd/network/20-wlan.network ]]; then
    processing "Removing /etc/systemd/network/20-wlan.network"
    rm -f /etc/systemd/network/20-wlan.network
    success "Removed conflicting WiFi configuration"
fi

# Enable and start fix-routing service
substep "Enabling routing fix service"
systemctl enable fix-routing.service || warn "Failed to enable fix-routing service"

# Restart systemd-networkd to apply wireless configuration
substep "Restarting systemd-networkd"
systemctl restart systemd-networkd

# Wait a moment for network to reconfigure
sleep 2

# Clean up any existing WiFi default route
substep "Cleaning up WiFi default route"
ip route del default via 192.168.1.1 dev wlan0 2>/dev/null && success "Removed WiFi default route" || info "No WiFi default route to remove"

# Start the fix-routing service immediately
substep "Running routing fix service"
systemctl start fix-routing.service || warn "Failed to start fix-routing service"

success "PEON network configuration complete"
info "Ethernet handles internet, WiFi for smart home (192.168.1.0/24) only"
info "Run 'ip route | grep default' to verify only ethernet default route exists"