#!/bin/bash

# Arch Linux Dotfiles Bootstrap Script
# Usage: curl -fsSL https://raw.githubusercontent.com/sevos/arch-dotfiles/main/bootstrap.sh | bash

set -e

REPO_URL="https://github.com/sevos/arch-dotfiles.git"
INSTALL_DIR="/root/dotfiles"
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

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root"
fi

# Check if we're on Arch Linux
if ! command -v pacman &> /dev/null; then
    error "This script is designed for Arch Linux systems only"
fi

log "Starting Arch Linux dotfiles bootstrap..."

# Install git if not present
if ! command -v git &> /dev/null; then
    log "Git not found. Installing git..."
    pacman -Sy --noconfirm git
    log "Git installed successfully"
else
    log "Git is already installed"
fi

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
log ""
log "Next steps:"
log "  1. Review the configuration files"
log "  2. Run any setup scripts as needed"
log "  3. Customize settings to your preferences"