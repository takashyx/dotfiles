#!/usr/bin/env bash
# vscode モジュール (Mac): 現在の VSCode 設定をリポジトリへ取り込む
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE="$HOME/Library/Application Support/Code/User/settings.json"
REPO="$MODULE_DIR/settings.json"
TXT="$MODULE_DIR/extensions.txt"

# code コマンド確認・有効化
source "$MODULE_DIR/lib/ensure-code-command.sh"
echo ""

# 1. settings.json の取り込み
if [ ! -e "$LIVE" ]; then
  echo "==> 警告: $LIVE が見つかりません (setup.sh 未実行?)"
elif [ -L "$LIVE" ]; then
  # リンク運用ならリポジトリのファイル自体が書き換わっているので取り込み不要
  echo "==> settings.json: リンク運用のため取り込み不要"
elif cmp -s "$LIVE" "$REPO"; then
  echo "==> settings.json: 変更なし"
else
  cp "$LIVE" "$REPO"
  echo "==> settings.json を取り込みました: $LIVE"
fi

# 2. extensions.txt の取り込み
if ! command -v code >/dev/null 2>&1; then
  echo "==> 警告: code コマンドが見つからないため拡張機能をスキップします"
else
  LIST="$(code --list-extensions | grep -v '^$' | sort)"
  if [ -z "$LIST" ]; then
    echo "==> エラー: code --list-extensions が空を返しました" >&2
    exit 1
  fi
  COUNT="$(printf '%s\n' "$LIST" | wc -l | tr -d ' ')"

  TMP="$(mktemp "${TMPDIR:-/tmp}/extensions.XXXXXX")"
  # 既存ファイル先頭のコメント行 (ヘッダ) は維持する
  if [ -f "$TXT" ]; then
    awk '/^[[:space:]]*#/ { print; next } { exit }' "$TXT" > "$TMP"
  fi
  printf '%s\n' "$LIST" >> "$TMP"

  if [ -f "$TXT" ] && cmp -s "$TMP" "$TXT"; then
    echo "==> extensions.txt: 変更なし ($COUNT 件)"
    rm -f "$TMP"
  else
    mv "$TMP" "$TXT"
    chmod 644 "$TXT"
    echo "==> extensions.txt を更新しました ($COUNT 件)"
  fi
fi
