#!/usr/bin/env bash
# Interactive installer - collect required information from user

set -euo pipefail
export LANG=C LC_ALL=C

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONFIG_FILE="/tmp/ztp-install.conf"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }

check_network() {
    log_info "Checking network connection..."

    if ping -c 3 archlinux.org &>/dev/null; then
        log_info "✓ Internet connection OK"
        return 0
    else
        log_error "✗ No internet connection"
        log_warn "Please check if the ethernet cable is connected"

        if dialog --yesno "No network connection detected.\nContinue anyway?\n(Package installation will fail without network)" 10 60; then
            return 0
        else
            exit 1
        fi
    fi
}

select_disk() {
    log_info "Detecting available disks..."

    local disks=()
    while IFS= read -r line; do
        local disk=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $4}')
        disks+=("$disk" "${size}")
    done < <(lsblk -dpno NAME,SIZE,TYPE | grep 'disk')

    if [ ${#disks[@]} -eq 0 ]; then
        log_error "No available disks found"
        exit 1
    fi

    INSTALL_DISK=$(dialog --stdout --menu "Select installation disk\nWARNING: All data on the selected disk will be erased" 20 60 10 "${disks[@]}")

    if [ -z "$INSTALL_DISK" ]; then
        log_error "No disk selected"
        exit 1
    fi

    if ! dialog --yesno "Install to ${INSTALL_DISK}?\nALL DATA WILL BE ERASED!" 10 60; then
        log_warn "Installation cancelled"
        exit 0
    fi

    echo "INSTALL_DISK=${INSTALL_DISK}" >> "$CONFIG_FILE"
    log_info "Install disk: ${INSTALL_DISK}"
}

input_hostname() {
    HOSTNAME=$(dialog --stdout --inputbox "Enter hostname:" 10 60 "archlinux-ztp")

    if [ -z "$HOSTNAME" ]; then
        HOSTNAME="archlinux-ztp"
        log_warn "Using default hostname: ${HOSTNAME}"
    fi

    echo "HOSTNAME=${HOSTNAME}" >> "$CONFIG_FILE"
    log_info "Hostname: ${HOSTNAME}"
}

input_username() {
    USERNAME=$(dialog --stdout --inputbox "Enter username:" 10 60 "taka")

    if [ -z "$USERNAME" ]; then
        log_error "Username is required"
        input_username
        return
    fi

    echo "USERNAME=${USERNAME}" >> "$CONFIG_FILE"
    log_info "Username: ${USERNAME}"
}

input_password() {
    PASSWORD=$(dialog --stdout --insecure --passwordbox "Enter user password:" 10 60)

    if [ -z "$PASSWORD" ]; then
        log_error "Password is required"
        input_password
        return
    fi

    PASSWORD_CONFIRM=$(dialog --stdout --insecure --passwordbox "Confirm user password:" 10 60)

    if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        input_password
        return
    fi

    printf 'PASSWORD=%q\n' "${PASSWORD}" >> "$CONFIG_FILE"
    log_info "✓ User password set"
}

input_root_password() {
    ROOT_PASSWORD=$(dialog --stdout --insecure --passwordbox "Enter root password:" 10 60)

    if [ -z "$ROOT_PASSWORD" ]; then
        log_error "Root password is required"
        input_root_password
        return
    fi

    ROOT_PASSWORD_CONFIRM=$(dialog --stdout --insecure --passwordbox "Confirm root password:" 10 60)

    if [ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        input_root_password
        return
    fi

    printf 'ROOT_PASSWORD=%q\n' "${ROOT_PASSWORD}" >> "$CONFIG_FILE"
    log_info "✓ Root password set"
}

select_timezone() {
    TIMEZONE=$(dialog --stdout --inputbox "Enter timezone:" 10 60 "Asia/Tokyo")

    if [ -z "$TIMEZONE" ]; then
        TIMEZONE="Asia/Tokyo"
    fi

    echo "TIMEZONE=${TIMEZONE}" >> "$CONFIG_FILE"
    log_info "Timezone: ${TIMEZONE}"
}

select_locale() {
    LOCALE=$(dialog --stdout --menu "Select locale:" 15 60 5 \
        "ja_JP.UTF-8" "Japanese" \
        "en_US.UTF-8" "English (US)" \
        "en_GB.UTF-8" "English (GB)")

    if [ -z "$LOCALE" ]; then
        LOCALE="ja_JP.UTF-8"
    fi

    echo "LOCALE=${LOCALE}" >> "$CONFIG_FILE"
    log_info "Locale: ${LOCALE}"
}

final_confirmation() {
    source "$CONFIG_FILE"

    dialog --title "Confirm Installation Settings" --msgbox "$(cat <<EOF
Installation will proceed with the following settings:

Disk:     ${INSTALL_DISK}
Hostname: ${HOSTNAME}
Username: ${USERNAME}
Timezone: ${TIMEZONE}
Locale:   ${LOCALE}

Press OK to start installation.
EOF
)" 20 70

    if ! dialog --yesno "Start installation?" 8 50; then
        log_warn "Installation cancelled"
        exit 0
    fi
}

main() {
    clear
    log_info "Arch Linux ZTP Installer"
    log_info "========================"

    > "$CONFIG_FILE"

    check_network
    select_disk
    input_hostname
    input_username
    input_password
    input_root_password
    select_timezone
    select_locale
    final_confirmation

    log_info "Configuration saved: ${CONFIG_FILE}"
    log_info "Starting automated installation..."

    /root/auto-install.sh
}

main "$@"
