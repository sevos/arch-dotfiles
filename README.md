# Arch Linux Dotfiles

A collection of configuration files and settings for Arch Linux systems.

## Quick Installation

Run this one-liner to bootstrap the dotfiles on your Arch Linux system:

```bash
curl -fsSL https://raw.githubusercontent.com/sevos/arch-dotfiles/main/bootstrap.sh | bash
```

This will:
- Install git and stow if not already present
- Clone this repository to `/root/dotfiles`
- Detect your machine hostname (tuxedo/peon)

## Manual Installation

If you prefer to install manually:

```bash
# Install dependencies
pacman -S git stow

# Clone the repository
git clone https://github.com/sevos/arch-dotfiles.git /root/dotfiles

# Navigate to the dotfiles directory
cd /root/dotfiles
```

## Structure

```
/root/dotfiles/
├── bootstrap.sh              # Bootstrap installation script
├── sync-system.sh           # System configuration sync (run as root)
├── sync-user.sh             # User configuration sync (run as user)
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

### System Configuration (as root)
```bash
cd /root/dotfiles
./sync-system.sh
```

This will:
- Install packages from common and machine-specific lists
- Stow system configurations to `/`
- Run post-install scripts

### User Configuration (as regular user)
```bash
cd /root/dotfiles
./sync-user.sh
```

This will:
- Stow user configurations to `~`
- Run user post-install scripts

## Machine Support

Currently supports:
- `tuxedo` - Machine-specific configurations
- `peon` - Machine-specific configurations

Common configurations are applied to all machines.

## Contributing

This is a personal dotfiles repository, but feel free to fork it and adapt it for your own use.

## License

This project is licensed under the MIT License - see the LICENSE file for details.