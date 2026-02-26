#!/usr/bin/env bash
# VirtualBox テストVM作成スクリプト

set -euo pipefail

VM_NAME="ArchLinux-ZTP-Test"
ISO_PATH="/home/taka/ZTP/iso-build/out/archlinux-ztp-2026.02.20-x86_64.iso"
VM_RAM=4096  # 4GB
VM_DISK_SIZE=30720  # 30GB
VM_CPUS=2

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# VirtualBoxのチェック
check_virtualbox() {
    if ! command -v VBoxManage &>/dev/null; then
        log_warn "VirtualBoxがインストールされていません"
        echo "VirtualBoxをインストールしてください: sudo pacman -S virtualbox"
        exit 1
    fi
    
    log_info "VirtualBox: $(VBoxManage --version)"
}

# 既存VMの削除
remove_existing_vm() {
    if VBoxManage list vms | grep -q "\"${VM_NAME}\""; then
        log_warn "既存のVM「${VM_NAME}」を削除します..."
        VBoxManage unregistervm "${VM_NAME}" --delete 2>/dev/null || true
    fi
}

# VM作成
create_vm() {
    log_info "VMを作成中: ${VM_NAME}"
    
    VBoxManage createvm \
        --name "${VM_NAME}" \
        --ostype "ArchLinux_64" \
        --register
    
    log_info "✓ VM作成完了"
}

# VM設定
configure_vm() {
    log_info "VM設定を構成中..."
    
    # メモリとCPU
    VBoxManage modifyvm "${VM_NAME}" \
        --memory ${VM_RAM} \
        --cpus ${VM_CPUS}
    
    # UEFI有効化
    VBoxManage modifyvm "${VM_NAME}" \
        --firmware efi
    
    # ネットワーク（NAT - インターネット接続）
    VBoxManage modifyvm "${VM_NAME}" \
        --nic1 nat
    
    # グラフィック
    VBoxManage modifyvm "${VM_NAME}" \
        --vram 128 \
        --graphicscontroller vmsvga
    
    log_info "✓ VM設定完了"
}

# ストレージ設定
setup_storage() {
    log_info "ストレージを設定中..."
    
    local vm_dir="${HOME}/VirtualBox VMs/${VM_NAME}"
    local disk_path="${vm_dir}/${VM_NAME}.vdi"
    
    # SATA コントローラー追加
    VBoxManage storagectl "${VM_NAME}" \
        --name "SATA Controller" \
        --add sata \
        --controller IntelAhci \
        --bootable on
    
    # ディスク作成
    VBoxManage createmedium disk \
        --filename "${disk_path}" \
        --size ${VM_DISK_SIZE} \
        --format VDI
    
    # ディスク接続
    VBoxManage storageattach "${VM_NAME}" \
        --storagectl "SATA Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium "${disk_path}"
    
    # IDE コントローラー追加（光学ドライブ用）
    VBoxManage storagectl "${VM_NAME}" \
        --name "IDE Controller" \
        --add ide
    
    # ISOをマウント
    VBoxManage storageattach "${VM_NAME}" \
        --storagectl "IDE Controller" \
        --port 0 \
        --device 0 \
        --type dvddrive \
        --medium "${ISO_PATH}"
    
    log_info "✓ ストレージ設定完了"
}

# 起動順序設定
set_boot_order() {
    log_info "起動順序を設定中..."
    
    VBoxManage modifyvm "${VM_NAME}" \
        --boot1 dvd \
        --boot2 disk \
        --boot3 none \
        --boot4 none
    
    log_info "✓ 起動順序設定完了"
}

# VM情報表示
show_vm_info() {
    log_info "=========================================="
    log_info "  テストVM作成完了"
    log_info "=========================================="
    echo
    echo "VM名: ${VM_NAME}"
    echo "メモリ: ${VM_RAM} MB"
    echo "CPU: ${VM_CPUS} コア"
    echo "ディスク: ${VM_DISK_SIZE} MB (約 $((VM_DISK_SIZE / 1024)) GB)"
    echo "ISO: ${ISO_PATH}"
    echo
    log_info "VMを起動するには:"
    echo "  VBoxManage startvm \"${VM_NAME}\" --type gui"
    echo
    log_info "または、VirtualBox GUIから起動してください"
}

# メイン処理
main() {
    check_virtualbox
    remove_existing_vm
    create_vm
    configure_vm
    setup_storage
    set_boot_order
    show_vm_info
}

main "$@"
