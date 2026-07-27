#!/usr/bin/env bash
# vscode: code コマンド確認・有効化 (共通ロジック)
# 他のスクリプトから source で読み込む
#   source "$MODULE_DIR/lib/ensure-code-command.sh"

if command -v code >/dev/null 2>&1; then
  echo "==> code コマンド: 有効化済み"
else
  echo "==> code コマンドが見つかりません。有効化を試みます"
  VS_CODE_APP="/Applications/Visual Studio Code.app"
  if [ -d "$VS_CODE_APP" ]; then
    echo "==> code コマンドを PATH に追加します"
    sudo ln -sfn "$VS_CODE_APP/Contents/Resources/app/bin/code" /usr/local/bin/code
    if command -v code >/dev/null 2>&1; then
      echo "==> code コマンドを有効化しました"
    else
      echo "==> 警告: code コマンドの有効化に失敗しました"
    fi
  else
    echo "==> 警告: VS Code がインストールされていないようです"
  fi
fi
