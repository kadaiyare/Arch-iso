#!/usr/bin/env bash
# Automatic partitioning script

set -euo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

create_partitions() {
    log_info "Creating partitions on: ${INSTALL_DISK}"
    log_warn "Erasing existing data..."
    wipefs -af "${INSTALL_DISK}" || true
    sgdisk -Z "${INSTALL_DISK}" || true
    log_info "Creating GPT partition table..."
    sgdisk -o "${INSTALL_DISK}"
    log_info "Creating EFI partition (512MB)..."
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "${INSTALL_DISK}"
    log_info "Creating root partition (remaining space)..."
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"Linux filesystem" "${INSTALL_DISK}"
    partprobe "${INSTALL_DISK}"
    sleep 2
    log_info "✓ Partitions created"
}

get_partition_names() {
    if [[ "${INSTALL_DISK}" =~ "nvme" ]] || [[ "${INSTALL_DISK}" =~ "mmcblk" ]]; then
        EFI_PARTITION="${INSTALL_DISK}p1"
        ROOT_PARTITION="${INSTALL_DISK}p2"
    else
        EFI_PARTITION="${INSTALL_DISK}1"
        ROOT_PARTITION="${INSTALL_DISK}2"
    fi
    log_info "EFI partition:  ${EFI_PARTITION}"
    log_info "Root partition: ${ROOT_PARTITION}"
    echo "EFI_PARTITION=${EFI_PARTITION}"   >> "$CONFIG_FILE"
    echo "ROOT_PARTITION=${ROOT_PARTITION}" >> "$CONFIG_FILE"
}

create_filesystems() {
    log_info "Formatting EFI partition (FAT32)..."
    mkfs.fat -F32 -n EFI "${EFI_PARTITION}"
    log_info "Formatting root partition (ext4)..."
    mkfs.ext4 -L ROOT -F "${ROOT_PARTITION}"
    log_info "✓ Filesystems created"
}

mount_partitions() {
    log_info "Mounting partitions..."
    mount "${ROOT_PARTITION}" /mnt
    mkdir -p /mnt/boot
    mount "${EFI_PARTITION}" /mnt/boot
    log_info "✓ Mounted"
    df -h /mnt
}

main() {
    log_info "=== Partitioning start ==="
    create_partitions
    get_partition_names
    create_filesystems
    mount_partitions
    log_info "=== Partitioning complete ==="
}
main "$@"
