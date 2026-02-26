# USB-Based ZTP System for Arch Linux - Implementation Plan

## 問題と目標

**現在の状況**: 
- 既存のZTP設計はPXEサーバー(別のLinuxマシン)を前提としている
- ネットワークインフラが複雑(dnsmasq, TFTP, HTTPサーバー等)

**新しい目標**:
- USBメモリだけでArch Linuxを完全自動インストール
- 有線LAN接続で公式ミラーからパッケージを取得
- 最小限の対話的設定(ディスク選択、ホスト名、ユーザー名等)
- 既存のdotfiles(arch-dotfiles)を自動適用

## アーキテクチャ

```
┌─────────────────────────────────────────────┐
│  USB Boot Media (Arch Linux Live + Custom)  │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │  1. archiso (Arch Linux Live)         │ │
│  │  2. カスタムブートスクリプト          │ │
│  │  3. インストールスクリプト            │ │
│  │  4. 設定ファイル(packages.txt等)      │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    ↓ USB Boot
┌─────────────────────────────────────────────┐
│  Target PC (Empty Disk)                     │
│                                             │
│  1. USB起動 → Live環境                      │
│  2. TUIで最小限の質問                       │
│     - インストール先ディスク               │
│     - ホスト名                             │
│     - ユーザー名/パスワード                │
│  3. 有線LAN → Arch公式ミラー               │
│  4. 自動パーティション & インストール      │
│  5. dotfiles適用 & Hyprland環境構築        │
│  6. 再起動 → 完成                          │
└─────────────────────────────────────────────┘
```

## 技術スタック

- **ベースイメージ**: archiso (公式のArch Linux ISOビルダー)
- **ブートメディア**: USBメモリ (dd or Ventoy対応)
- **対話的UI**: dialog or whiptail (軽量TUI)
- **パーティショニング**: sgdisk + mkfs.ext4 + mkfs.fat
- **ブートローダー**: systemd-boot (シンプル、UEFIネイティブ)
- **パッケージ管理**: pacstrap + pacman
- **設定管理**: Git (arch-dotfiles) + シェルスクリプト

## 実装フェーズ

### Phase 1: カスタムArch ISOの準備
- archisoのセットアップとビルド環境構築
- 既存のarchiso profileをベースに作業
- カスタムスクリプトを組み込む準備

### Phase 2: 対話的インストーラーの作成
- dialogベースのTUIメニュー作成
- ユーザー入力の検証ロジック
- インストール先ディスクの自動検出と選択

### Phase 3: 自動インストールスクリプトの実装
- パーティショニング自動化 (GPT + EFI + root)
- pacstrapによるベースシステムインストール
- systemd-bootのセットアップ
- fstab, hostname, locale, timezone設定

### Phase 4: 環境構築の自動化
- packages.txtからの一括パッケージインストール
- arch-dotfilesのクローンと配置
- nucleus-shellのビルドとインストール
- サービスの有効化 (NetworkManager, bluetooth, ufw)

### Phase 5: カスタムISOのビルドとテスト
- archisoでのビルド実行
- VirtualBoxでのテスト
- USBメモリへの書き込みと実機テスト

### Phase 6: ドキュメント整備
- README更新
- トラブルシューティングガイド
- 技術解説ドキュメント

## 既存ファイルの再利用と変更

### 再利用できるもの
- `packages.txt` - パッケージリスト (ほぼそのまま)
- `docs/design.md` - 参考情報として保持

### 削除または置き換えるもの
- `server-config/` - PXEサーバー設定は不要
- Phase 1-2のPXEブート関連タスク

### 新規作成が必要なもの
- `iso-build/` - archisoプロファイル
- `iso-build/airootfs/` - カスタムファイルを配置
- `scripts/install-dialog.sh` - 対話的インストーラー
- `scripts/auto-install.sh` - 自動インストールメイン
- `scripts/post-install.sh` - 環境構築スクリプト

## 重要な技術的考慮事項

1. **ネットワーク接続の確認**: インストール開始前にpingテストで接続確認
2. **GPUドライバ**: インストール時にハードウェア検出し、適切なドライバを選択
3. **エラーハンドリング**: 各ステップで失敗時のログ出力とリトライ
4. **べき等性**: 途中で失敗しても再実行可能な設計
5. **セキュリティ**: パスワードは平文保存せず、インストール時のみ入力

## 成果物

1. カスタムArch Linux ISOイメージ (`archlinux-ztp.iso`)
2. USBブート可能なメディア作成手順
3. 完全な技術ドキュメント
4. VirtualBoxテスト環境
