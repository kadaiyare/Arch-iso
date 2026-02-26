# ZTPプロジェクト - 作業再開メモ

**最終更新**: 2026-02-20 13:12

## 📍 現在の状況

### ✅ 完了済み
1. USB-based ZTPシステムの設計・実装完了
2. 最小限のパッケージ（46→51個）でISOを構成
3. 全インストールスクリプト作成完了（9個）
4. ISOビルド成功（1.3GB）
5. VirtualBoxテスト環境セットアップ完了

### 🔄 作業中
- **VirtualBoxでのインストールテスト実行中**
- **問題発見**: Live環境で日本語が文字化け（豆腐表示）

### 🔧 修正済み（未ビルド）
- `iso-build/profile/packages.x86_64` に日本語フォントを追加:
  - `noto-fonts`
  - `noto-fonts-cjk`
  - `terminus-font`

## 🚀 次回作業時にやること

### 1. ISOの再ビルド（必須）

日本語フォントを含めた新しいISOをビルド：

```bash
cd /home/taka/ZTP
sudo rm -rf iso-build/work iso-build/out/*
sudo ./build-iso.sh
```

**所要時間**: 10-20分

### 2. VirtualBoxテストの再開

#### オプションA: 既存VMを使用

```bash
# 新しいISOをマウント
VBoxManage storageattach "ArchLinux-ZTP-Test" \
    --storagectl "IDE Controller" \
    --port 0 \
    --device 0 \
    --type dvddrive \
    --medium /home/taka/ZTP/iso-build/out/archlinux-ztp-2026.02.20-x86_64.iso

# VMを起動
VBoxManage startvm "ArchLinux-ZTP-Test" --type gui
```

#### オプションB: VMを再作成

```bash
# 既存VMを削除
VBoxManage unregistervm "ArchLinux-ZTP-Test" --delete

# 新規作成
cd /home/taka/ZTP
./create-test-vm.sh

# 起動
VBoxManage startvm "ArchLinux-ZTP-Test" --type gui
```

### 3. インストールテストの実行

対話的質問に答える:
- ネットワーク接続確認: ✓
- ディスク選択: `/dev/sda`
- ホスト名: `ztp-test`
- ユーザー名: `testuser`
- パスワード: （任意のテスト用パスワード）
- rootパスワード: （任意のテスト用パスワード）
- タイムゾーン: `Asia/Tokyo`
- ロケール: `ja_JP.UTF-8`

**所要時間**: 20-40分

### 4. インストール後の確認項目

再起動後、ログインして確認:

```bash
# 基本情報
whoami
hostname
uname -r

# パッケージ数
pacman -Q | wc -l

# dotfiles確認
ls ~/.config/

# Hyprland起動
Hyprland
```

Hyprland環境で:
- [ ] 日本語表示が正常
- [ ] kittyターミナル起動（Super+Return）
- [ ] wofiランチャー動作
- [ ] Firefox起動
- [ ] ネットワーク接続維持

## 📂 重要なファイル

### スクリプト
- `/home/taka/ZTP/build-iso.sh` - ISOビルド
- `/home/taka/ZTP/create-test-vm.sh` - VM作成
- `/home/taka/ZTP/scripts/` - インストールスクリプト群

### 設定ファイル
- `/home/taka/ZTP/packages.txt` - インストール先パッケージリスト
- `/home/taka/ZTP/iso-build/profile/packages.x86_64` - Live環境パッケージ（51個）
- `/home/taka/ZTP/iso-build/profile/profiledef.sh` - ISO設定

### ドキュメント
- `/home/taka/ZTP/README.md` - プロジェクト概要
- `/home/taka/ZTP/USAGE.md` - 使用方法
- `/home/taka/ZTP/TESTING.md` - テスト手順詳細
- `/home/taka/ZTP/plan.md` - 実装プラン

## 🐛 既知の問題と対処

### 問題1: Live環境で日本語文字化け
- **原因**: 日本語フォントが含まれていない
- **対処**: packages.x86_64に追加済み → 再ビルドで解決予定

### 問題2: VirtualBoxカーネルモジュールエラー
- **症状**: `vboxdrv kernel module is not loaded`
- **対処**: `sudo modprobe vboxdrv` または `sudo /sbin/vboxconfig`

## 📊 プロジェクト進捗

```
Phase 1: 設計・計画        [████████████████████] 100%
Phase 2: スクリプト実装    [████████████████████] 100%
Phase 3: ISOビルド         [████████████████████] 100%
Phase 4: VirtualBoxテスト  [████████░░░░░░░░░░░░]  40%
Phase 5: 実機テスト        [░░░░░░░░░░░░░░░░░░░░]   0%
Phase 6: ドキュメント整備  [███████████████░░░░░]  75%
```

## 🎯 最終ゴール

1. ✅ USBメモリから起動
2. ✅ 最小限の質問に回答
3. 🔄 自動インストール完了（テスト中）
4. ⏳ Hyprland環境が完全に動作
5. ⏳ 実機での動作確認
6. ⏳ 本番運用可能な状態

## 📝 メモ・備考

### テスト環境
- VirtualBox VM: ArchLinux-ZTP-Test
- メモリ: 4GB
- ディスク: 30GB
- ネットワーク: NAT（インターネット接続）
- ファームウェア: UEFI

### 次回の改善候補
- [ ] インストール進捗バーの追加
- [ ] エラーログの自動保存
- [ ] GPU自動検出とドライバインストール
- [ ] 複数ロケール対応

---

**再開時のチェックリスト**:
1. [ ] ISOを再ビルド（日本語フォント対応）
2. [ ] VirtualBoxでテスト再開
3. [ ] インストール完了まで確認
4. [ ] Hyprland環境の動作確認
5. [ ] 問題があれば修正して再ビルド
