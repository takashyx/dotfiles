#!/usr/bin/env bash
# vscode モジュール (Mac): settings.json のリンク / 拡張機能 / フォントの導入
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_DIR="$HOME/Library/Application Support/Code/User"

# settings.json の editor.fontFamily で指定しているフォント
FONT_CASK="font-moralerspace-hw"
FONT_FILE="MoralerspaceNeonHW-Regular.ttf"
FONT_FAMILY="Moralerspace Neon HW"

# 1. settings.json をシンボリックリンク (既存の実ファイルは .bak に退避)
mkdir -p "$USER_DIR"
if [ -e "$USER_DIR/settings.json" ] && [ ! -L "$USER_DIR/settings.json" ]; then
  if cmp -s "$USER_DIR/settings.json" "$MODULE_DIR/settings.json"; then
    echo "==> settings.json: 配置済み (最新)"
  elif [ -e "$USER_DIR/settings.json.bak" ]; then
    # dotfiles 導入前の設定を保持したいので、既存の .bak は上書きしない
    echo "==> settings.json.bak は既にあるため退避をスキップします"
    echo "    (未取り込みの変更があるなら update.sh を先に実行してください)"
  else
    mv "$USER_DIR/settings.json" "$USER_DIR/settings.json.bak"
    echo "==> 既存の settings.json を settings.json.bak に退避しました"
  fi
fi
ln -sfn "$MODULE_DIR/settings.json" "$USER_DIR/settings.json"
echo "==> リンク作成: $USER_DIR/settings.json -> $MODULE_DIR/settings.json"

# 2. 拡張機能のインストール (extensions.txt との差分のみ)
if ! command -v code >/dev/null 2>&1; then
  echo "==> 警告: code コマンドが見つからないため拡張機能をスキップします"
  echo "    (VSCode の コマンドパレット > \"Shell Command: Install 'code' command in PATH\" を実行してください)"
else
  WANTED=()
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"   # 先頭の空白を除去
    line="${line%"${line##*[![:space:]]}"}"   # 末尾の空白を除去
    case "$line" in ''|\#*) continue ;; esac
    WANTED+=("$line")
  done < "$MODULE_DIR/extensions.txt"

  INSTALLED="$(code --list-extensions)"
  MISSING=()
  for ext in "${WANTED[@]}"; do
    if ! grep -qix -- "$ext" <<<"$INSTALLED"; then
      MISSING+=("$ext")
    fi
  done

  if [ "${#MISSING[@]}" -eq 0 ]; then
    echo "==> 拡張機能: ${#WANTED[@]} 件すべてインストール済み"
  else
    echo "==> 拡張機能: ${#MISSING[@]} 件をインストールします"
    for ext in "${MISSING[@]}"; do
      code --install-extension "$ext" --force || echo "    [NG] $ext のインストールに失敗しました"
    done
  fi
fi

# 3. フォントのインストール (Homebrew Cask)
if [ -e "$HOME/Library/Fonts/$FONT_FILE" ] || [ -e "/Library/Fonts/$FONT_FILE" ]; then
  echo "==> フォント: $FONT_FAMILY はインストール済み"
elif command -v brew >/dev/null 2>&1; then
  echo "==> フォント $FONT_FAMILY をインストールします ($FONT_CASK / 約 100MB)"
  brew install --cask "$FONT_CASK"
else
  echo "==> 警告: brew が無いためフォント $FONT_FAMILY をスキップします"
  echo "    (https://github.com/yuru7/moralerspace のリリースから手動で導入してください)"
fi
