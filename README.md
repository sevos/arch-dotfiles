# Arch Linux Dotfiles

A collection of configuration files and settings for Arch Linux systems.

## Quick Installation

Run this one-liner to bootstrap the dotfiles on your Arch Linux system:

```bash
curl -fsSL https://raw.githubusercontent.com/sevos/arch-dotfiles/main/bootstrap.sh | bash
```

This will:
- Install git and stow if not already present (using sudo if needed)
- Clone this repository to `~/.dotfiles`
- Detect your machine hostname (tuxedo/peon)
- Allow you to edit your dotfiles directly in your home directory

## Manual Installation

If you prefer to install manually:

```bash
# Install dependencies (as root or with sudo)
sudo pacman -S git stow

# Clone the repository to your home directory
git clone https://github.com/sevos/arch-dotfiles.git ~/.dotfiles

# Navigate to the dotfiles directory
cd ~/.dotfiles
```

## Structure

```
~/.dotfiles/
├── bootstrap.sh              # Bootstrap installation script
├── sync-system.sh           # System configuration sync (uses sudo as needed)
├── sync-user.sh             # User configuration sync
├── packages-common/         # Common package lists
│   ├── pacman.txt          # Official packages
│   └── aur.txt             # AUR packages
├── packages-{hostname}/     # Machine-specific packages
├── system-common/           # Common system configs (stow to /)
│   ├── etc/                # System configuration files
│   └── post-install.d/     # Post-install scripts
├── system-{hostname}/       # Machine-specific system configs
├── user-common/             # Common user configs (stow to ~)
│   ├── .config/            # User configuration files
│   └── post-install.d/     # Post-install scripts
├── user-{hostname}/         # Machine-specific user configs
└── README.md               # This file
```

## Usage

After bootstrap, configure your system:

### System Configuration
```bash
cd ~/.dotfiles
./sync-system.sh
```

This will:
- Install packages from common and machine-specific lists (using sudo)
- Stow system configurations to `/` (using sudo)
- Run system post-install scripts (using sudo)

### User Configuration
```bash
cd ~/.dotfiles
./sync-user.sh
```

This will:
- Stow user configurations to `~`
- Run user post-install scripts

## Editing Your Dotfiles

With the new user-centric approach, you can now easily edit your dotfiles:

```bash
cd ~/.dotfiles
# Edit any configuration files directly
vim user-common/.config/nvim/init.lua
# Commit your changes
git add .
git commit -m "Update neovim config"
```

## Machine Support

Currently supports:
- `tuxedo` - Machine-specific configurations
- `peon` - Machine-specific configurations

Common configurations are applied to all machines.

## Contributing

This is a personal dotfiles repository, but feel free to fork it and adapt it for your own use.

## License

This project is licensed under the MIT License - see the LICENSE file for details.