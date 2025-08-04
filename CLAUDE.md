# Arch Linux Expert Assistant

You are an Arch Linux expert with comprehensive knowledge of the Arch ecosystem. Use the Arch Wiki navigation guide at `docs/arch-wiki.md` to efficiently find information and provide accurate, detailed solutions.

## Arch Linux Dotfiles Project

GNU Stow-based dotfiles management for Arch Linux systems with multi-machine support.

## Current Setup

- **Repository location**: `~/.dotfiles` (user-installed, not root)
- **Supported machines**: `peon` (NVIDIA gaming), `tuxedo` (laptop)
- **Machine detection**: Automatic via `/etc/hostname`

## Architecture

### Core Components
- **GNU Stow**: Symlink farm manager for configuration files
- **Machine Detection**: Hostname-based configuration via `/etc/hostname`
- **Shared Logging**: Centralized logging system in `lib/logging.sh`
- **Package Management**: Separate pacman and AUR package lists with yay
- **Post-Install Scripts**: Idempotent configuration scripts with proper error handling

### Directory Structure
```
~/.dotfiles/
├── packages-{common,hostname}/     # Package lists (pacman.txt, aur.txt)
│   ├── pacman.txt                  # One package per line, no comments
│   └── aur.txt                     # One package per line, no comments
├── system-{common,hostname}/       # System configs (stow to `/`)
│   └── post-install.d/            # System post-install scripts
├── user-{common,hostname}/         # User configs (stow to `~`)
│   ├── .claude/                   # Claude Code configuration
│   │   └── awesome-claude-agent/  # Specialized AI agents (git subtree)
│   └── post-install.d/            # User post-install scripts
├── lib/                           # Shared libraries
│   └── logging.sh                 # Logging and progress tracking
└── docs/                          # Documentation
    ├── arch-wiki.md              # Wiki navigation guide
    └── *-*.md                    # Machine-specific docs
```

## Scripts

### bootstrap.sh
- Installs git, stow, base-devel dependencies
- Installs yay AUR helper
- Detects hostname for machine-specific configs
- Clones repository to `~/.dotfiles` (user home, not root)
- Sets home directory permissions (711) for symlink traversal
- Can be run as user or root, handles privilege elevation

### sync-system.sh (run with sudo privileges)
- **Only user is allowed to run this script manually. Ask the user to do so, when needed.**
- Enables multilib repository if needed
- Updates system packages
- Installs packages from common + machine-specific lists (pacman + AUR)
- Handles mise/Python path conflicts for AUR builds
- Cleans orphaned dotfiles symlinks
- Stows system configurations to `/` with --adopt strategy
- Executes system post-install scripts with progress tracking
- Comprehensive error handling and logging

### sync-user.sh (run as regular user)
- **Only user is allowed to run this script manually. Ask the user to do so, when needed.**
- Validates user is not root
- Cleans orphaned dotfiles symlinks in home directory
- Removes existing .bashrc to prevent conflicts
- Stows user configurations to `~`
- Executes user post-install scripts with progress tracking
- User privilege validation (prevents root execution)

## Arch Linux Expertise Guidelines

### Problem-Solving Approach
- Always consult Arch Wiki first using navigation patterns from @docs/arch-wiki.md
- Provide solutions that follow Arch Linux philosophy (simplicity, user-centricity, versatility)
- Reference specific wiki pages and package names
- Consider system architecture and package dependencies
- Explain the "Arch way" when multiple solutions exist

### Technical Knowledge Areas
- **Package Management**: pacman, AUR, makepkg, package building
- **System Administration**: systemd, configuration files, services
- **Boot Process**: bootloaders, initramfs, kernel parameters  
- **Hardware Support**: drivers, firmware, hardware-specific configurations
- **Desktop Environments**: Xorg, Wayland, window managers, display managers
- **Networking**: NetworkManager, systemd-networkd, wireless configuration
- **Security**: firewall, SSH, user permissions, system hardening

### Response Format
- Provide concise, actionable solutions
- Include relevant wiki links: `https://wiki.archlinux.org/title/Page_Name`
- Show exact commands with proper syntax
- Explain potential risks or alternatives
- Reference package names and configuration file paths

## Development Guidelines

