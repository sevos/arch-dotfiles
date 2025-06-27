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

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

# Initialize logging with total steps: update+multilib, packages-common, packages-hostname, aur-common, aur-hostname, stow-common, stow-hostname, post-install-common, post-install-hostname
init_logging 10

debug "sync-system.sh started successfully"

# Check if we can gain root privileges
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &> /dev/null; then
        die "sudo not available and not running as root. This script requires root privileges for system operations."
    fi
    debug "Running as regular user with sudo for system operations"
else
    debug "Running as root"
fi

# Check if stow is available
if ! command -v stow &> /dev/null; then
    die "GNU Stow is not installed. Please run bootstrap.sh first."
fi

[[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && info "Starting system configuration sync for machine: $(highlight "$HOSTNAME")"

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
    
    substep "Cleaning orphaned dotfiles symlinks in $target_dir"
    
    # Find broken symlinks and check if they point to our dotfiles directory
    # Use timeout to prevent hanging
    local temp_file=$(mktemp)
    # Only search directories where dotfiles creates symlinks
    local search_dirs=("/etc" "/usr" "/post-install.d")
    
    # Build find command for specific directories only
    local find_cmd=()
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            find_cmd+=("$dir")
        fi
    done
    
    if [[ ${#find_cmd[@]} -gt 0 ]] && timeout 60 find "${find_cmd[@]}" -type l -print0 2>/dev/null > "$temp_file"; then
        while IFS= read -r -d '' link; do
            if [[ -L "$link" && ! -e "$link" ]]; then
                local link_target
                link_target=$(readlink "$link" 2>/dev/null || echo "")
                
                # Resolve the absolute path of the symlink target
                local abs_link_target=""
                if [[ -n "$link_target" ]]; then
                    # Get the directory containing the symlink
                    local link_dir=$(dirname "$link")
                    # Try to resolve the absolute path (even if target doesn't exist)
                    abs_link_target=$(cd "$link_dir" 2>/dev/null && realpath -m "$link_target" 2>/dev/null || echo "")
                fi
                
                # Check if symlink points to our dotfiles directory (either relative or absolute)
                if [[ "$link_target" == *"$dotfiles_dir"* ]] || [[ "$abs_link_target" == "$dotfiles_dir"* ]]; then
                    debug "Removing orphaned symlink: $link -> $link_target"
                    if run_as_root rm "$link" 2>/dev/null; then
                        ((cleaned_count++))
                    else
                        warn "Failed to remove orphaned symlink: $link"
                    fi
                fi
            fi
        done < "$temp_file"
    else
        warn "Cleanup operation timed out or failed"
    fi
    rm -f "$temp_file"
    
    if [[ $cleaned_count -gt 0 ]]; then
        success "Removed $cleaned_count orphaned dotfiles symlink(s)"
    else
        info "No orphaned dotfiles symlinks found"
    fi
}

cd "$DOTFILES_DIR"

# Function to ensure multilib repository is enabled
ensure_multilib_enabled() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        substep "Enabling multilib repository"
        
        # Create a backup of pacman.conf
        run_as_root cp /etc/pacman.conf /etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Enable multilib by uncommenting the section
        run_as_root sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ {
            s/^#\[multilib\]/[multilib]/
            s/^#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/
        }' /etc/pacman.conf
        
        success "Multilib repository enabled"
    else
        substep "Multilib repository already enabled"
    fi
}

# Step 1: Check multilib and update system
step "Updating system packages"
ensure_multilib_enabled
if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
    run_cmd "Updating pacman database and packages" run_as_root pacman -Syu --noconfirm
else
    # Silent update in normal mode
    run_as_root pacman -Syu --noconfirm >/dev/null 2>&1 || die "System update failed"
fi

# Step 2: Install common pacman packages
step "Installing common packages"
if [[ -f "packages-common/pacman.txt" && -s "packages-common/pacman.txt" ]]; then
    package_count=$(wc -l < packages-common/pacman.txt)
    substep "Installing $package_count common packages from pacman"
    
    if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
        run_as_root pacman -S --needed --noconfirm - < packages-common/pacman.txt || warn "Some common pacman packages failed to install"
    else
        temp_output=$(mktemp)
        if run_as_root pacman -S --needed --noconfirm - < packages-common/pacman.txt > "$temp_output" 2>&1; then
            # Count actual operations from output
            installed=$(grep -E "installing|upgrading" "$temp_output" 2>/dev/null | wc -l || echo "0")
            up_to_date=$(grep "is up to date" "$temp_output" 2>/dev/null | wc -l || echo "0")
            package_summary "$package_count" "$installed" "0" "$up_to_date"
        else
            error "Some common pacman packages failed to install"
            [[ "$VERBOSITY_LEVEL" != "quiet" ]] && cat "$temp_output"
        fi
        rm -f "$temp_output"
    fi
else
    warn "packages-common/pacman.txt not found or empty"
fi

# Step 3: Install machine-specific pacman packages  
step "Installing $HOSTNAME-specific packages"
if [[ -f "packages-$HOSTNAME/pacman.txt" && -s "packages-$HOSTNAME/pacman.txt" ]]; then
    package_count=$(wc -l < "packages-$HOSTNAME/pacman.txt")
    substep "Installing $package_count $HOSTNAME-specific packages from pacman"
    
    if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
        run_as_root pacman -S --needed --noconfirm - < "packages-$HOSTNAME/pacman.txt" || warn "Some $HOSTNAME-specific pacman packages failed to install"
    else
        temp_output=$(mktemp)
        if run_as_root pacman -S --needed --noconfirm - < "packages-$HOSTNAME/pacman.txt" > "$temp_output" 2>&1; then
            installed=$(grep -E "installing|upgrading" "$temp_output" 2>/dev/null | wc -l || echo "0")
            up_to_date=$(grep "is up to date" "$temp_output" 2>/dev/null | wc -l || echo "0") 
            package_summary "$package_count" "$installed" "0" "$up_to_date"
        else
            error "Some $HOSTNAME-specific pacman packages failed to install"
            [[ "$VERBOSITY_LEVEL" != "quiet" ]] && cat "$temp_output"
        fi
        rm -f "$temp_output"
    fi
else
    warn "packages-$HOSTNAME/pacman.txt not found or empty"
fi

# Step 4: Install common AUR packages
step "Installing common AUR packages"
if command -v yay &> /dev/null; then
    # Check if mise Python is in PATH and temporarily remove it for AUR builds
    ORIGINAL_PATH="$PATH"
    if command -v mise &> /dev/null && python --version 2>&1 | grep -q "Python" && which python | grep -q "mise"; then
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Detected mise-managed Python, temporarily using system Python for AUR builds"
        # Remove mise paths from PATH
        NEW_PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "mise" | tr '\n' ':' | sed 's/:$//')
        export PATH="$NEW_PATH"
        debug "Using system Python for AUR builds: $(which python 2>/dev/null || echo 'none found')"
    fi
    
    if [[ -f "packages-common/aur.txt" && -s "packages-common/aur.txt" ]]; then
        # Filter out empty lines and comments, then install
        packages=$(grep -v '^#' packages-common/aur.txt | grep -v '^$' | tr '\n' ' ')
        if [[ -n "$packages" ]]; then
            package_count=$(echo "$packages" | wc -w)
            substep "Installing $package_count common AUR packages"
            
            if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
                info "AUR packages: $packages"
                yay -S --needed --noconfirm $packages || die "Failed to install common AUR packages"
            else
                temp_output=$(mktemp)
                if yay -S --needed --noconfirm $packages > "$temp_output" 2>&1; then
                    installed=$(grep -E "installing|upgrading" "$temp_output" 2>/dev/null | wc -l || echo "0")
                    up_to_date=$(grep "is up to date" "$temp_output" 2>/dev/null | wc -l || echo "0")
                    package_summary "$package_count" "$installed" "0" "$up_to_date"
                else
                    error "Failed to install common AUR packages"
                    [[ "$VERBOSITY_LEVEL" != "quiet" ]] && cat "$temp_output"
                fi
                rm -f "$temp_output"
            fi
        else
            info "No AUR packages to install (common)"
        fi
    else
        info "No common AUR packages file found"
    fi
else
    warn "yay not found. Skipping AUR package installation."
fi

# Step 5: Install machine-specific AUR packages
step "Installing $HOSTNAME-specific AUR packages"
if command -v yay &> /dev/null; then
    if [[ -f "packages-$HOSTNAME/aur.txt" && -s "packages-$HOSTNAME/aur.txt" ]]; then
        # Filter out empty lines and comments, then install
        packages=$(grep -v '^#' "packages-$HOSTNAME/aur.txt" | grep -v '^$' | tr '\n' ' ')
        if [[ -n "$packages" ]]; then
            package_count=$(echo "$packages" | wc -w)
            substep "Installing $package_count $HOSTNAME-specific AUR packages"
            
            if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
                info "AUR packages: $packages"
                yay -S --needed --noconfirm $packages || die "Failed to install $HOSTNAME-specific AUR packages"
            else
                temp_output=$(mktemp)
                if yay -S --needed --noconfirm $packages > "$temp_output" 2>&1; then
                    installed=$(grep -E "installing|upgrading" "$temp_output" 2>/dev/null | wc -l || echo "0")
                    up_to_date=$(grep "is up to date" "$temp_output" 2>/dev/null | wc -l || echo "0")
                    package_summary "$package_count" "$installed" "0" "$up_to_date"
                else
                    error "Failed to install $HOSTNAME-specific AUR packages"
                    [[ "$VERBOSITY_LEVEL" != "quiet" ]] && cat "$temp_output"
                fi
                rm -f "$temp_output"
            fi
        else
            info "No AUR packages to install ($HOSTNAME-specific)"
        fi
    else
        info "No $HOSTNAME-specific AUR packages file found"
    fi
    
    # Restore original PATH if it was modified for AUR builds
    if [[ -n "$ORIGINAL_PATH" && "$PATH" != "$ORIGINAL_PATH" ]]; then
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Restoring original PATH after AUR builds"
        export PATH="$ORIGINAL_PATH"
    fi
else
    info "Skipping $HOSTNAME-specific AUR packages (yay not available)"
fi

# Step 6: Clean orphaned symlinks
step "Cleaning orphaned symlinks"
if [[ $EUID -eq 0 ]]; then
    # Running as root, call function directly
    cleanup_orphaned_dotfiles_links "/" "$DOTFILES_DIR"
else
    # Running as user, need to use sudo but export the function and variables
    sudo bash -c "
        source '$DOTFILES_DIR/lib/logging.sh'
        $(declare -f cleanup_orphaned_dotfiles_links run_as_root)
        cleanup_orphaned_dotfiles_links '/' '$DOTFILES_DIR'
    "
fi

# Function to stow with adopt and selective reset
stow_with_adopt() {
    local stow_dir="$1"
    local stow_type="$2"
    
    # Check if directory is a git repo for selective reset
    if [[ -d ".git" ]]; then
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Recording modified files before stowing $stow_type configurations"
        # Create temp directory for tracking
        local temp_dir=$(mktemp -d)
        
        # Record currently modified files
        git diff --name-only > "$temp_dir/pre-adopt-modified.txt" 2>/dev/null || true
        git diff --staged --name-only >> "$temp_dir/pre-adopt-modified.txt" 2>/dev/null || true
        
        # Stow with adopt to handle conflicts
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Stowing $stow_type configurations with --adopt"
        if run_as_root stow -t / --adopt --ignore='post-install.d' "$stow_dir"; then
            # Check for newly adopted files
            git diff --name-only > "$temp_dir/post-adopt-modified.txt" 2>/dev/null || true
            
            # Find files that were adopted (modified after stow but not before)
            if [[ -s "$temp_dir/post-adopt-modified.txt" ]]; then
                local adopted_files=$(comm -13 <(sort "$temp_dir/pre-adopt-modified.txt" 2>/dev/null) <(sort "$temp_dir/post-adopt-modified.txt") 2>/dev/null || true)
                
                if [[ -n "$adopted_files" ]]; then
                    [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Resetting adopted files to repository versions"
                    echo "$adopted_files" | while IFS= read -r file; do
                        if [[ -n "$file" ]]; then
                            if git checkout -- "$file" 2>/dev/null; then
                                debug "Reset: $file"
                            else
                                warn "Failed to reset: $file"
                            fi
                        fi
                    done
                    
                    # Restow to ensure symlinks point to our configs
                    [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Restowing $stow_type configurations"
                    run_as_root stow -R -t / --ignore='post-install.d' "$stow_dir" || warn "Failed to restow $stow_type configurations"
                fi
            fi
            success "Stowed $stow_type configurations"
        else
            die "Failed to stow $stow_type configurations"
        fi
        
        # Cleanup
        rm -rf "$temp_dir"
    else
        # Not a git repo, use standard stow
        [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]] && substep "Stowing $stow_type configurations"
        run_as_root stow -t / --ignore='post-install.d' "$stow_dir" || die "Failed to stow $stow_type configurations"
        success "Stowed $stow_type configurations"
    fi
}

# Step 7: Stow common system configurations
step "Stowing common system configurations"
if [[ -d "system-common" ]]; then
    stow_with_adopt "system-common" "common system"
else
    warn "system-common directory not found"
fi

# Step 8: Stow machine-specific system configurations
step "Stowing $HOSTNAME-specific system configurations"
if [[ -d "system-$HOSTNAME" ]]; then
    stow_with_adopt "system-$HOSTNAME" "$HOSTNAME-specific system"
else
    warn "system-$HOSTNAME directory not found"
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
                    if run_as_root "$script"; then
                        success_count=$((success_count + 1))
                        local script_duration=$(($(date +%s) - script_start_time))
                        success "$script_name completed in $(format_duration $script_duration)"
                    else
                        warn "Post-install script $script_name failed"
                    fi
                else
                    local temp_output=$(mktemp)
                    if run_as_root "$script" > "$temp_output" 2>&1; then
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

# Step 9: Run common post-install scripts
step "Running common post-install scripts"
run_post_install_scripts "system-common/post-install.d" "common system"

# Step 10: Run machine-specific post-install scripts
step "Running $HOSTNAME-specific post-install scripts"
run_post_install_scripts "system-$HOSTNAME/post-install.d" "$HOSTNAME system"

success "System configuration sync completed"
if [[ "$VERBOSITY_LEVEL" == "verbose" || "$VERBOSITY_LEVEL" == "debug" ]]; then
    info "Next step: Run $(highlight './sync-user.sh') to configure user settings"
fi