#!/usr/bin/env bash
# nvim モジュール (Mac): macism のインストールと init.lua のリンク
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

# 1. macism (Homebrew)
if command -v macism >/dev/null 2>&1; then
  echo "==> macism: インストール済み"
else
  echo "==> macism をインストールします"
  brew install laishulu/homebrew/macism
fi

# 2. init.lua をシンボリックリンク (既存の実ファイルは .bak に退避)
mkdir -p "$NVIM_DIR"
if [ -e "$NVIM_DIR/init.lua" ] && [ ! -L "$NVIM_DIR/init.lua" ]; then
  mv "$NVIM_DIR/init.lua" "$NVIM_DIR/init.lua.bak"
  echo "==> 既存の init.lua を init.lua.bak に退避しました"
fi
ln -sfn "$MODULE_DIR/init.lua" "$NVIM_DIR/init.lua"
echo "==> リンク作成: $NVIM_DIR/init.lua -> $MODULE_DIR/init.lua"

echo "==> 初回の IME 切り替え時に macOS がアクセシビリティ権限を求めた場合は、"
echo "    VSCode (または使用中のターミナル) に権限を付与してください。"
