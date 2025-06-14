#!/bin/bash

# System Configuration Sync Script
# Run as root to install packages and system configurations
# Usage: ./sync-system.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -r /etc/hostname ]]; then
    HOSTNAME=$(cat /etc/hostname)
elif [[ -n "$HOSTNAME" ]]; then
    HOSTNAME="$HOSTNAME"
else
    HOSTNAME="unknown"
fi

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# Check if we can gain root privileges
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &> /dev/null; then
        error "sudo not available and not running as root. This script requires root privileges for system operations."
    fi
    log "Running as regular user. Will use sudo for system operations."
else
    log "Running as root."
fi

# Check if stow is available
if ! command -v stow &> /dev/null; then
    error "GNU Stow is not installed. Please run bootstrap.sh first."
fi

# Function to run commands with appropriate privileges
run_as_root() {
    if [[ $EUID -eq 0 ]]; then
        # Running as root, execute directly
        "$@"
    else
        # Running as user, use sudo
        sudo "$@"
    fi
}

# Function to cleanup orphaned symlinks pointing to dotfiles
cleanup_orphaned_dotfiles_links() {
    local target_dir="$1"
    local dotfiles_dir="$2"
    local cleaned_count=0
    
    log "Cleaning orphaned dotfiles symlinks in $target_dir..."
    
    # Find broken symlinks and check if they point to our dotfiles directory
    while IFS= read -r -d '' link; do
        if [[ -L "$link" && ! -e "$link" ]]; then
            local link_target
            link_target=$(readlink "$link" 2>/dev/null || echo "")
            
            # Check if symlink points to our dotfiles directory
            if [[ "$link_target" == "$dotfiles_dir"* ]]; then
                log "Removing orphaned symlink: $link -> $link_target"
                if rm "$link" 2>/dev/null; then
                    ((cleaned_count++))
                else
                    warn "Failed to remove orphaned symlink: $link"
                fi
            fi
        fi
    done < <(find "$target_dir" -type l -print0 2>/dev/null)
    
    if [[ $cleaned_count -gt 0 ]]; then
        log "Removed $cleaned_count orphaned dotfiles symlink(s)"
    else
        log "No orphaned dotfiles symlinks found"
    fi
}

log "Starting system configuration sync for machine: $HOSTNAME"
cd "$DOTFILES_DIR"

# Install packages from common list
if [[ -f "packages-common/pacman.txt" && -s "packages-common/pacman.txt" ]]; then
    log "Installing common packages from pacman..."
    run_as_root pacman -S --needed --noconfirm - < packages-common/pacman.txt || warn "Some common pacman packages failed to install"
else
    warn "packages-common/pacman.txt not found or empty"
fi

# Install packages from machine-specific list
if [[ -f "packages-$HOSTNAME/pacman.txt" && -s "packages-$HOSTNAME/pacman.txt" ]]; then
    log "Installing $HOSTNAME-specific packages from pacman..."
    run_as_root pacman -S --needed --noconfirm - < "packages-$HOSTNAME/pacman.txt" || warn "Some $HOSTNAME-specific pacman packages failed to install"
else
    warn "packages-$HOSTNAME/pacman.txt not found or empty"
fi

# Install AUR packages (if yay is available)
if command -v yay &> /dev/null; then
    if [[ -f "packages-common/aur.txt" && -s "packages-common/aur.txt" ]]; then
        log "Installing common AUR packages..."
        yay -S --needed --noconfirm - < packages-common/aur.txt || warn "Some common AUR packages failed to install"
    fi
    
    if [[ -f "packages-$HOSTNAME/aur.txt" && -s "packages-$HOSTNAME/aur.txt" ]]; then
        log "Installing $HOSTNAME-specific AUR packages..."
        yay -S --needed --noconfirm - < "packages-$HOSTNAME/aur.txt" || warn "Some $HOSTNAME-specific AUR packages failed to install"
    fi
else
    warn "yay not found. Skipping AUR package installation."
fi

# Clean orphaned symlinks before stowing
if [[ $EUID -eq 0 ]]; then
    # Running as root, call function directly
    cleanup_orphaned_dotfiles_links "/" "$DOTFILES_DIR"
else
    # Running as user, need to use sudo but export the function and variables
    sudo bash -c "
        GREEN='$GREEN'
        YELLOW='$YELLOW'
        NC='$NC'
        $(declare -f cleanup_orphaned_dotfiles_links log warn)
        cleanup_orphaned_dotfiles_links '/' '$DOTFILES_DIR'
    "
fi

# Stow common system configurations
if [[ -d "system-common" ]]; then
    log "Stowing common system configurations..."
    run_as_root stow -t / --ignore='post-install.d' system-common || error "Failed to stow common system configurations"
else
    warn "system-common directory not found"
fi

# Stow machine-specific system configurations
if [[ -d "system-$HOSTNAME" ]]; then
    log "Stowing $HOSTNAME-specific system configurations..."
    run_as_root stow -t / --ignore='post-install.d' "system-$HOSTNAME" || error "Failed to stow $HOSTNAME-specific system configurations"
else
    warn "system-$HOSTNAME directory not found"
fi

# Execute post-install scripts
run_post_install_scripts() {
    local script_dir="$1"
    local context="$2"
    
    if [[ -d "$script_dir" ]]; then
        log "Running $context post-install scripts..."
        for script in "$script_dir"/*.sh; do
            if [[ -f "$script" && -x "$script" ]]; then
                log "Executing: $(basename "$script")"
                run_as_root "$script" || warn "Post-install script $(basename "$script") failed"
            fi
        done
    fi
}

# Run common post-install scripts
run_post_install_scripts "system-common/post-install.d" "common system"

# Run machine-specific post-install scripts
run_post_install_scripts "system-$HOSTNAME/post-install.d" "$HOSTNAME system"

log "${BOLD}System configuration sync completed!${NC}"
log "Next step: Run './sync-user.sh' to configure user settings"