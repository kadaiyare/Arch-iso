#!/usr/bin/env bash
# Apply dotfiles, install yay+AUR packages, and set up nucleus-shell

set -euo pipefail

CONFIG_FILE="/tmp/ztp-install.conf"
source "$CONFIG_FILE"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARNING]${NC} $*"; }

clone_dotfiles() {
    log_info "Cloning arch-dotfiles..."
    local user_home="/mnt/home/${USERNAME}"
    if [ -d "${user_home}/arch-dotfiles" ]; then
        log_warn "arch-dotfiles already exists, skipping"
        return 0
    fi
    arch-chroot /mnt sudo -u "${USERNAME}" git clone \
        https://github.com/kadaiyare/arch-dotfiles.git \
        "/home/${USERNAME}/arch-dotfiles" || {
        log_error "Failed to clone arch-dotfiles"
        return 1
    }
    log_info "✓ arch-dotfiles cloned"
}

setup_dotfiles() {
    log_info "Setting up dotfiles..."
    local dotfiles_dir="/mnt/home/${USERNAME}/arch-dotfiles"
    arch-chroot /mnt sudo -u "${USERNAME}" mkdir -p "/home/${USERNAME}/.config"
    for cfg in hypr kitty wofi fastfetch; do
        if [ -d "${dotfiles_dir}/${cfg}" ]; then
            log_info "Copying ${cfg} config..."
            arch-chroot /mnt sudo -u "${USERNAME}" cp -r \
                "/home/${USERNAME}/arch-dotfiles/${cfg}" \
                "/home/${USERNAME}/.config/"
        fi
    done
    if [ -f "${dotfiles_dir}/.zshrc" ]; then
        log_info "Copying .zshrc..."
        arch-chroot /mnt sudo -u "${USERNAME}" cp \
            "/home/${USERNAME}/arch-dotfiles/.zshrc" \
            "/home/${USERNAME}/"
    fi
    log_info "✓ Dotfiles set up"
}

install_yay() {
    log_info "Installing yay (AUR helper)..."
    if arch-chroot /mnt sudo -u "${USERNAME}" bash -c "command -v yay" &>/dev/null; then
        log_warn "yay already installed, skipping"
        return 0
    fi
    arch-chroot /mnt bash -c "
        export LANG=C LC_ALL=C
        cd /tmp
        git clone https://aur.archlinux.org/yay.git yay-build
        chown -R ${USERNAME}:${USERNAME} yay-build
        cd yay-build
        sudo -u ${USERNAME} LANG=C LC_ALL=C makepkg -si --noconfirm
        cd /tmp && rm -rf yay-build
    " || {
        log_error "Failed to install yay"
        return 1
    }
    log_info "✓ yay installed"
}

install_aur_packages() {
    log_info "Installing AUR packages (quickshell, matugen-bin)..."
    arch-chroot /mnt sudo -u "${USERNAME}" \
        yay -S --noconfirm --needed quickshell matugen-bin || {
        log_warn "Some AUR packages failed to install, continuing..."
    }
    log_info "✓ AUR packages installed"
}

setup_nucleus_shell() {
    log_info "Cloning nucleus-shell..."
    local user_home="/mnt/home/${USERNAME}"
    if [ ! -d "${user_home}/nucleus-shell" ]; then
        arch-chroot /mnt sudo -u "${USERNAME}" git clone \
            https://github.com/xZepyx/nucleus-shell.git \
            "/home/${USERNAME}/nucleus-shell" || {
            log_error "Failed to clone nucleus-shell"
            return 1
        }
    fi

    log_info "Copying nucleus-shell config..."
    arch-chroot /mnt sudo -u "${USERNAME}" bash -c "
        mkdir -p ~/.config/quickshell/nucleus-shell
        cp -r ~/nucleus-shell/quickshell/nucleus-shell/* ~/.config/quickshell/nucleus-shell/
    " || {
        log_error "Failed to copy nucleus-shell config"
        return 1
    }
    log_info "✓ nucleus-shell set up"
}

set_default_shell() {
    log_info "Setting zsh as default shell..."
    local zsh_path
    zsh_path=$(arch-chroot /mnt which zsh 2>/dev/null || echo "")
    if [ -z "${zsh_path}" ]; then
        log_warn "zsh not found in chroot, keeping bash as default shell"
        return 0
    fi
    # /etc/shells に登録されていなければ追加
    if ! grep -q "${zsh_path}" /mnt/etc/shells 2>/dev/null; then
        echo "${zsh_path}" >> /mnt/etc/shells
    fi
    arch-chroot /mnt chsh -s "${zsh_path}" "${USERNAME}"
    log_info "✓ Default shell set to ${zsh_path}"
}

main() {
    log_info "=== Dotfiles setup start ==="
    clone_dotfiles
    setup_dotfiles
    install_yay || log_warn "yay installation failed, skipping AUR packages"
    install_aur_packages || log_warn "AUR packages failed, continuing..."
    setup_nucleus_shell || log_warn "nucleus-shell setup failed, continuing..."
    set_default_shell
    log_info "=== Dotfiles setup complete ==="
}
main "$@"
