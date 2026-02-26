#!/usr/bin/env bash
# ISOビルドスクリプト

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# 作業ディレクトリ
WORK_DIR="/home/taka/ZTP/iso-build"
PROFILE_DIR="${WORK_DIR}/profile"
OUT_DIR="${WORK_DIR}/out"

# ISOのビルド
build_iso() {
    log_info "=== カスタムArch Linux ISOのビルド開始 ==="
    
    cd "$WORK_DIR"
    
    # 既存のビルド成果物をクリーンアップ
    if [ -d "${WORK_DIR}/work" ]; then
        log_info "既存のworkディレクトリを削除中..."
        sudo rm -rf "${WORK_DIR}/work"
    fi
    
    # ISOビルド実行
    log_info "mkarchiso実行中... (時間がかかります)"
    sudo mkarchiso -v -w "${WORK_DIR}/work" -o "$OUT_DIR" "$PROFILE_DIR"
    
    log_info "✓ ISOビルド完了"
}

# ビルド結果の確認
check_result() {
    log_info "=== ビルド結果 ==="
    
    local iso_file=$(find "$OUT_DIR" -name "*.iso" -type f | head -1)
    
    if [ -z "$iso_file" ]; then
        log_error "ISOファイルが見つかりません"
        exit 1
    fi
    
    log_info "ISOファイル: ${iso_file}"
    log_info "ファイルサイズ: $(du -h "$iso_file" | cut -f1)"
    log_info "SHA256: $(sha256sum "$iso_file" | cut -d' ' -f1)"
    
    echo
    log_info "次のコマンドでUSBに書き込めます:"
    echo "  sudo dd if=${iso_file} of=/dev/sdX bs=4M status=progress && sync"
    echo
}

# メイン処理
main() {
    build_iso
    check_result
    
    log_info "=== 完了 ==="
}

main "$@"
