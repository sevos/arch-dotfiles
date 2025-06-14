# Arch Linux Dotfiles Project

GNU Stow-based dotfiles management for Arch Linux systems with multi-machine support.

## Architecture

### Core Components
- **GNU Stow**: Symlink farm manager for configuration files
- **Machine Detection**: Hostname-based configuration (tuxedo/peon)
- **Package Management**: Separate pacman and AUR package lists
- **Post-Install Scripts**: Idempotent configuration scripts

### Directory Structure
- `packages-{common,hostname}/` - Package lists (pacman.txt, aur.txt)
- `system-{common,hostname}/` - System configs (stow to `/`)
- `user-{common,hostname}/` - User configs (stow to `~`)
- `post-install.d/` - Executable scripts run after stowing

## Scripts

### bootstrap.sh
- Installs git and stow dependencies
- Detects hostname for machine-specific configs
- Clones repository to `/root/dotfiles`
- Root privilege validation

### sync-system.sh (run as root)
- Installs packages from common + machine-specific lists
- Stows system configurations to `/`
- Executes system post-install scripts

### sync-user.sh (run as regular user)
- Stows user configurations to `~`
- Executes user post-install scripts
- User privilege validation (prevents root execution)

## Development Guidelines

- Keep directory structure minimal and functional
- Use .keep files for empty directories
- All scripts include proper error handling and logging
- Post-install scripts must be idempotent
- Package lists: one package per line, comments allowed
- Test on clean Arch installations before deployment