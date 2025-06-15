#!/bin/bash

# User Configuration Sync Script
# Run as regular user to install user configurations
# Usage: ./sync-user.sh

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

# Check if running as regular user (not root)
if [[ $EUID -eq 0 ]]; then
    error "This script should be run as a regular user, not root"
fi

# Check if stow is available
if ! command -v stow &> /dev/null; then
    error "GNU Stow is not installed. Please run bootstrap.sh first."
fi

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

log "Starting user configuration sync for machine: $HOSTNAME"
log "Dotfiles repository: $DOTFILES_DIR"
log "Target directory: $HOME"
cd "$DOTFILES_DIR"

# Clean orphaned symlinks before stowing
cleanup_orphaned_dotfiles_links "$HOME" "$DOTFILES_DIR"

# Remove existing bashrc to prevent stow conflicts
if [[ -f "$HOME/.bashrc" ]]; then
    log "Removing existing .bashrc to prevent stow conflicts"
    rm "$HOME/.bashrc"
fi

# Stow common user configurations
if [[ -d "user-common" ]]; then
    log "Stowing common user configurations..."
    stow -t "$HOME" --ignore='post-install.d' user-common || error "Failed to stow common user configurations"
else
    warn "user-common directory not found"
fi

# Stow machine-specific user configurations
if [[ -d "user-$HOSTNAME" ]]; then
    log "Stowing $HOSTNAME-specific user configurations..."
    stow -t "$HOME" --ignore='post-install.d' "user-$HOSTNAME" || error "Failed to stow $HOSTNAME-specific user configurations"
else
    warn "user-$HOSTNAME directory not found"
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
                "$script" || warn "Post-install script $(basename "$script") failed"
            fi
        done
    fi
}

# Run common post-install scripts
run_post_install_scripts "user-common/post-install.d" "common user"

# Run machine-specific post-install scripts
run_post_install_scripts "user-$HOSTNAME/post-install.d" "$HOSTNAME user"

log "${BOLD}User configuration sync completed!${NC}"
log "Your dotfiles have been installed to: $HOME"