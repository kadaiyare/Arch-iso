#!/usr/bin/env bash
# Install packages from packages.txt

set -euo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

PACKAGES_FILE="/root/packages.txt"

install_packages() {
    log_info "=== Package installation start ==="
    if [ ! -f "$PACKAGES_FILE" ]; then
        log_error "Package list not found: ${PACKAGES_FILE}"
        exit 1
    fi
    local packages
    packages=$(grep -v '^#' "$PACKAGES_FILE" | grep -v '^$' | tr '\n' ' ')
    log_info "Packages to install: $(echo $packages | wc -w)"
    log_info "Installing packages (this may take a while)..."
    arch-chroot /mnt pacman -S --noconfirm $packages || {
        log_error "Some packages failed to install"
        log_warn "Continuing..."
    }
    log_info "Updating font cache..."
    arch-chroot /mnt fc-cache -fv || log_warn "fc-cache failed"
    log_info "✓ Package installation complete"
}

main() { install_packages; }
main "$@"
