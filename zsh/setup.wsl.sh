#!/usr/bin/env bash
# zsh モジュール (WSL): .zshrc / sheldon の plugins.toml / ~/dotfiles リンクを配置
# Mac 版 (setup.sh) との違い:
#   - powerlevel10k は Homebrew ではなく ~/.local/share へ git clone する
#   - sheldon が無ければ ~/.local/bin へプレビルドバイナリを導入する
#   - フォントは Windows 側のターミナルが描画するため導入しない (NOTE で案内)
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
TARGET="$HOME/.zshrc"

# zsh 本体 (WSL の Ubuntu などは未導入のことがある)
if command -v zsh >/dev/null 2>&1; then
  echo "==> zsh: インストール済み"
else
  echo "==> 警告: zsh が見つかりません" >&2
  echo "NOTE: zsh が未インストールです。'sudo apt install zsh' の後、'chsh -s \$(which zsh)' でログインシェルに設定してください"
fi

# sheldon (プラグインマネージャ)。~/.local/bin へ導入する (.zshrc が PATH に追加する)
if command -v sheldon >/dev/null 2>&1 || [ -x "$HOME/.local/bin/sheldon" ]; then
  echo "==> sheldon: インストール済み"
else
  echo "==> sheldon をインストールします (~/.local/bin)"
  mkdir -p "$HOME/.local/bin"
  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo rossmacarthur/sheldon --to "$HOME/.local/bin"
fi

# powerlevel10k (プロンプトテーマ本体は plugins.toml が OS 判定して source する)
P10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
  echo "==> powerlevel10k: インストール済み ($P10K_DIR)"
else
  echo "==> powerlevel10k を clone します ($P10K_DIR)"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# powerlevel10k 推奨フォント (MesloLGS NF) は Windows 側のターミナルが描画するため
# WSL 内には導入せず、Windows 側での手動導入を案内する
echo "NOTE: フォントは Windows 側に MesloLGS NF (https://github.com/romkatv/powerlevel10k#fonts) を導入し、Windows Terminal 等のフォントに設定してください"

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
# リポジトリに追加してから setup.wsl.sh を再実行するとリンクされる。
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
