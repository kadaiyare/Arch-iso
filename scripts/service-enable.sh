#!/usr/bin/env bash
# Enable system services
set -uo pipefail
export LANG=C LC_ALL=C

CONFIG_FILE="/tmp/ztp-install.conf"
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

enable_services() {
    log_info "Enabling NetworkManager..."
    arch-chroot /mnt systemctl enable NetworkManager \
        || log_warn "Failed to enable NetworkManager"

    log_info "Enabling Bluetooth..."
    arch-chroot /mnt systemctl enable bluetooth \
        || log_warn "bluetooth not found, skipping"

    log_info "Enabling UFW..."
    arch-chroot /mnt systemctl enable ufw \
        || log_warn "ufw not found, skipping"

    log_info "Enabling SDDM (display manager)..."
    arch-chroot /mnt systemctl enable sddm \
        || log_warn "sddm not found, skipping"

    log_info "✓ Services enabled"
}

configure_ufw() {
    log_info "Configuring UFW default policies..."
    arch-chroot /mnt ufw default deny incoming  || true
    arch-chroot /mnt ufw default allow outgoing || true
    log_info "✓ UFW configured"
}

configure_sddm() {
    log_info "Configuring SDDM for Hyprland..."

    # SDDM設定ディレクトリ
    mkdir -p /mnt/etc/sddm.conf.d

    # Waylandセッションで起動・自動ログイン設定
    cat > /mnt/etc/sddm.conf.d/10-ztp.conf << SDDMCONF
[Autologin]
User=${USERNAME}
Session=hyprland
SDDMCONF

    # Hyprland の .desktop セッションファイルが存在するか確認
    if [ ! -f /mnt/usr/share/wayland-sessions/hyprland.desktop ]; then
        log_warn "hyprland.desktop not found, creating manually..."
        mkdir -p /mnt/usr/share/wayland-sessions
        cat > /mnt/usr/share/wayland-sessions/hyprland.desktop << DESKTOP
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
DESKTOP
    fi

    log_info "✓ SDDM configured (auto-login: ${USERNAME} -> Hyprland)"
}

configure_wayland_env() {
    log_info "Configuring Wayland environment variables..."
    cat >> /mnt/etc/environment << 'ENVCONF'
# Hyprland / wlroots - cursor fix (required in most VMs and some hardware)
WLR_NO_HARDWARE_CURSORS=1
HYPRLAND_NO_HARDWARE_CURSORS=1
ENVCONF
    log_info "✓ Wayland env configured"
}

install_virtualbox_guest() {
    log_info "Detecting virtualization..."
    local virt
    virt=$(systemd-detect-virt 2>/dev/null || echo "none")
    log_info "Virtualization: ${virt}"
    if [ "${virt}" = "oracle" ]; then
        log_info "VirtualBox detected - installing guest utilities..."
        arch-chroot /mnt pacman -S --noconfirm --needed virtualbox-guest-utils \
            || log_warn "virtualbox-guest-utils install failed"
        arch-chroot /mnt systemctl enable vboxservice \
            || log_warn "vboxservice enable failed"
        log_info "✓ VirtualBox guest utils installed"
    fi
}

main() {
    log_info "=== Enable services start ==="
    enable_services
    configure_ufw
    configure_sddm
    configure_wayland_env
    install_virtualbox_guest
    log_info "=== Enable services complete ==="
}
main "$@"
