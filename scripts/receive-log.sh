#!/usr/bin/env bash
# ホスト側ログ受信スクリプト
# VMからのインストールログを受け取ってファイルに保存する
# VirtualBox NAT環境では VM から 10.0.2.2:9999 でこのサーバーに届く
#
# 使い方:
#   ./scripts/receive-log.sh
#   → vm-logs/YYYYMMDD-HHMMSS.log に保存される

set -euo pipefail

PORT=9999
LOG_DIR="$(cd "$(dirname "$0")/.." && pwd)/vm-logs"
mkdir -p "$LOG_DIR"

echo "=== ZTP Log Receiver ==="
echo "Listening on 0.0.0.0:${PORT}"
echo "Logs will be saved to: ${LOG_DIR}/"
echo "Stop with Ctrl+C"
echo

python3 - <<PYEOF
import http.server, datetime, os, sys

LOG_DIR = "${LOG_DIR}"
PORT    = ${PORT}

class LogReceiver(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        data   = self.rfile.read(length)
        ts     = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        path   = os.path.join(LOG_DIR, f'{ts}.log')
        with open(path, 'wb') as f:
            f.write(data)
        self.send_response(200)
        self.end_headers()
        print(f'\n[Saved] {path} ({len(data)} bytes)', flush=True)

    def log_message(self, fmt, *args):
        # POST 受信のみ表示、GET等のノイズは抑制
        if args and '\"POST' in str(args[0]):
            print(f'[{self.address_string()}] {fmt % args}', flush=True)

try:
    server = http.server.HTTPServer(('0.0.0.0', PORT), LogReceiver)
    server.serve_forever()
except KeyboardInterrupt:
    print('\nStopped.')
PYEOF
