# ZTP システム設計書

## システム概要
Arch Linux + Hyprland環境を物理マシンに完全自動でインストール・構築するゼロタッチプロビジョニングシステム。

## 技術要件

### プロビジョニングサーバー
- OS: Arch Linux（または任意のLinuxディストリビューション）
- 必要なサービス:
  - **dnsmasq**: DHCP + TFTPサーバー
  - **nginx**: HTTPサーバー（インストールスクリプト配信用）
- ネットワーク: 静的IP（例: 192.168.1.100）

### ターゲットマシン（クライアント）
- BIOS/UEFI: PXEブート対応
- ネットワーク: 有線LAN接続
- ストレージ: 空のディスク（自動パーティショニング）

## プロビジョニングフロー

```
1. ターゲットPC起動
   ↓
2. PXE ROM起動 → DHCP Request (ブロードキャスト)
   ↓
3. dnsmasqが応答
   - IPアドレス割り当て (例: 192.168.1.150)
   - TFTP Server情報提供
   - ブートファイル名指定 (pxelinux.0 または ipxe.efi)
   ↓
4. TFTPでブートローダーをダウンロード
   ↓
5. Arch Linux Live環境起動 (archiso over HTTP)
   ↓./create-test-vm.sh
6. カーネルパラメータで自動インストールスクリプト起動
   - curl http://192.168.1.100/install.sh | bash
   ↓
7. OSインストール
   - パーティショニング
   - pacstrap (base + packages.txt)
   - bootloader (GRUB/systemd-boot)
   ↓
8. 再起動 → ログイン後に環境構築スクリプト自動実行
   - arch-dotfiles clone & 適用
   - nucleus-shell ビルド
   - サービス有効化 (ufw, bluetooth)
   ↓
9. 完了: Hyprland環境が起動
```

## ネットワーク構成

```
192.168.1.0/24 (既存のLAN)
│
├─ 192.168.1.100  : Provisioning Server (静的IP)
│   ├─ dnsmasq    : DHCP (192.168.1.150-200 を配布)
│   ├─ TFTP       : :69/tcp
│   └─ nginx      : :80/tcp
│
└─ 192.168.1.150+ : Target PC (DHCP自動取得)
```

## ファイル構成

### サーバー側 (/srv/pxe/)
```
/srv/pxe/
├── tftp/
│   ├── pxelinux.0            # PXEブートローダー
│   ├── ldlinux.c32
│   ├── pxelinux.cfg/
│   │   └── default           # ブートメニュー設定
│   ├── archiso/
│   │   ├── vmlinuz-linux     # Arch Linuxカーネル
│   │   └── initramfs-linux.img
│   └── archiso.sqfs          # ルートファイルシステム
│
└── http/
    ├── install.sh            # 自動インストールスクリプト
    ├── provision.sh          # 環境構築スクリプト
    └── packages.txt          # パッケージリスト
```

## セキュリティ考慮事項

### ファイアウォール (ufw)
- SSH: 22/tcp (必要に応じて)
- DHCP: 67/udp
- TFTP: 69/udp
- HTTP: 80/tcp

### サービス有効化
```bash
systemctl enable ufw
systemctl enable bluetooth
systemctl enable NetworkManager
```

## カスタムコンポーネント

### 1. nucleus-shell
- ビルド元: https://github.com/xZepyx/nucleus-shell
- インストール方法: 
  ```bash
  git clone https://github.com/xZepyx/nucleus-shell
  cd nucleus-shell
  ./install
  ```

### 2. arch-dotfiles
- リポジトリ: https://github.com/kadaiyare/arch-dotfiles
- 配置場所: ~/.config/
- 含まれる設定:
  - hypr/ (Hyprland)
  - kitty/
  - wofi/
  - fastfetch/
  - .zshrc

### 3. 除外するコンポーネント
- KDE Plasma関連
- swaync (通知デーモン)
- waybar (ステータスバー)

## GPU/ドライバ対応

### NVIDIA
```bash
nvidia
nvidia-utils
nvidia-settings
```

### AMD
```bash
xf86-video-amdgpu
vulkan-radeon
```

### Intel
```bash
xf86-video-intel
vulkan-intel
```

※ハードウェアに応じて packages.txt に追記

## トラブルシューティング

### PXE Boot失敗
- BIOS設定確認: Legacy/UEFI モード
- ネットワークケーブル確認
- dnsmasqログ確認: `journalctl -u dnsmasq -f`

### インストール失敗
- HTTPサーバーログ確認: `journalctl -u nginx -f`
- インストールスクリプトのシンタックスエラー
- ディスク容量不足

### 環境構築失敗
- arch-dotfiles のクローン失敗（認証エラー）
- パッケージの依存関係エラー
- nucleus-shell のビルドエラー

## 参考資料
- Arch Wiki: PXE
- syslinux documentation
- dnsmasq man page
