#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux-ztp"
iso_label="ARCH_ZTP_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Arch Linux ZTP <https://archlinux.org>"
iso_application="Arch Linux ZTP Auto Installer"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/install-dialog.sh"]="0:0:755"
  ["/root/auto-install.sh"]="0:0:755"
  ["/root/partition.sh"]="0:0:755"
  ["/root/base-install.sh"]="0:0:755"
  ["/root/bootloader-setup.sh"]="0:0:755"
  ["/root/system-config.sh"]="0:0:755"
  ["/root/package-install.sh"]="0:0:755"
  ["/root/dotfiles-apply.sh"]="0:0:755"
  ["/root/service-enable.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
