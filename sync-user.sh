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

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

# Initialize logging with total steps: cleanup, stow-common, stow-hostname, post-install-common, post-install-hostname
init_logging 5

# Check if running as regular user (not root)
if [[ $EUID -eq 0 ]]; then
    die "This script should be run as a regular user, not root"
fi

# Check if stow is available
if ! command -v stow &> /dev/null; then
    die "GNU Stow is not installed. Please run bootstrap.sh first."
fi

[[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && info "Starting user configuration sync for machine: $(highlight "$HOSTNAME")"
[[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && info "Dotfiles repository: $(highlight "$DOTFILES_DIR")"
[[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && info "Target directory: $(highlight "$HOME")"

# Function to cleanup orphaned symlinks pointing to dotfiles
cleanup_orphaned_dotfiles_links() {
    local target_dir="$1"
    local dotfiles_dir="$2"
    local cleaned_count=0
    
    substep "Cleaning orphaned dotfiles symlinks in $target_dir"
    
    # Find broken symlinks and check if they point to our dotfiles directory
    while IFS= read -r -d '' link; do
        if [[ -L "$link" && ! -e "$link" ]]; then
            local link_target
            link_target=$(readlink "$link" 2>/dev/null || echo "")
            
            # Check if symlink points to our dotfiles directory
            if [[ "$link_target" == "$dotfiles_dir"* ]]; then
                debug "Removing orphaned symlink: $link -> $link_target"
                if rm "$link" 2>/dev/null; then
                    cleaned_count=$((cleaned_count + 1))
                else
                    warn "Failed to remove orphaned symlink: $link"
                fi
            fi
        fi
    done < <(find "$target_dir" -type l -print0 2>/dev/null)
    
    if [[ $cleaned_count -gt 0 ]]; then
        success "Removed $cleaned_count orphaned dotfiles symlink(s)"
    else
        info "No orphaned dotfiles symlinks found"
    fi
}

cd "$DOTFILES_DIR"

# Step 1: Clean orphaned symlinks before stowing
step "Cleaning orphaned symlinks"
cleanup_orphaned_dotfiles_links "$HOME" "$DOTFILES_DIR"

# Remove existing bashrc to prevent stow conflicts
if [[ -f "$HOME/.bashrc" ]]; then
    [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Removing existing .bashrc to prevent stow conflicts"
    rm "$HOME/.bashrc"
fi

# Handle mimeapps.list specially - it needs to be adopted if it conflicts
handle_mimeapps_conflict() {
    local mimeapps_target="$HOME/.config/mimeapps.list"
    local mimeapps_source="$DOTFILES_DIR/user-common/.config/mimeapps.list"
    
    if [[ -f "$mimeapps_source" && -f "$mimeapps_target" && ! -L "$mimeapps_target" ]]; then
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Handling mimeapps.list conflict with --adopt"
        # Create backup of existing file
        cp "$mimeapps_target" "$mimeapps_target.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
        return 0  # Signal that we need to use --adopt for this stow operation
    fi
    return 1  # No conflict, proceed normally
}

# Step 2: Stow common user configurations
step "Stowing common user configurations"
if [[ -d "user-common" ]]; then
    [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Stowing common user configurations"
    
    # Check if we need to adopt mimeapps.list
    adopt_flag=""
    if handle_mimeapps_conflict; then
        adopt_flag="--adopt"
    fi
    
    if stow -t "$HOME" --ignore='post-install.d' $adopt_flag user-common; then
        success "Stowed common user configurations"
    else
        die "Failed to stow common user configurations"
    fi
else
    warn "user-common directory not found"
fi

# Step 3: Stow machine-specific user configurations
step "Stowing $HOSTNAME-specific user configurations"
if [[ -d "user-$HOSTNAME" ]]; then
    [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Stowing $HOSTNAME-specific user configurations"
    if stow -t "$HOME" --ignore='post-install.d' "user-$HOSTNAME"; then
        success "Stowed $HOSTNAME-specific user configurations"
    else
        die "Failed to stow $HOSTNAME-specific user configurations"
    fi
else
    warn "user-$HOSTNAME directory not found"
fi

# Execute post-install scripts
run_post_install_scripts() {
    local script_dir="$1"
    local context="$2"
    
    if [[ -d "$script_dir" ]]; then
        substep "Running $context post-install scripts"
        local script_count=0
        local success_count=0
        
        for script in "$script_dir"/*.sh; do
            if [[ -f "$script" && -x "$script" ]]; then
                script_count=$((script_count + 1))
                local script_name=$(basename "$script")
                substep "Executing: $script_name"
                
                local script_start_time=$(date +%s)
                if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
                    if "$script"; then
                        success_count=$((success_count + 1))
                        local script_duration=$(($(date +%s) - script_start_time))
                        success "$script_name completed in $(format_duration $script_duration)"
                    else
                        warn "Post-install script $script_name failed"
                    fi
                else
                    local temp_output=$(mktemp)
                    if "$script" > "$temp_output" 2>&1; then
                        success_count=$((success_count + 1))
                        local script_duration=$(($(date +%s) - script_start_time))
                        success "$script_name completed in $(format_duration $script_duration)"
                    else
                        warn "Post-install script $script_name failed"
                        [[ "$VERBOSITY_LEVEL" != "quiet" ]] && cat "$temp_output"
                    fi
                    rm -f "$temp_output"
                fi
            fi
        done
        
        if [[ $script_count -gt 0 ]]; then
            if [[ $success_count -eq $script_count ]]; then
                success "All $script_count $context post-install scripts completed"
            else
                warn "$success_count of $script_count $context post-install scripts completed"
            fi
        else
            info "No $context post-install scripts found"
        fi
    else
        info "No $context post-install directory found"
    fi
}

# Step 4: Run common post-install scripts
step "Running common post-install scripts"
run_post_install_scripts "user-common/post-install.d" "common user"

# Step 5: Run machine-specific post-install scripts
step "Running $HOSTNAME-specific post-install scripts"
run_post_install_scripts "user-$HOSTNAME/post-install.d" "$HOSTNAME user"

success "User configuration sync completed"
if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
    info "Your dotfiles have been installed to: $(highlight "$HOME")"
fi