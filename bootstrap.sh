#!/bin/bash

# Arch Linux Dotfiles Bootstrap Script
# Usage: curl -fsSL https://raw.githubusercontent.com/sevos/arch-dotfiles/main/bootstrap.sh | bash

set -e

REPO_URL="https://github.com/sevos/arch-dotfiles.git"
INSTALL_DIR="$HOME/.dotfiles"
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check if we're on Arch Linux
if ! command -v pacman &> /dev/null; then
    error "This script is designed for Arch Linux systems only"
fi

log "Starting Arch Linux dotfiles bootstrap..."

# Function to install packages with appropriate privileges
install_package() {
    local package="$1"
    local install_cmd="pacman -S --needed --noconfirm $package"
    
    if [[ $EUID -eq 0 ]]; then
        # Running as root, install directly
        $install_cmd
    else
        # Running as user, use sudo
        if command -v sudo &> /dev/null; then
            sudo $install_cmd
        else
            error "sudo not available and not running as root. Cannot install $package"
        fi
    fi
}

# Install git if not present
if ! command -v git &> /dev/null; then
    log "Git not found. Installing git..."
    install_package git
    log "Git installed successfully"
else
    log "Git is already installed"
fi

# Install stow if not present
if ! command -v stow &> /dev/null; then
    log "Stow not found. Installing stow..."
    install_package stow
    log "Stow installed successfully"
else
    log "Stow is already installed"
fi

# Detect hostname
if [[ -r /etc/hostname ]]; then
    HOSTNAME=$(cat /etc/hostname)
elif [[ -n "$HOSTNAME" ]]; then
    HOSTNAME="$HOSTNAME"
else
    HOSTNAME="unknown"
fi
log "Detected hostname: $HOSTNAME"

# Remove existing directory if it exists
if [[ -d "$INSTALL_DIR" ]]; then
    log "Removing existing dotfiles directory..."
    rm -rf "$INSTALL_DIR"
fi

# Clone the repository
log "Cloning dotfiles repository to $INSTALL_DIR..."
git clone "$REPO_URL" "$INSTALL_DIR"

# Change to the dotfiles directory
cd "$INSTALL_DIR"

log "${BOLD}Bootstrap completed successfully!${NC}"
log "Dotfiles are now available in: $INSTALL_DIR"
log "Detected machine: $HOSTNAME"
log ""
log "Next steps:"
log "  1. cd $INSTALL_DIR"
log "  2. Run './sync-system.sh' to install packages and system configs (will use sudo as needed)"
log "  3. Run './sync-user.sh' to install user configs"
log "  4. Review and customize configurations as needed"
log ""
log "${BOLD}Note:${NC} You can now edit your dotfiles directly in $INSTALL_DIR"