#!/bin/bash
# Switch from iwd to NetworkManager for WiFi and VPN management

set -uo pipefail

SCRIPT_NAME="$(basename "$0")"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "[$SCRIPT_NAME] Error: This script must be run as root" >&2
    exit 1
fi

log() {
    echo "[$SCRIPT_NAME] $*"
}

log "Configuring NetworkManager with WireGuard support..."

# Stop and disable iwd if running
if systemctl is-active --quiet iwd.service; then
    log "Stopping iwd service..."
    systemctl stop iwd.service
fi

if systemctl is-enabled --quiet iwd.service; then
    log "Disabling iwd service..."
    systemctl disable iwd.service
fi

# Enable and start NetworkManager
log "Enabling NetworkManager service..."
systemctl enable NetworkManager.service

if ! systemctl is-active --quiet NetworkManager.service; then
    log "Starting NetworkManager service..."
    systemctl start NetworkManager.service
fi

# Ensure NetworkManager manages WiFi
log "Configuring NetworkManager for WiFi management..."
mkdir -p /etc/NetworkManager/conf.d

# Create NetworkManager configuration
cat > /etc/NetworkManager/conf.d/wifi.conf << 'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

# Enable WireGuard support
log "Enabling WireGuard kernel module..."
if ! lsmod | grep -q wireguard; then
    modprobe wireguard 2>/dev/null || log "Warning: WireGuard module not available"
fi

# Create WireGuard module loading configuration
echo "wireguard" > /etc/modules-load.d/wireguard.conf

# Restart NetworkManager to apply configuration
log "Restarting NetworkManager to apply configuration..."
systemctl restart NetworkManager.service

# Check status
if systemctl is-active --quiet NetworkManager.service; then
    log "NetworkManager is running successfully"
else
    log "Warning: NetworkManager failed to start"
    exit 1
fi

log "NetworkManager configuration completed:"
echo "  - iwd service disabled"
echo "  - NetworkManager service enabled"
echo "  - WiFi MAC randomization enabled"
echo "  - WireGuard kernel module configured"
echo ""
log "You can now use network-manager-applet or nm-connection-editor to manage"
log "WiFi connections and WireGuard VPN configurations."