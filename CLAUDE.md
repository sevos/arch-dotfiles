# Arch Linux Dotfiles Project

This repository contains configuration files and settings for Arch Linux systems.

## Project Structure

- `bootstrap.sh` - Bootstrap script for one-liner installation
- `README.md` - Project documentation and usage instructions
- Configuration files and dotfiles will be added as the project grows

## Development Guidelines

- All shell scripts should be executable and include proper error handling
- Use consistent formatting and follow shell scripting best practices
- Test bootstrap script on clean Arch Linux installations
- Keep configuration files organized by application/service

## Installation Target

- Target directory: `/root/dotfiles`
- Requires root access for installation
- Designed specifically for Arch Linux systems

## Bootstrap Script Features

- Checks for root privileges
- Validates Arch Linux environment
- Installs git if not present
- Clones repository to target directory
- Provides clear feedback and next steps