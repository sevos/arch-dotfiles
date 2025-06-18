#!/bin/bash
# Configure NVIDIA Container Toolkit for Docker GPU support

set -euo pipefail

echo "Configuring NVIDIA Container Toolkit for Docker..."

# Check if nvidia-container-toolkit is installed
if ! command -v nvidia-ctk &> /dev/null; then
    echo "✗ nvidia-container-toolkit not found. Make sure it's installed."
    exit 1
fi

# Configure the container runtime
echo "Configuring Docker runtime for NVIDIA GPU support..."
nvidia-ctk runtime configure --runtime=docker

# Restart Docker daemon to apply changes
echo "Restarting Docker daemon..."
sudo systemctl restart docker

# Verify Docker daemon is running
if systemctl is-active --quiet docker.service; then
    echo "✓ Docker service restarted successfully"
else
    echo "✗ Docker service failed to restart"
    exit 1
fi

# Check NVIDIA driver status and test GPU availability
if lsmod | grep nvidia >/dev/null 2>&1; then
    echo "✓ NVIDIA drivers are loaded"
    
    # Test GPU availability in containers (as root since user group change requires logout)
    echo "Testing NVIDIA GPU access in Docker..."
    if sudo docker run --rm --gpus all nvidia/cuda:12.1.1-runtime-ubuntu22.04 nvidia-smi &>/dev/null; then
        echo "✓ NVIDIA GPU container support verified"
    else
        echo "⚠ GPU test failed - may need container image download or GPU initialization"
        echo "  GPU support is configured and should work when containers can access GPU"
    fi
else
    echo "⚠ NVIDIA drivers not currently loaded - GPU support configured for when drivers are active"
fi

echo "✓ NVIDIA Container Toolkit configuration complete"
echo "  Use '--gpus all' flag with docker run to enable GPU access"