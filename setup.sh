#!/usr/bin/env bash
# =====================================================================
# dotfiles セットアップエントリポイント (Mac / Linux)
#   各モジュールフォルダ直下の setup.sh を順に実行する。
#   新しい設定を追加するときは、フォルダを作って setup.sh を置くだけでよい。
#   モジュールが失敗しても残りは続行し、最後に結果をサマリー表示する。
# 実行例: bash setup.sh
# =====================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODULES=()
RESULTS=()
FAILED=0

for script in "$REPO_ROOT"/*/setup.sh; do
  [ -f "$script" ] || continue
  module="$(basename "$(dirname "$script")")"
  echo ""
  echo "========== モジュール: $module =========="
  if bash "$script"; then
    MODULES+=("$module")
    RESULTS+=("成功")
  else
    MODULES+=("$module")
    RESULTS+=("失敗")
    FAILED=1
  fi
done

# 色付き出力 (端末出力時のみ有効化。パイプ/リダイレクト時は無色)
if [ -t 1 ]; then
  C_GREEN=$'\033[32m'
  C_RED=$'\033[31m'
  C_CYAN=$'\033[36m'
  C_RESET=$'\033[0m'
else
  C_GREEN='' C_RED='' C_CYAN='' C_RESET=''
fi

echo ""
echo "${C_CYAN}========== セットアップ結果 ==========${C_RESET}"
if [ "${#MODULES[@]}" -eq 0 ]; then
  echo "  実行されたモジュールはありません"
else
  for i in "${!MODULES[@]}"; do
    if [ "${RESULTS[$i]}" = "成功" ]; then
      echo "  ${C_GREEN}[OK] ${MODULES[$i]}: 成功${C_RESET}"
    else
      echo "  ${C_RED}[NG] ${MODULES[$i]}: 失敗${C_RESET}"
    fi
  done
fi

exit "$FAILED"
