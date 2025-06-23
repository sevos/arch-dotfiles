#!/bin/bash
# Configure printing services for network printer discovery

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

log "Setting up printing services..."

# Enable and start Avahi daemon for network discovery
if ! systemctl is-enabled avahi-daemon.service >/dev/null 2>&1; then
    log "Enabling avahi-daemon.service"
    systemctl enable avahi-daemon.service
else
    log "avahi-daemon.service already enabled"
fi

if ! systemctl is-active avahi-daemon.service >/dev/null 2>&1; then
    log "Starting avahi-daemon.service"
    systemctl start avahi-daemon.service
else
    log "avahi-daemon.service already running"
fi

# Enable and start CUPS printing service
if ! systemctl is-enabled cups.service >/dev/null 2>&1; then
    log "Enabling cups.service"
    systemctl enable cups.service
else
    log "cups.service already enabled"
fi

if ! systemctl is-active cups.service >/dev/null 2>&1; then
    log "Starting cups.service"
    systemctl start cups.service
else
    log "cups.service already running"
fi

# Restart services to apply new configuration
log "Restarting services to apply configuration"
systemctl restart avahi-daemon.service
systemctl restart cups.service

log "Printing services setup complete!"
log "You can now:"
log "  - Access CUPS web interface at http://localhost:631"
log "  - Use 'hp-setup -i' to configure HP printers"
log "  - Use 'system-config-printer' for GUI configuration"
log "  - Auto-discover network printers via mDNS/DNS-SD"