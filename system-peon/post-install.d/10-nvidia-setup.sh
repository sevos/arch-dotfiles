#!/bin/bash

set -euo pipefail

MKINITCPIO_CONF="/etc/mkinitcpio.conf"
MODPROBE_CONF="/etc/modprobe.d/blacklist-nouveau.conf"

echo "Setting up NVIDIA drivers..."

# Check if kms is in HOOKS and remove it if present
if grep -q "^HOOKS.*kms" "$MKINITCPIO_CONF"; then
    echo "Removing kms from mkinitcpio HOOKS..."
    sed -i 's/\(HOOKS=.*\)kms\(.*\)/\1\2/' "$MKINITCPIO_CONF"
    # Clean up any double spaces
    sed -i 's/  / /g' "$MKINITCPIO_CONF"
    REGENERATE_INITRAMFS=true
else
    echo "kms not found in mkinitcpio HOOKS, no changes needed"
    REGENERATE_INITRAMFS=false
fi

# Blacklist nouveau module if not already blacklisted
if [ ! -f "$MODPROBE_CONF" ] || ! grep -q "blacklist nouveau" "$MODPROBE_CONF"; then
    echo "Blacklisting nouveau module..."
    echo "blacklist nouveau" > "$MODPROBE_CONF"
    REGENERATE_INITRAMFS=true
fi

# Only regenerate initramfs if we made changes
if [ "$REGENERATE_INITRAMFS" = true ]; then
    echo "Regenerating initramfs..."
    mkinitcpio -P
    echo "NVIDIA setup complete. Reboot required for changes to take effect."
else
    echo "NVIDIA setup complete. No initramfs regeneration needed."
fi