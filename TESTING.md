# VirtualBoxテストガイド

## 前提条件

VirtualBoxとカーネルモジュールの準備：

```bash
# VirtualBoxカーネルモジュールをロード
sudo modprobe vboxdrv

# または、vboxconfigで再構築
sudo /sbin/vboxconfig
```

## テストVM作成

自動でVMを作成：

```bash
cd /home/taka/ZTP
./create-test-vm.sh
```

### VM仕様
- 名前: ArchLinux-ZTP-Test
- メモリ: 4GB
- CPU: 2コア
- ディスク: 30GB
- ファームウェア: **UEFI必須**（設定 → システム → マザーボード → 「EFIを有効化」にチェック）
- ネットワーク: NAT（自動的にインターネット接続）

> ⚠️ **EFI を有効化しないと「booting...」で止まります。**
> systemd-boot は UEFI 専用のブートローダーです。

## VMの起動

### 方法1: コマンドライン

```bash
VBoxManage startvm "ArchLinux-ZTP-Test" --type gui
```

### 方法2: VirtualBox GUI

1. VirtualBoxを起動
2. 「ArchLinux-ZTP-Test」を選択
3. 「起動」をクリック

## テスト手順

### 1. Live環境の起動確認

- [ ] ISOから正常に起動する
- [ ] ネットワーク接続がある（`ping archlinux.org`）
- [ ] 対話的インストーラーが自動起動する

### 2. インストーラーのテスト

対話的質問に答える：

- **ネットワーク接続確認**: OK を確認
- **ディスク選択**: `/dev/sda` を選択
- **ホスト名**: `ztp-test` (任意)
- **ユーザー名**: `testuser` (任意)
- **パスワード**: テスト用パスワード
- **rootパスワード**: テスト用パスワード
- **タイムゾーン**: `Asia/Tokyo`
- **ロケール**: `ja_JP.UTF-8` または `en_US.UTF-8`

### 3. インストールプロセス

自動的に以下が実行される：
- [ ] パーティショニング (EFI + Root)
- [ ] ベースシステムインストール (5-10分)
- [ ] ブートローダーセットアップ
- [ ] システム設定
- [ ] パッケージインストール (10-20分)
- [ ] dotfiles適用とnucleus-shellビルド (5-10分)
- [ ] サービス有効化
- [ ] 自動再起動

**合計所要時間**: 約20-40分（ネットワーク速度に依存）

### 4. インストール後の確認

再起動後：

- [ ] GRUB/systemd-bootメニューが表示される
- [ ] Arch Linuxが起動する
- [ ] ログインプロンプトが表示される
- [ ] 設定したユーザー名でログインできる

ログイン後：

```bash
# Hyprlandを起動
Hyprland

# または、確認コマンド
whoami
hostname
uname -r
pacman -Q | wc -l  # インストール済みパッケージ数
ls ~/.config/      # dotfilesが配置されているか
which nucleus-shell
```

### 5. Hyprland環境の確認

Hyprlandが起動したら：

- [ ] 壁紙が表示される
- [ ] Super+Return でkittyターミナルが開く
- [ ] wofiランチャーが動作する
- [ ] Firefoxが起動する
- [ ] ネットワーク接続が維持されている

## トラブルシューティング

### ネットワーク接続エラー

Live環境で確認：
```bash
ip link
ip addr
ping 8.8.8.8
ping archlinux.org
```

### インストールエラー

ログを確認：
```bash
# インストール中
journalctl -f

# エラーメッセージの確認
dmesg | tail -50
```

### VM再作成

```bash
# VMを削除
VBoxManage unregistervm "ArchLinux-ZTP-Test" --delete

# 再作成
./create-test-vm.sh
```

## スナップショット（推奨）

インストール前にスナップショットを取得：

```bash
# VMを停止してから
VBoxManage snapshot "ArchLinux-ZTP-Test" take "clean-install" --description "インストール直後の状態"

# スナップショットから復元
VBoxManage snapshot "ArchLinux-ZTP-Test" restore "clean-install"
```

## VMの削除

テスト完了後：

```bash
VBoxManage unregistervm "ArchLinux-ZTP-Test" --delete
```

## 次のステップ

VirtualBoxでのテストが成功したら：

1. 実機用USBメディアを作成
2. 予備のPC/ラップトップでテスト
3. 本番環境にデプロイ
