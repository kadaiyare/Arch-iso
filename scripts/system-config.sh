#!/usr/bin/env bash
# System base configuration script

# set -e は使わず各ステップで明示的にエラーチェック
set -uo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }
die()       { log_error "$*"; exit 1; }

# CONFIG_FILE の内容を確認
log_info "--- CONFIG_FILE contents ---"
cat "$CONFIG_FILE"
echo "----------------------------"
source "$CONFIG_FILE"

log_info "USERNAME   = '${USERNAME}'"
log_info "HOSTNAME   = '${HOSTNAME}'"
log_info "TIMEZONE   = '${TIMEZONE}'"
log_info "LOCALE     = '${LOCALE}'"

configure_timezone() {
    log_info "Setting timezone: ${TIMEZONE}"
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime \
        || log_warn "Failed to set timezone symlink"
    arch-chroot /mnt hwclock --systohc \
        || log_warn "hwclock failed (normal in VM), continuing"
    log_info "✓ Timezone done"
}

configure_locale() {
    log_info "Setting locale: ${LOCALE}"
    if [ "${LOCALE}" = "ja_JP.UTF-8" ]; then
        sed -i 's/^#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /mnt/etc/locale.gen
        sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
    else
        sed -i "s/^#${LOCALE}/${LOCALE}/" /mnt/etc/locale.gen
    fi
    arch-chroot /mnt locale-gen \
        || log_warn "locale-gen failed, continuing"
    echo "LANG=${LOCALE}" > /mnt/etc/locale.conf
    log_info "✓ Locale done"
}

configure_vconsole() {
    log_info "Creating /etc/vconsole.conf..."
    printf 'KEYMAP=us\nFONT=\n' > /mnt/etc/vconsole.conf
    log_info "✓ vconsole.conf created"
}

configure_hostname() {
    log_info "Setting hostname: ${HOSTNAME}"
    echo "${HOSTNAME}" > /mnt/etc/hostname
    printf '127.0.0.1   localhost\n::1         localhost\n127.0.1.1   %s.localdomain %s\n' \
        "${HOSTNAME}" "${HOSTNAME}" > /mnt/etc/hosts
    log_info "✓ Hostname done"
}

configure_root_password() {
    log_info "Locking root account (sudo via wheel group)..."
    arch-chroot /mnt usermod -L root \
        || log_warn "usermod -L root failed, continuing"
    log_info "✓ Root account locked"
}

create_user() {
    log_info "=== Creating user: '${USERNAME}' ==="

    # すでに存在する場合はスキップ
    if arch-chroot /mnt id "${USERNAME}" &>/dev/null; then
        log_warn "User '${USERNAME}' already exists, skipping useradd"
    else
        arch-chroot /mnt useradd -m -s /bin/bash "${USERNAME}" \
            || die "useradd failed for '${USERNAME}'"
        log_info "useradd succeeded"
    fi

    # グループ追加
    for grp in wheel audio video optical storage; do
        arch-chroot /mnt groupadd -f "${grp}" 2>/dev/null || true
        arch-chroot /mnt usermod -aG "${grp}" "${USERNAME}" \
            || log_warn "Failed to add ${USERNAME} to group ${grp}"
    done

    # パスワード設定
    local hashed
    hashed=$(openssl passwd -6 "${PASSWORD}") \
        || die "openssl passwd failed for user"
    arch-chroot /mnt usermod -p "${hashed}" "${USERNAME}" \
        || die "usermod -p failed for '${USERNAME}'"

    # 結果確認
    log_info "--- /etc/passwd entry ---"
    grep "^${USERNAME}:" /mnt/etc/passwd || log_error "User not found in /etc/passwd!"
    log_info "--- /etc/shadow status ---"
    local shadow_field
    shadow_field=$(awk -F: -v u="${USERNAME}" '$1==u{print $2}' /mnt/etc/shadow)
    if [[ "${shadow_field}" == \$6\$* ]]; then
        log_info "Password hash looks correct (SHA-512)"
    else
        log_error "Password field: '${shadow_field}' - may be wrong!"
    fi
    log_info "✓ User '${USERNAME}' created"
}

configure_sudo() {
    log_info "Configuring sudo (NOPASSWD for wheel)..."
    # インストール中のmakepkg等でパスワード不要にする
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /mnt/etc/sudoers \
        || log_warn "sudo NOPASSWD config failed"
    log_info "✓ sudo configured"
}

configure_fonts() {
    log_info "Configuring Japanese fontconfig..."
    mkdir -p /mnt/etc/fonts/conf.d
    cat > /mnt/etc/fonts/conf.d/64-noto-cjk-jp.conf <<'FONTCONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <alias>
    <family>sans-serif</family>
    <prefer><family>Noto Sans CJK JP</family></prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer><family>Noto Serif CJK JP</family></prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer><family>Noto Sans Mono CJK JP</family></prefer>
  </alias>
</fontconfig>
FONTCONF
    log_info "✓ Fontconfig set"
}

enable_networkmanager() {
    log_info "Enabling NetworkManager..."
    arch-chroot /mnt systemctl enable NetworkManager \
        || log_warn "Failed to enable NetworkManager"
    log_info "✓ NetworkManager enabled"
}

main() {
    log_info "=== System configuration start ==="
    configure_timezone
    configure_locale
    configure_vconsole
    configure_hostname
    configure_root_password
    create_user
    configure_sudo
    configure_fonts
    enable_networkmanager
    log_info "=== System configuration complete ==="
}
main "$@"
