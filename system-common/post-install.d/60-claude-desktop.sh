#!/bin/bash
set -e

echo "Setting up Claude Desktop..."

# Configuration
REPO_URL="https://github.com/aaddrick/claude-desktop-arch.git"
BUILD_DIR="/opt/claude-desktop-arch"
PACKAGE_NAME="claude-desktop"
LOG_FILE="/var/log/claude-desktop-install.log"
LAST_RUN_FILE="/var/log/claude-desktop-last-run"
WEEK_IN_SECONDS=604800  # 7 days * 24 hours * 60 minutes * 60 seconds

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if package is already installed and get version
get_installed_version() {
    if pacman -Qi "$PACKAGE_NAME" &>/dev/null; then
        pacman -Qi "$PACKAGE_NAME" | grep Version | awk '{print $3}' | cut -d'-' -f1
    else
        echo "not_installed"
    fi
}

# Get last run timestamp
get_last_run_time() {
    if [ -f "$LAST_RUN_FILE" ]; then
        cat "$LAST_RUN_FILE"
    else
        echo "0"
    fi
}

# Check if script should run based on time constraint
should_run() {
    local current_time=$(date +%s)
    local last_run_time=$(get_last_run_time)
    local time_diff=$((current_time - last_run_time))
    
    # Always run if never run before
    if [ "$last_run_time" = "0" ]; then
        return 0
    fi
    
    # Run if a week has passed
    if [ "$time_diff" -ge "$WEEK_IN_SECONDS" ]; then
        return 0
    fi
    
    # Don't run if less than a week
    return 1
}

# Update last run timestamp
update_last_run_time() {
    date +%s > "$LAST_RUN_FILE"
    chmod 644 "$LAST_RUN_FILE"
}

# Get available version from the repository
get_available_version() {
    cd "$BUILD_DIR"
    
    # Run makepkg as SUDO_USER to determine version without building
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" bash -c "cd '$BUILD_DIR' && makepkg --printsrcinfo" | grep -E "pkgver\s*=" | head -1 | awk '{print $3}'
    else
        log "ERROR: SUDO_USER not set, cannot run makepkg safely"
        exit 1
    fi
}

# Clone or update repository
setup_repository() {
    # Clean up existing directory to avoid ownership issues
    if [ -d "$BUILD_DIR" ]; then
        log "Cleaning up existing build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    log "Cloning claude-desktop-arch repository..."
    git clone "$REPO_URL" "$BUILD_DIR"
    
    # Set proper ownership for the sudo user
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$BUILD_DIR"
    else
        log "WARNING: SUDO_USER not set, using root ownership"
        chown -R root:root "$BUILD_DIR"
    fi
    chmod -R 755 "$BUILD_DIR"
}

# Build and install Claude Desktop
build_and_install() {
    cd "$BUILD_DIR"
    
    log "Cleaning previous build artifacts..."
    rm -rf pkg/ src/ *.pkg.tar.* 2>/dev/null || true
    
    log "Building Claude Desktop package..."
    
    if [ -z "$SUDO_USER" ]; then
        log "ERROR: SUDO_USER not set, cannot run makepkg safely"
        exit 1
    fi
    
    # Build package as SUDO_USER
    sudo -u "$SUDO_USER" bash -c "cd '$BUILD_DIR' && makepkg -sf --noconfirm"
    
    # Find the built package
    PACKAGE_FILE=$(find "$BUILD_DIR" -name "*.pkg.tar.*" -type f | head -1)
    
    if [ -z "$PACKAGE_FILE" ]; then
        log "ERROR: No package file found after build"
        exit 1
    fi
    
    log "Installing Claude Desktop package: $(basename "$PACKAGE_FILE")"
    pacman -U --noconfirm "$PACKAGE_FILE"
    
    log "Updating desktop database..."
    update-desktop-database /usr/share/applications/ 2>/dev/null || true
    
    log "Claude Desktop installation completed successfully"
}

# Main execution
main() {
    # Ensure we're running as root but with SUDO_USER
    if [ "$EUID" -ne 0 ]; then
        echo "This script must be run with sudo"
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    log "Starting Claude Desktop setup..."
    
    # Check SUDO_USER is available
    if [ -z "$SUDO_USER" ]; then
        log "ERROR: This script must be run with sudo, not as root directly"
        exit 1
    fi
    
    # Check if Claude Desktop is already installed
    INSTALLED_VERSION=$(get_installed_version)
    
    # If already installed, check if we should run based on time constraint
    if [ "$INSTALLED_VERSION" != "not_installed" ]; then
        if ! should_run; then
            local last_run_time=$(get_last_run_time)
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_run_time))
            local days_left=$(( (WEEK_IN_SECONDS - time_diff) / 86400 ))
            log "Claude Desktop already installed (version $INSTALLED_VERSION). Skipping update check - $days_left days until next check allowed."
            exit 0
        fi
    fi
    
    # Setup repository
    setup_repository
    
    # Get versions
    INSTALLED_VERSION=$(get_installed_version)
    AVAILABLE_VERSION=$(get_available_version)
    
    log "Installed version: $INSTALLED_VERSION"
    log "Available version: $AVAILABLE_VERSION"
    
    # Check if update is needed
    if [ "$INSTALLED_VERSION" = "$AVAILABLE_VERSION" ]; then
        log "Claude Desktop is already up to date (version $INSTALLED_VERSION)"
        # Update timestamp even if no installation needed to reset weekly timer
        update_last_run_time
        exit 0
    fi
    
    if [ "$INSTALLED_VERSION" = "not_installed" ]; then
        log "Claude Desktop not installed, proceeding with installation..."
    else
        log "Updating Claude Desktop from $INSTALLED_VERSION to $AVAILABLE_VERSION..."
    fi
    
    # Build and install
    build_and_install
    
    # Update timestamp after successful installation
    update_last_run_time
    log "Claude Desktop setup completed successfully - next check allowed in 7 days"
}

# Run main function
main "$@"