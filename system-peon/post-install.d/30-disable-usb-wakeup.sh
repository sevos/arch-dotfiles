#!/bin/bash
# Enable disable-usb-wakeup service on peon machine

hostname=$(cat /etc/hostname)

if [ "$hostname" = "peon" ]; then
    echo "Enabling disable-usb-wakeup service for peon machine..."
    systemctl enable disable-usb-wakeup.service
    systemctl start disable-usb-wakeup.service
    echo "USB wake-up disable service enabled and started"
else
    echo "Skipping USB wake-up disable service (not peon machine)"
fi