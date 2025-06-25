#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/../../lib/logging.sh"

if [[ -z "${SUDO_USER:-}" ]]; then
    log_error "This script must be run with sudo"
    exit 1
fi

if groups "$SUDO_USER" | grep -q '\binput\b'; then
    log_info "User $SUDO_USER is already in the input group"
else
    log_info "Adding user $SUDO_USER to the input group"
    usermod -a -G input "$SUDO_USER"
    log_success "User $SUDO_USER added to input group"
fi