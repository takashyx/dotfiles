# ユーザーローカルの bin (WSL では setup.wsl.sh が sheldon を ~/.local/bin に導入する)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# プラグインマネージャ (sheldon)。設定は ~/.config/sheldon/plugins.toml (zsh/plugins.toml)
# dotfiles-sync プラグインが zsh/sync/*.zsh をまとめて source する
# (~/.p10k.zsh の source は plugins.toml の powerlevel10k-config プラグインが行う)
command -v sheldon >/dev/null 2>&1 && eval "$(sheldon source)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
