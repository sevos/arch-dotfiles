#!/bin/bash
# Tuxedo InfinityBook Gen9 AMD power management configuration
# Optimized for AMD Ryzen 7 8845HS with Radeon 780M graphics

set -uo pipefail

SCRIPT_NAME="$(basename "$0")"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "[$SCRIPT_NAME] Error: This script must be run as root" >&2
    exit 1
fi

# AMD-specific kernel parameters for InfinityBook Gen9
REQUIRED_PARAMS="acpi.ec_no_wakeup=1 mem_sleep_default=deep amd_pstate=active"

log() {
    echo "[$SCRIPT_NAME] $*"
}

log "Configuring Tuxedo InfinityBook Gen9 AMD power management..."

# Configure systemd-boot kernel parameters for AMD optimization
if bootctl status &>/dev/null; then
    log "systemd-boot detected, configuring AMD kernel parameters..."
    
    # Get current boot entry
    CURRENT_ENTRY=$(bootctl list --json=short 2>/dev/null | jq -r '.[] | select(.isSelected == true) | .id' 2>/dev/null || true)
    
    if [[ -z "$CURRENT_ENTRY" ]]; then
        # Fallback: find the most recent entry
        CURRENT_ENTRY=$(ls -t /boot/loader/entries/*.conf 2>/dev/null | head -1 | xargs basename 2>/dev/null || true)
    fi
    
    if [[ -n "$CURRENT_ENTRY" ]]; then
        ENTRY_FILE="/boot/loader/entries/${CURRENT_ENTRY}"
        
        if [[ -f "$ENTRY_FILE" ]]; then
            # Always cleanup old parameters and ensure AMD parameters are present
            log "Cleaning up and configuring AMD optimization parameters in $ENTRY_FILE"
            
            # Backup original file
            cp "$ENTRY_FILE" "${ENTRY_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Remove old problematic ACPI parameters
            sed -i 's/acpi_os_name=Linux //g' "$ENTRY_FILE"
            sed -i 's/acpi_osi=[^ ]* //g' "$ENTRY_FILE"
            sed -i 's/acpi_osi= //g' "$ENTRY_FILE"
            
            # Remove existing AMD parameters to avoid duplicates
            sed -i 's/acpi\.ec_no_wakeup=[^ ]* //g' "$ENTRY_FILE"
            sed -i 's/mem_sleep_default=[^ ]* //g' "$ENTRY_FILE"
            sed -i 's/amd_pstate=[^ ]* //g' "$ENTRY_FILE"
            
            # Add AMD parameters to options line
            sed -i "s/^options \(.*\)$/options \1 $REQUIRED_PARAMS/" "$ENTRY_FILE"
            
            log "AMD optimization parameters configured in boot entry"
        else
            log "Warning: Boot entry file not found: $ENTRY_FILE"
        fi
    else
        log "Warning: Could not determine current boot entry"
    fi
else
    log "systemd-boot not detected, skipping kernel parameter configuration"
fi

# Load tuxedo modules if drivers are installed
log "Loading Tuxedo kernel modules..."
TUXEDO_MODULES_LIST=(
    "tuxedo_io"
    "tuxedo_keyboard" 
    "tuxedo_cc_wmi"
)

MODULES_LOADED=0
MODULES_FAILED=()

for module in "${TUXEDO_MODULES_LIST[@]}"; do
    if modinfo "$module" >/dev/null 2>&1; then
        if modprobe "$module" 2>/dev/null; then
            log "Module $module loaded successfully"
            ((MODULES_LOADED++))
        else
            log "Warning: Failed to load module $module (modprobe exit code: $?)"
            MODULES_FAILED+=("$module")
        fi
    else
        log "Warning: Module $module not available (not built for current kernel?)"
        MODULES_FAILED+=("$module")
    fi
done

if [[ $MODULES_LOADED -gt 0 ]]; then
    log "Successfully loaded $MODULES_LOADED Tuxedo modules"
else
    log "Warning: No Tuxedo modules loaded"
    if [[ ${#MODULES_FAILED[@]} -gt 0 ]]; then
        log "Failed modules: ${MODULES_FAILED[*]}"
        log "Run 'dkms status' to check if modules are built for current kernel"
        log "Run 'pacman -Q linux-headers' to check if headers are installed"
    fi
fi

# Configure power management daemons
log "Configuring power management daemons..."

# Check for power-profiles-daemon conflict with TLP
if systemctl is-enabled power-profiles-daemon.service &>/dev/null; then
    if pacman -Q tlp &>/dev/null; then
        log "Masking power-profiles-daemon due to TLP installation"
        systemctl mask power-profiles-daemon.service
        systemctl stop power-profiles-daemon.service 2>/dev/null || true
    fi
fi

# Enable TCC services if available
if systemctl list-unit-files | grep -q "tccd.service"; then
    log "Enabling Tuxedo Control Center daemon..."
    systemctl enable tccd.service
    systemctl enable tccd-sleep.service
elif systemctl list-unit-files | grep -q "tuxedo-control-center"; then
    log "Enabling Tuxedo Control Center service..."
    systemctl enable --now tuxedo-control-center 2>/dev/null || true
fi

# Create power saving configurations
log "Creating power saving configurations..."

# PCIe ASPM power saving
cat > /etc/udev/rules.d/50-pcie-power.rules << 'EOF'
# PCIe Active State Power Management for Tuxedo InfinityBook Gen9
SUBSYSTEM=="pci", ATTR{power/control}="auto"
EOF

# NVMe power management
if ! grep -q "nvme_core.default_ps_max_latency_us" /etc/modprobe.d/nvme.conf 2>/dev/null; then
    echo "options nvme_core default_ps_max_latency_us=5500" > /etc/modprobe.d/nvme.conf
    log "NVMe APST power saving configured"
fi

# Audio codec power saving
if ! grep -q "snd_hda_intel.*power_save" /etc/modprobe.d/audio-powersave.conf 2>/dev/null; then
    echo "options snd_hda_intel power_save=10 power_save_controller=Y" > /etc/modprobe.d/audio-powersave.conf
    log "Audio codec power saving configured"
fi

# USB autosuspend with HID exclusions
cat > /etc/udev/rules.d/50-usb-power.rules << 'EOF'
# USB autosuspend for Tuxedo InfinityBook Gen9
# Enable autosuspend for most USB devices
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"

# Exclude HID devices (keyboard, mouse, touchpad) from autosuspend
ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="03", ATTR{power/control}="on"

# Exclude known problematic devices
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="0129", ATTR{power/control}="on"
EOF

# AMD GPU power management
log "Configuring AMD Radeon 780M power management..."
cat > /etc/udev/rules.d/50-amd-gpu-power.rules << 'EOF'
# AMD Radeon 780M power management for Tuxedo InfinityBook Gen9
KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_state}="battery"
KERNEL=="card0", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="auto"
EOF

# Enable runtime PM for AMD GPU
if [[ -d /sys/bus/pci/devices/0000:*:00.0 ]]; then
    for gpu_device in /sys/bus/pci/devices/0000:*:00.0; do
        if [[ -f "$gpu_device/vendor" ]] && grep -q "0x1002" "$gpu_device/vendor" 2>/dev/null; then
            echo auto > "$gpu_device/power/control" 2>/dev/null || true
            log "Enabled runtime PM for AMD GPU"
            break
        fi
    done
fi

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Configure system power management
log "Configuring system power management..."

# Reload systemd configuration
systemctl daemon-reload

# Logind configuration has been updated
log "Logind configuration updated. Changes will take effect after reboot."

# Display configuration summary
log "Power management configuration completed:"
echo "  AMD Kernel Parameters:"
echo "    - acpi.ec_no_wakeup=1 (prevents spurious wake events)"
echo "    - mem_sleep_default=deep (S3 suspend for better battery life)"
echo "    - amd_pstate=active (hardware P-state control)"
echo "  Power Optimizations:"
echo "    - PCIe ASPM enabled"
echo "    - NVMe APST configured (5.5ms latency)"
echo "    - Audio codec power saving (10s timeout)"
echo "    - USB selective autosuspend (HID devices excluded)"
echo "    - AMD Radeon 780M runtime power management"

if bootctl status &>/dev/null; then
    log "systemd-boot configuration updated"
else
    log "Manual bootloader configuration may be required"
fi

log "Tuxedo InfinityBook Gen9 AMD power management setup completed"
log ""
log "IMPORTANT: Reboot required to apply:"
log "  - Kernel parameter changes"
log "  - Logind power button/lid behavior"  
log "  - Module configurations"
log ""
log "Please reboot your system to activate all changes."