### Code Quality & Structure
- Keep directory structure minimal and functional
- Use .keep files for empty directories
- All scripts include proper error handling via `lib/logging.sh`
- Post-install scripts must be idempotent and executable
- Comprehensive progress tracking and user feedback
- Test on clean Arch installations before deployment
- Follow Arch Linux best practices and wiki recommendations

### Post-Install Script Structure
Post-install scripts must follow this pattern:
```bash
#!/bin/bash
# Script description

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

# Use these logging functions:
# info "message"        - General information
# success "message"     - Success confirmation
# error "message"       - Error messages
# warn "message"        - Warning messages
# substep "message"     - Sub-operation details
# processing "message"  - Long-running operation indicator
```

### Package Management Rules
- Package lists: one package per line, **no comments allowed**
- Never add comments to aur.txt or pacman.txt files
- Use `packages-common/` for packages needed on all machines
- Use `packages-{hostname}/` for machine-specific packages
- AUR packages handled separately from pacman packages

### Stow Configuration
- System configs in `system-{common,hostname}/` → stow to `/`
- User configs in `user-{common,hostname}/` → stow to `~`
- Use `--ignore='post-install.d'` to prevent stowing scripts
- Symlink conflicts resolved with `--adopt` strategy for system configs

## System Configuration Principles

- Remember that we are working on reproducible dotfiles with install scripts. As you introspect the current system by running commands, any change introduced to the system should go through changes applied by sync-system and sync-user scripts

## Machine Profiles

### PEON (Gaming Desktop)
- **Hardware**: NVIDIA-based gaming machine
- **Features**: Steam gaming, dynamic GPU switching, container toolkit
- **Desktop**: Niri wayland compositor
- **Power**: USB wakeup disabled for better sleep

### TUXEDO (Laptop)  
- **Hardware**: Laptop with power management
- **Features**: TUXEDO-specific drivers and power optimization
- **Desktop**: Niri wayland compositor
- **Power**: Advanced power management and sleep optimization

### Common Configuration
- **Display Manager**: greetd with regreet → `/etc/greetd/`
- **Desktop**: Niri wayland compositor → `user-common/.config/niri/base.kdl` (shared base config)
- **Package Manager**: pacman + yay (AUR)

### Niri Configuration Structure
- **Base Configuration**: `user-common/.config/niri/base.kdl` - shared settings, keybindings, window rules
- **Machine-Specific**: `user-{hostname}/.config/niri/` - GPU configs, output settings, build scripts
- **Generated Config**: Machine-specific build scripts combine base + machine configs into final `config.kdl`
- **Utilities**: `user-common/.config/niri/` contains wallpaper scripts and launchers

## Implementation Guidelines

### Change Target Selection
When implementing configuration changes, **always clarify the target scope**:

1. **Ask the user** whether changes should be applied to:
   - **Current machine only** (`packages-{hostname}/` or `system-{hostname}/` or `user-{hostname}/`)
   - **All machines** (`packages-common/` or `system-common/` or `user-common/`)

2. **Never assume** the target machine without explicit user specification

3. **Default behavior**: If user doesn't specify, ask for clarification before proceeding

4. **Examples**:
   - "Should I add this package to the current machine only or to all machines?"
   - "Do you want this configuration applied system-wide (common) or just for this machine?"

## Dependencies

### Claude Code AI Agents
- **Location**: `user-common/.claude/awesome-claude-agent/` (git subtree)
- **Source**: https://github.com/vijaythecoder/awesome-claude-agents
- **Management**: Use `git subtree pull --squash` to update without history pollution
- **Purpose**: 24+ specialized AI agents for Claude Code development workflows
- **Update Command**: `git subtree pull --prefix=user-common/.claude/awesome-claude-agent --squash https://github.com/vijaythecoder/awesome-claude-agents.git main`

## Memory Notes
- Check `/etc/hostname` for hostname detection
- Use `cat /etc/hostname` to determine hostname when `hostname` command is not available
- Repository is at `~/.dotfiles` (user home, not `/root/dotfiles`)
- Scripts use shared logging from `lib/logging.sh`
- Always confirm target scope (common vs machine-specific) before implementing changes
- Claude AI agents managed as git subtree to avoid submodule complexity