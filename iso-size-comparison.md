# ISO サイズ比較

## 変更前
- パッケージ数: 128個（releng標準）
- ISOサイズ: 1.5GB
- 含まれる内容: クローニングツール、リカバリツール、仮想化ツールなど多数

## 変更後（最小化）
- パッケージ数: 46個
- 予想ISOサイズ: 800MB-1GB
- 含まれる内容: インストーラー実行に必要な最小限

## ISO Live環境に含まれるもの（最小化後）
- ベースシステム（Linux kernel、ファームウェア）
- ネットワーク接続ツール（NetworkManager）
- パーティショニングツール（gptfdisk、mkfs系）
- インストールツール（arch-install-scripts、pacstrap）
- インストーラースクリプト（dialog、curl、git、reflector）
- 基本エディタ（vim、nano）

## インストール先に入るもの（packages.txt）
- Hyprland環境（85個のパッケージ）
- 開発ツール（Rust、Go、Python、Node.js）
- アプリケーション（Firefox、kitty等）
- dotfiles + nucleus-shell

## メリット
✅ ISOサイズが半分以下に
✅ USB書き込み時間が短縮
✅ Live環境の起動が高速化
✅ インストール先は変わらず全機能搭載
