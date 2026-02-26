# Arch Linux ZTP (Zero Touch Provisioning) System

## 概要
このプロジェクトは、USBメモリから起動して最小限の質問に答えるだけで、Arch Linux + Hyprland環境が完全自動でセットアップされるゼロタッチプロビジョニングシステムです。

## システム構成

```
┌─────────────────────────────────────────────────────┐
│  USB Boot Media (Arch Linux Live + Custom Scripts) │
│                                                     │
│  - カスタムarchiso                                  │
│  - 対話的インストーラー                            │
│  - 自動インストールスクリプト                      │
│  - パッケージリスト + dotfiles設定                 │
└─────────────────────────────────────────────────────┘
                    ↓ USB Boot
┌─────────────────────────────────────────────────────┐
│  Target PC (Empty Disk) + 有線LAN                   │
│                                                     │
│  1. USB起動 → Live環境                              │
│  2. 対話的質問（ディスク/ユーザー名等）             │
│  3. 有線LAN → Arch公式ミラーからパッケージ取得     │
│  4. 自動パーティション & インストール              │
│  5. dotfiles適用 & Hyprland環境構築                │
│  6. 再起動 → 完成                                   │
└─────────────────────────────────────────────────────┘
```

## ディレクトリ構造

```
ZTP/
├── README.md                 # このファイル
├── USAGE.md                  # 使用方法とテストガイド
├── plan.md                   # 実装プラン
├── packages.txt              # 自動インストールするパッケージリスト
├── build-iso.sh              # ISOビルドスクリプト
├── scripts/                  # インストールスクリプト群
│   ├── install-dialog.sh     # 対話的インストーラー
│   ├── auto-install.sh       # メイン自動インストーラー
│   ├── partition.sh          # パーティショニング
│   ├── base-install.sh       # ベースシステムインストール
│   ├── bootloader-setup.sh   # systemd-bootセットアップ
│   ├── system-config.sh      # システム基本設定
│   ├── package-install.sh    # パッケージインストール
│   ├── dotfiles-apply.sh     # dotfiles適用
│   └── service-enable.sh     # サービス有効化
├── iso-build/                # ISOビルド作業ディレクトリ
│   ├── profile/              # archisoプロファイル
│   │   ├── airootfs/         # カスタムファイル配置先
│   │   ├── packages.x86_64   # archisoパッケージリスト
│   │   └── profiledef.sh     # ISO設定
│   ├── work/                 # ビルド中間ファイル（自動生成）
│   └── out/                  # 完成したISOファイル
├── docs/                     # 設計ドキュメント
└── Claude.md                 # プロジェクト要件定義
```

## クイックスタート

### 1. ISOのビルド

```bash
cd /home/taka/ZTP
sudo ./build-iso.sh
```

### 2. USBメディア作成

```bash
# USBデバイスを確認
lsblk

# ISOをUSBに書き込み（/dev/sdXは実際のデバイス名に）
sudo dd if=iso-build/out/archlinux-ztp-*.iso of=/dev/sdX bs=4M status=progress && sync
```

### 3. インストール

1. 有線LANケーブルを接続
2. USBから起動
3. 対話的質問に回答
4. 自動インストール完了を待つ
5. 再起動してログイン

詳細は [USAGE.md](USAGE.md) を参照してください。

## インストールされる環境
- Hyprland (Waylandコンポジター)
- kitty (ターミナル)
- zsh + nucleus-shell
- Firefox
- 開発環境 (Rust, Go, Python, Node.js)
- 個人用dotfiles (arch-dotfiles)

## 除外するパッケージ
- KDE Plasma (plasma-desktop, plasma-wayland-session など)
- swaync (通知デーモン)
- waybar (ステータスバー)

## 参照リポジトリ
- dotfiles: https://github.com/kadaiyare/arch-dotfiles

## 技術スタック
- **ベースイメージ**: archiso (公式のArch Linux ISOビルダー)
- **ブートメディア**: USBメモリ
- **対話的UI**: dialog (軽量TUI)
- **パーティショニング**: sgdisk + mkfs.ext4 + mkfs.fat
- **ブートローダー**: systemd-boot
- **パッケージ管理**: pacstrap + pacman
- **設定管理**: Git (arch-dotfiles) + シェルスクリプト

---

**現在のステータス**: 実装完了 - テスト待ち
