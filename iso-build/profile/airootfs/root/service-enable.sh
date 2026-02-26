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
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

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

main() {
    log_info "=== Enable services start ==="
    enable_services
    configure_ufw
    configure_sddm
    log_info "=== Enable services complete ==="
}
main "$@"
