# Arch Linux Dotfiles

A collection of configuration files and settings for Arch Linux systems.

## Quick Installation

Run this one-liner to bootstrap the dotfiles on your Arch Linux system:

```bash
curl -fsSL https://raw.githubusercontent.com/sevos/arch-dotfiles/main/bootstrap.sh | bash
```

This will:
- Install git if not already present
- Clone this repository to `/root/dotfiles`
- Set up the basic structure for your dotfiles

## Manual Installation

If you prefer to install manually:

```bash
# Install git if needed
sudo pacman -S git

# Clone the repository
git clone https://github.com/sevos/arch-dotfiles.git /root/dotfiles

# Navigate to the dotfiles directory
cd /root/dotfiles
```

## Structure

```
/root/dotfiles/
├── bootstrap.sh    # Bootstrap installation script
├── CLAUDE.md       # AI assistant instructions
└── README.md       # This file
```

## Usage

After installation, you can:
1. Review and customize the configuration files
2. Create symlinks to your home directory as needed
3. Add your own configuration files to this repository

## Contributing

This is a personal dotfiles repository, but feel free to fork it and adapt it for your own use.

## License

This project is licensed under the MIT License - see the LICENSE file for details.