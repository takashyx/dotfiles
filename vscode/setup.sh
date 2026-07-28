#!/usr/bin/env bash
# vscode モジュール (Mac): 何も配置せず、移行済みであることをサマリに伝えるだけ
#   settings.json / 拡張機能は VSCode 内蔵の Settings Sync で同期する。
#   NOTE: で始まる行はエントリポイントが拾ってサマリに表示する。
set -euo pipefail

echo "NOTE: VSCode の設定は VSCode 内蔵の Settings Sync に移行しました"
