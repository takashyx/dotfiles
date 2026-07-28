#!/usr/bin/env bash
# font モジュール (Mac): エディタ用フォントの導入
set -euo pipefail

# 通常版 (Moralerspace Neon) と HW 版 (Moralerspace Neon HW) の両方を導入する
#   "cask 名|導入判定に使う .ttf|表示名"
FONT_SETS=(
  "font-moralerspace|MoralerspaceNeon-Regular.ttf|Moralerspace Neon"
  "font-moralerspace-hw|MoralerspaceNeonHW-Regular.ttf|Moralerspace Neon HW"
)

if ! command -v brew >/dev/null 2>&1; then
  HAS_BREW=0
else
  HAS_BREW=1
fi

for entry in "${FONT_SETS[@]}"; do
  IFS='|' read -r CASK FONT_FILE FONT_FAMILY <<<"$entry"

  if [ -e "$HOME/Library/Fonts/$FONT_FILE" ] || [ -e "/Library/Fonts/$FONT_FILE" ]; then
    echo "==> フォント: $FONT_FAMILY はインストール済み"
  elif [ "$HAS_BREW" -eq 1 ]; then
    echo "==> フォント $FONT_FAMILY をインストールします ($CASK / 約 100MB)"
    brew install --cask "$CASK"
  else
    echo "==> 警告: brew が無いためフォント $FONT_FAMILY をスキップします"
    echo "    (https://github.com/yuru7/moralerspace のリリースから手動で導入してください)"
  fi
done
