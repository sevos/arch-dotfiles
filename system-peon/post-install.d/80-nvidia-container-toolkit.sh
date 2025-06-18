#!/bin/bash
# Configure NVIDIA Container Toolkit for Docker GPU support

set -euo pipefail

# Get the dotfiles directory (going up two levels from post-install.d)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source the shared logging library
source "$DOTFILES_DIR/lib/logging.sh"

info "Configuring NVIDIA Container Toolkit for Docker"

# Check if nvidia-container-toolkit is installed
if ! command -v nvidia-ctk &> /dev/null; then
    error "nvidia-container-toolkit not found. Make sure it's installed."
    exit 1
fi

# Configure the container runtime
substep "Configuring Docker runtime for NVIDIA GPU support"
nvidia-ctk runtime configure --runtime=docker

# Restart Docker daemon to apply changes
substep "Restarting Docker daemon"
sudo systemctl restart docker

# Verify Docker daemon is running
if systemctl is-active --quiet docker.service; then
    success "Docker service restarted successfully"
else
    error "Docker service failed to restart"
    exit 1
fi

# Check NVIDIA driver status and test GPU availability
if lsmod | grep nvidia >/dev/null 2>&1; then
    success "NVIDIA drivers are loaded"
    
    # Test GPU availability in containers (as root since user group change requires logout)
    substep "Testing NVIDIA GPU access in Docker"
    if sudo docker run --rm --gpus all nvidia/cuda:12.1.1-runtime-ubuntu22.04 nvidia-smi &>/dev/null; then
        success "NVIDIA GPU container support verified"
    else
        warn "GPU test failed - may need container image download or GPU initialization"
        info "GPU support is configured and should work when containers can access GPU"
    fi
else
    warn "NVIDIA drivers not currently loaded - GPU support configured for when drivers are active"
fi

success "NVIDIA Container Toolkit configuration complete"
info "Use '--gpus all' flag with docker run to enable GPU access"