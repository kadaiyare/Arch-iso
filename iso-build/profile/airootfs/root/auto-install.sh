#!/usr/bin/env bash
# Main auto-installer - runs all scripts in sequence

set -uo pipefail
export LANG=C LC_ALL=C

LOG_FILE="/tmp/ztp-install.log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*" | tee -a "$LOG_FILE"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $*" | tee -a "$LOG_FILE"; }

run_step() {
    local name="$1"
    local script="$2"
    log_step "${name}"
    if bash "$script" 2>&1 | tee -a "$LOG_FILE"; then
        log_info "✓ ${name} done"
    else
        log_error "✗ ${name} FAILED (exit $?)"
        log_error "See full log: $LOG_FILE"
        echo
        echo -e "${RED}====== STEP FAILED: ${name} ======${NC}"
        echo "Press Enter to continue anyway, or Ctrl+C to abort"
        read -r
    fi
    echo
}

show_user_summary() {
    source /tmp/ztp-install.conf
    local passwd_entry shadow_field groups_entry

    passwd_entry=$(grep "^${USERNAME}:" /mnt/etc/passwd 2>/dev/null || echo "NOT FOUND")
    shadow_field=$(awk -F: -v u="${USERNAME}" '$1==u{print $2}' /mnt/etc/shadow 2>/dev/null || echo "NOT FOUND")
    groups_entry=$(grep "wheel" /mnt/etc/group 2>/dev/null | grep "${USERNAME}" || echo "NOT IN WHEEL")

    local pw_status
    if [[ "${shadow_field}" == \$6\$* ]]; then
        pw_status="${GREEN}OK (SHA-512 hash)${NC}"
    elif [[ "${shadow_field}" == "NOT FOUND" ]]; then
        pw_status="${RED}NOT FOUND${NC}"
    else
        pw_status="${RED}INVALID: '${shadow_field}'${NC}"
    fi

    echo
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         USER CREATION SUMMARY           ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} passwd : ${passwd_entry}"
    echo -e "${BLUE}║${NC} shadow : $(echo -e $pw_status)"
    echo -e "${BLUE}║${NC} wheel  : ${groups_entry}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo
    echo "Press Enter to continue..."
    read -r
}

main() {
    : > "$LOG_FILE"
    clear
    log_info "=========================================="
    log_info "   Arch Linux ZTP Auto Installer"
    log_info "   Log: $LOG_FILE"
    log_info "=========================================="
    echo

    run_step "1/7 Partitioning"         /root/partition.sh
    run_step "2/7 Base system install"  /root/base-install.sh
    run_step "3/7 Bootloader setup"     /root/bootloader-setup.sh
    run_step "4/7 System configuration" /root/system-config.sh

    # ユーザー作成結果を目立つように表示
    show_user_summary

    run_step "5/7 Package installation" /root/package-install.sh
    run_step "6/7 Dotfiles & nucleus-shell" /root/dotfiles-apply.sh
    run_step "7/7 Enable system services"   /root/service-enable.sh

    source /tmp/ztp-install.conf
    echo
    echo -e "${GREEN}=========================================="
    echo    "   Installation complete!"
    echo    "=========================================="
    echo -e "${NC}"
    echo "  Username : ${USERNAME}"
    echo "  Hostname : ${HOSTNAME}"
    echo "  Log file : ${LOG_FILE}"
    echo
    echo "Rebooting in 10 seconds... (Ctrl+C to cancel)"
    sleep 10

    umount -R /mnt || true
    reboot
}
main "$@"
