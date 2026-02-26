#!/usr/bin/env bash
# systemd-boot setup script

set -euo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

install_systemd_boot() {
    log_info "Installing systemd-boot..."
    arch-chroot /mnt bootctl install
    log_info "✓ systemd-boot installed"
}

create_loader_config() {
    log_info "Creating loader config..."
    cat > /mnt/boot/loader/loader.conf <<'CONF'
default  arch.conf
timeout  3
console-mode max
editor   no
CONF
    log_info "✓ Loader config created"
}

install_microcode() {
    if lscpu | grep -q "GenuineIntel"; then
        log_info "Intel CPU detected: installing intel-ucode"
        arch-chroot /mnt pacman -S --noconfirm intel-ucode
    elif lscpu | grep -q "AuthenticAMD"; then
        log_info "AMD CPU detected: installing amd-ucode"
        arch-chroot /mnt pacman -S --noconfirm amd-ucode
    else
        log_warn "CPU vendor unknown, skipping microcode"
    fi
}

create_boot_entry() {
    log_info "Creating boot entry..."
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "${ROOT_PARTITION}")

    if [ -z "$root_uuid" ]; then
        log_error "Could not detect root partition UUID!"
        exit 1
    fi
    log_info "Root UUID: ${root_uuid}"

    # microcode initrd line (only if the file actually exists)
    local microcode_line=""
    if [ -f /mnt/boot/intel-ucode.img ]; then
        microcode_line="initrd  /intel-ucode.img"
    elif [ -f /mnt/boot/amd-ucode.img ]; then
        microcode_line="initrd  /amd-ucode.img"
    fi

    {
        echo "title   Arch Linux"
        echo "linux   /vmlinuz-linux"
        [ -n "$microcode_line" ] && echo "$microcode_line"
        echo "initrd  /initramfs-linux.img"
        echo "options root=UUID=${root_uuid} rw quiet"
    } > /mnt/boot/loader/entries/arch.conf

    log_info "Boot entry:"
    cat /mnt/boot/loader/entries/arch.conf
    log_info "✓ Boot entry created"
}

create_fallback_entry() {
    log_info "Creating fallback boot entry..."
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "${ROOT_PARTITION}")

    local microcode_line=""
    [ -f /mnt/boot/intel-ucode.img ] && microcode_line="initrd  /intel-ucode.img"
    [ -f /mnt/boot/amd-ucode.img ]   && microcode_line="initrd  /amd-ucode.img"

    {
        echo "title   Arch Linux (fallback)"
        echo "linux   /vmlinuz-linux"
        [ -n "$microcode_line" ] && echo "$microcode_line"
        echo "initrd  /initramfs-linux-fallback.img"
        echo "options root=UUID=${root_uuid} rw"
    } > /mnt/boot/loader/entries/arch-fallback.conf

    log_info "✓ Fallback entry created"
}

regenerate_initramfs() {
    log_info "Regenerating initramfs (mkinitcpio -P)..."
    arch-chroot /mnt mkinitcpio -P
    log_info "✓ initramfs regenerated"

    log_info "Verifying kernel and initramfs files..."
    ls -lh /mnt/boot/vmlinuz-linux /mnt/boot/initramfs-linux.img /mnt/boot/initramfs-linux-fallback.img
}

main() {
    log_info "=== systemd-boot setup start ==="
    install_systemd_boot
    create_loader_config
    install_microcode
    create_boot_entry
    create_fallback_entry
    regenerate_initramfs
    log_info "=== systemd-boot setup complete ==="
}
main "$@"
