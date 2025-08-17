#!/bin/bash
# Install Playwright browsers (idempotent)

set -e

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Setting up Playwright browsers..."

# Check if python-playwright is available first
if ! python -c "import playwright" 2>/dev/null; then
    warn "python-playwright package not found, install it first with sync-system.sh"
    exit 0
fi

# Check if playwright browsers are already installed by testing if the install command shows they exist
if python -m playwright install --dry-run 2>&1 | grep -q "browsers are already installed"; then
    success "Playwright browsers already installed"
else
    processing "Installing Playwright browsers (Chromium, Firefox, WebKit)..."
    substep "This will download approximately 500MB of browser binaries"
    python -m playwright install
    success "Playwright browsers installed successfully"
    substep "Browsers installed in: $(python -c 'import playwright; print(playwright.__file__.replace("/__init__.py", "/browsers"))')"
fi

# Install system dependencies if needed
processing "Installing system dependencies for Playwright..."
if command -v pacman >/dev/null 2>&1; then
    # On Arch Linux, install basic dependencies that Playwright browsers need
    sudo pacman -S --needed --noconfirm \
        libxcomposite libxdamage libxrandr \
        libxss libnss alsa-lib libxft \
        libxkbcommon ttf-liberation \
        glibc gtk3 2>/dev/null || true
    success "System dependencies installed"
else
    # For non-Arch systems, use playwright's built-in installer
    python -m playwright install-deps 2>/dev/null || warn "Could not install system dependencies automatically"
fi

success "Playwright setup complete"
substep "You can now use Playwright with Python scripts or tests"