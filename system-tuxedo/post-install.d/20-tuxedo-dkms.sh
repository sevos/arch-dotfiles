#!/bin/bash
# Tuxedo DKMS module management

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

log() {
    echo "[$SCRIPT_NAME] $*"
}

log "Configuring Tuxedo DKMS modules..."

# Check if tuxedo-drivers-dkms is installed
if ! pacman -Q tuxedo-drivers-dkms &>/dev/null; then
    log "tuxedo-drivers-dkms not installed, skipping DKMS configuration"
    exit 0
fi

# Get current kernel version
KERNEL_VERSION=$(uname -r)
log "Current kernel version: $KERNEL_VERSION"

# Check DKMS status for tuxedo modules
log "Checking DKMS status..."
DKMS_STATUS=$(dkms status 2>/dev/null || true)

if [[ -n "$DKMS_STATUS" ]]; then
    log "Current DKMS status:"
    echo "$DKMS_STATUS"
else
    log "No DKMS modules found"
fi

# Find tuxedo modules in DKMS
TUXEDO_MODULES=$(dkms status 2>/dev/null | grep -i tuxedo || true)

if [[ -z "$TUXEDO_MODULES" ]]; then
    log "No Tuxedo modules found in DKMS, attempting to add..."
    
    # Check if tuxedo source exists
    if [[ -d /usr/src/tuxedo-drivers-* ]]; then
        TUXEDO_DIR=$(ls -d /usr/src/tuxedo-drivers-* | head -1)
        TUXEDO_VERSION=$(basename "$TUXEDO_DIR" | sed 's/tuxedo-drivers-//')
        
        log "Adding tuxedo-drivers/$TUXEDO_VERSION to DKMS..."
        dkms add -m tuxedo-drivers -v "$TUXEDO_VERSION" || log "Warning: Failed to add tuxedo-drivers to DKMS"
    else
        log "Warning: Tuxedo drivers source not found in /usr/src/"
    fi
fi

# Rebuild tuxedo modules for current kernel
log "Building Tuxedo modules for kernel $KERNEL_VERSION..."

# Get tuxedo module info
TUXEDO_INFO=$(dkms status 2>/dev/null | grep -i tuxedo | head -1 || true)

if [[ -n "$TUXEDO_INFO" ]]; then
    # Extract module name and version
    MODULE_NAME=$(echo "$TUXEDO_INFO" | cut -d',' -f1 | cut -d'/' -f1)
    MODULE_VERSION=$(echo "$TUXEDO_INFO" | cut -d',' -f1 | cut -d'/' -f2)
    
    log "Processing module: $MODULE_NAME version $MODULE_VERSION"
    
    # Check if already built for current kernel
    if dkms status -m "$MODULE_NAME" -v "$MODULE_VERSION" -k "$KERNEL_VERSION" 2>/dev/null | grep -q "installed"; then
        log "Module already built and installed for kernel $KERNEL_VERSION"
    else
        log "Building module for kernel $KERNEL_VERSION..."
        
        # Remove any existing build
        dkms remove -m "$MODULE_NAME" -v "$MODULE_VERSION" -k "$KERNEL_VERSION" 2>/dev/null || true
        
        # Build the module
        if dkms build -m "$MODULE_NAME" -v "$MODULE_VERSION" -k "$KERNEL_VERSION"; then
            log "Build successful, installing..."
            if dkms install -m "$MODULE_NAME" -v "$MODULE_VERSION" -k "$KERNEL_VERSION"; then
                log "Module installed successfully"
            else
                log "Error: Failed to install module"
                exit 1
            fi
        else
            log "Error: Failed to build module"
            log "Checking if linux-headers are installed..."
            if ! pacman -Q linux-headers &>/dev/null; then
                log "Warning: linux-headers not installed. Install with: pacman -S linux-headers"
            fi
            exit 1
        fi
    fi
else
    log "Warning: No Tuxedo modules found in DKMS after setup"
fi

# Verify modules can be loaded
log "Verifying Tuxedo modules..."
TUXEDO_MODULES_LIST=(
    "tuxedo_io"
    "tuxedo_keyboard" 
    "tuxedo_cc_wmi"
)

for module in "${TUXEDO_MODULES_LIST[@]}"; do
    if modinfo "$module" >/dev/null 2>&1; then
        log "Module $module is available"
    else
        log "Warning: Module $module not found"
    fi
done

log "Tuxedo DKMS configuration completed"