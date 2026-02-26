#!/usr/bin/env bash
# Base system installation script

set -euo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

install_base_system() {
    log_info "Optimizing mirror list..."
    reflector --country Japan --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist \
        || log_warn "reflector failed, using default mirrors"
    log_info "Installing base packages (this may take a while)..."
    pacstrap -K /mnt base linux linux-firmware base-devel
    log_info "✓ Base system installed"
}

generate_fstab() {
    log_info "Generating fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
    log_info "✓ fstab generated"
}

install_essential_tools() {
    log_info "Installing essential tools..."
    arch-chroot /mnt pacman -S --noconfirm networkmanager sudo git vim dialog reflector
    log_info "✓ Essential tools installed"
}

main() {
    log_info "=== Base system install start ==="
    install_base_system
    generate_fstab
    install_essential_tools
    log_info "=== Base system install complete ==="
}
main "$@"
