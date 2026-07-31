#!/usr/bin/env bash
# zsh モジュール (Mac): .zshrc / sheldon の plugins.toml / ~/dotfiles リンクを配置
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
TARGET="$HOME/.zshrc"

# powerlevel10k (Homebrew 版。プロンプトテーマ本体は plugins.toml から source する)
if brew list --formula powerlevel10k >/dev/null 2>&1; then
  echo "==> powerlevel10k: インストール済み"
else
  echo "==> powerlevel10k をインストールします"
  brew install powerlevel10k
fi

# powerlevel10k 推奨フォント (MesloLGS NF 4書体)。ターミナル側のフォント設定は手動で行う
if brew list --cask font-meslo-for-powerlevel10k >/dev/null 2>&1; then
  echo "==> MesloLGS NF フォント: インストール済み"
else
  echo "==> MesloLGS NF フォントをインストールします"
  brew install --cask font-meslo-for-powerlevel10k
  echo "==> ターミナルのフォント設定を 'MesloLGS NF' に変更してください"
fi

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
  mv "$TARGET" "$TARGET.bak"
  echo "==> 既存の .zshrc を .zshrc.bak に退避しました"
fi
ln -sfn "$MODULE_DIR/.zshrc" "$TARGET"
echo "==> リンク作成: $TARGET -> $MODULE_DIR/.zshrc"

# sheldon (プラグインマネージャ) の設定ファイル
SHELDON_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sheldon"
SHELDON_TARGET="$SHELDON_DIR/plugins.toml"
mkdir -p "$SHELDON_DIR"
if [ -e "$SHELDON_TARGET" ] && [ ! -L "$SHELDON_TARGET" ]; then
  mv "$SHELDON_TARGET" "$SHELDON_TARGET.bak"
  echo "==> 既存の plugins.toml を plugins.toml.bak に退避しました"
fi
ln -sfn "$MODULE_DIR/plugins.toml" "$SHELDON_TARGET"
echo "==> リンク作成: $SHELDON_TARGET -> $MODULE_DIR/plugins.toml"

# ~/dotfiles : sheldon の dotfiles-sync プラグイン (zsh/plugins.toml) が
# 固定パス ~/dotfiles/zsh/sync を参照するため、リポジトリ本体へのリンクを用意する
DOTFILES_LINK="$HOME/dotfiles"
if [ "$(cd "$DOTFILES_LINK" 2>/dev/null && pwd -P)" = "$REPO_ROOT" ]; then
  : # 既に ~/dotfiles がリポジトリ本体 (実体 or 正しいリンク)
elif [ -e "$DOTFILES_LINK" ] && [ ! -L "$DOTFILES_LINK" ]; then
  echo "==> 警告: $DOTFILES_LINK は既存の実ディレクトリのため触れません。" >&2
  echo "    sheldon の dotfiles-sync プラグインが動かない可能性があるので手動で確認してください。" >&2
else
  ln -sfn "$REPO_ROOT" "$DOTFILES_LINK"
  echo "==> リンク作成: $DOTFILES_LINK -> $REPO_ROOT"
fi

# powerlevel10k の設定ファイル (`p10k configure` で生成)
# 初回はリポジトリ側に zsh/p10k.zsh が無いのでスキップする。
# `p10k configure` 実行後、生成された ~/.p10k.zsh を zsh/p10k.zsh として
# リポジトリに追加してから setup.sh を再実行するとリンクされる。
P10K_SRC="$MODULE_DIR/p10k.zsh"
P10K_TARGET="$HOME/.p10k.zsh"
if [ -e "$P10K_SRC" ]; then
  if [ -e "$P10K_TARGET" ] && [ ! -L "$P10K_TARGET" ]; then
    mv "$P10K_TARGET" "$P10K_TARGET.bak"
    echo "==> 既存の .p10k.zsh を .p10k.zsh.bak に退避しました"
  fi
  ln -sfn "$P10K_SRC" "$P10K_TARGET"
  echo "==> リンク作成: $P10K_TARGET -> $P10K_SRC"
fi
