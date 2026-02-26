# ZTP プロジェクト 引き継ぎドキュメント

## プロジェクト概要

USB メモリから起動して最小限の質問に答えるだけで **Arch Linux + Hyprland** 環境が完全自動でセットアップされる ZTP (Zero Touch Provisioning) システム。

- **場所**: `/home/taka/ZTP/`
- **ステータス**: 基本インストール動作確認済み。GUI (SDDM + Hyprland) 自動起動は実装済みだが未テスト。

---

## 今日やったこと（2026-02-26）

| # | 対応内容 |
|---|---|
| 1 | 日本語フォント豆腐問題 → `fc-cache -fv` 追加 + fontconfig CJK 設定 |
| 2 | Live インストーラーの日本語表示不可 → 全ログを英語化 |
| 3 | `partprobe: command not found` → `parted` パッケージを追加 |
| 4 | `booting...` で止まる → `mkinitcpio -P` を明示実行、microcode 検出修正 |
| 5 | `vconsole.conf` が無くて mkinitcpio エラー → `/etc/vconsole.conf` 作成を追加 |
| 6 | ログインできない（パスワード問題） → `chpasswd` を廃止し `openssl passwd -6` + `usermod -p` に変更 |
| 7 | `set -euo pipefail` でユーザー作成前に止まる → `set -uo pipefail` に変更し各コマンドを個別チェック |
| 8 | ログが多すぎてデバッグ不可 → ユーザー作成後に枠付きサマリー表示 + `/tmp/ztp-install.log` にログ保存 |
| 9 | nucleus-shell の `./install` がディレクトリ問題 → yay をビルドして AUR から quickshell 取得に変更 |
| 10 | yay ビルド中に豆腐文字 → 全スクリプトに `LANG=C LC_ALL=C` を追加 |
| 11 | GUI が起動しない → `sddm` を追加、自動ログイン設定 (SDDM → Hyprland) を実装 |

---

## ディレクトリ構成

```
ZTP/
├── scripts/               # インストールスクリプト（開発用）
│   ├── install-dialog.sh  # 対話的インストーラー（英語UI）
│   ├── auto-install.sh    # メイン制御スクリプト（ログ: /tmp/ztp-install.log）
│   ├── partition.sh       # パーティション作成
│   ├── base-install.sh    # pacstrap でベースシステム
│   ├── bootloader-setup.sh # systemd-boot + mkinitcpio -P
│   ├── system-config.sh   # locale/hostname/user作成/fontconfig/vconsole
│   ├── package-install.sh # packages.txt から pacman インストール + fc-cache
│   ├── dotfiles-apply.sh  # yay ビルド → quickshell/matugen → nucleus-shell config
│   └── service-enable.sh  # NetworkManager/bluetooth/ufw/sddm 有効化
├── iso-build/
│   └── profile/           # archiso プロファイル（ここを編集してビルド）
│       ├── airootfs/root/ # ↑ scripts/ と同期させること
│       └── packages.x86_64 # Live 環境のパッケージ（parted 等）
├── packages.txt           # インストール対象パッケージ（sddm 含む）
└── build-iso.sh           # ISO ビルドスクリプト
```

> ⚠️ `scripts/` と `iso-build/profile/airootfs/root/*.sh` は**常に同期**が必要。
> スクリプト変更後は必ず両方に反映すること。

---

## ISO ビルド方法

```bash
cd /home/taka/ZTP
sudo ./build-iso.sh
# → iso-build/out/archlinux-ztp-YYYY.MM.DD-x86_64.iso が生成される
```

---

## VirtualBox テスト時の注意

- **EFI を必ず有効化**（設定 → システム → マザーボード → EFIを有効化）
  - 未設定だと `booting...` で止まる
- 3D アクセラレーションを有効化すると Wayland の描画が安定する
- ネットワーク: NAT で OK

---

## 未解決・次にやること

### 要テスト
- [ ] SDDM → Hyprland 自動ログインの動作確認（未テスト）
- [ ] ログイン後に日本語が正しく表示されるか確認（fontconfig 設定が効いているか）
- [ ] nucleus-shell / quickshell が正常に動作するか

### 既知の残課題
- [ ] `yay` ビルドに時間がかかる（インターネット速度次第で 10〜20 分）
- [ ] AUR パッケージ（quickshell, matugen-bin）のビルド失敗時のフォールバックが未整備
- [ ] GPU ドライバの自動判定（現状は mesa のみ、NVIDIA 環境は手動対応が必要）
- [ ] Hyprland の初期設定（arch-dotfiles の hypr/ が入るが、環境依存の調整が必要な場合あり）

### 中長期
- [ ] `oh-my-zsh` の自動インストール（現状コメントアウト）
- [ ] インストール後の動作確認チェックリストを自動化

---

## 重要な設定ファイルの場所（インストール後）

| ファイル | 内容 |
|---|---|
| `/etc/sddm.conf.d/10-ztp.conf` | SDDM 設定・自動ログイン |
| `/etc/fonts/conf.d/64-noto-cjk-jp.conf` | 日本語フォント優先設定 |
| `/etc/vconsole.conf` | コンソールキーマップ（KEYMAP=us） |
| `/usr/share/wayland-sessions/hyprland.desktop` | Hyprland セッション定義 |
| `~/.config/quickshell/nucleus-shell/` | nucleus-shell 設定 |

---

## インストール時のデバッグ

- **ログファイル**: `/tmp/ztp-install.log`（Live 環境内）
- **ユーザー確認**: Step 4 完了後に枠付きサマリーが表示される
  ```
  ╔══════════════════════════════════════════╗
  ║         USER CREATION SUMMARY           ║
  ╠══════════════════════════════════════════╣
  ║ passwd : taka:x:1000:1000::/home/taka:/bin/bash
  ║ shadow : OK (SHA-512 hash)
  ║ wheel  : wheel:x:998:taka
  ╚══════════════════════════════════════════╝
  ```
- **shadow が `INVALID` の場合**: `arch-chroot /mnt passwd taka` で手動設定可能
