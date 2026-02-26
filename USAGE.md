# USB-Based ZTP System - 使用方法とテストガイド

## ISOのビルド

カスタムArch Linux ISOをビルドします：

```bash
cd /home/taka/ZTP
sudo ./build-iso.sh
```

ビルドには10-20分程度かかります。完成したISOは `/home/taka/ZTP/iso-build/out/` に生成されます。

## USBメディアの作成

### 方法1: ddコマンド（推奨）

```bash
# USBデバイスを確認（例: /dev/sdb）
lsblk

# ISOをUSBに書き込み（/dev/sdXは実際のデバイス名に置き換える）
sudo dd if=/home/taka/ZTP/iso-build/out/archlinux-ztp-*.iso of=/dev/sdX bs=4M status=progress && sync
```

**警告**: `/dev/sdX` は必ず正しいUSBデバイスを指定してください。間違えるとデータが消失します。

### 方法2: Ventoy（マルチブート可能）

1. [Ventoy](https://www.ventoy.net/)をUSBにインストール
2. ISOファイルをVentoyのパーティションにコピー
3. 起動時にISOを選択

## VirtualBoxでのテスト

### VM作成

1. VirtualBox を開く
2. 新規VM作成:
   - 名前: Arch-ZTP-Test
   - タイプ: Linux
   - バージョン: Arch Linux (64-bit)
   - メモリ: 4096 MB以上
   - ディスク: 30 GB以上（新規作成）
3. 設定 → システム → 起動順序: 光学ドライブを最優先
4. 設定 → ストレージ → 光学ドライブにISOをマウント
5. 設定 → ネットワーク → アダプター1: NAT または ブリッジ

### テスト実行

1. VMを起動
2. Arch Linux ZTP ISOが起動
3. 自動的に対話的インストーラーが起動
4. 以下の質問に答える:
   - ネットワーク接続確認
   - インストール先ディスク選択（例: /dev/sda）
   - ホスト名（例: archlinux-ztp）
   - ユーザー名（例: taka）
   - ユーザーパスワード
   - rootパスワード
   - タイムゾーン（例: Asia/Tokyo）
   - ロケール（例: ja_JP.UTF-8）
5. 確認後、自動インストール開始
6. 完了後、自動的に再起動
7. ログインして環境を確認

### 動作確認項目

- [ ] Hyprlandが起動する
- [ ] kittyターミナルが起動する
- [ ] ネットワーク接続が動作する
- [ ] dotfilesが適用されている
- [ ] nucleus-shellがインストールされている
- [ ] zshがデフォルトシェルになっている

## 実機でのテスト

1. USBメモリを作成
2. 有線LANケーブルを接続
3. BIOSでUSBブート優先順位を最上位に設定
4. USBから起動
5. VirtualBoxと同じ手順でインストール

## トラブルシューティング

### ネットワーク接続エラー

```bash
# Live環境でネットワークを確認
ip link
ip addr
ping archlinux.org

# 手動でDHCP取得
dhcpcd
```

### パッケージインストールエラー

- ミラーサーバーが遅い場合: reflectorで最適化
- 特定のパッケージが見つからない: packages.txtを確認

### ビルドエラー

```bash
# workディレクトリをクリーンアップ
sudo rm -rf /home/taka/ZTP/iso-build/work

# 再ビルド
sudo ./build-iso.sh
```

### ディスク認識エラー

- NVMeディスク: `/dev/nvme0n1p1`, `/dev/nvme0n1p2`
- SATA/HDD: `/dev/sda1`, `/dev/sda2`
- スクリプトは自動判定しますが、確認してください

## カスタマイズ

### パッケージの追加・削除

`packages.txt` を編集してからISOを再ビルド：

```bash
vim /home/taka/ZTP/packages.txt
sudo ./build-iso.sh
```

### スクリプトの変更

`/home/taka/ZTP/scripts/` 内のスクリプトを編集後、再ビルド：

```bash
vim /home/taka/ZTP/scripts/dotfiles-apply.sh
# スクリプトをairootfsにコピー
cp /home/taka/ZTP/scripts/*.sh /home/taka/ZTP/iso-build/profile/airootfs/root/
# 再ビルド
sudo ./build-iso.sh
```

## セキュリティ考慮事項

- パスワードは平文保存されません（一時的にメモリ内のみ）
- UFWファイアウォールが自動的に有効化されます
- デフォルトではSSHポートは閉じられています
- 必要に応じて `scripts/service-enable.sh` でSSH許可を追加

## 次のステップ

1. VirtualBoxでテストしてすべて動作することを確認
2. 実機用のUSBメディアを作成
3. テスト用の実機でインストール
4. 本番環境にデプロイ
