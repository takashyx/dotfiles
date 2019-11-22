# macbook pro 16 2019

# go
export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin


# load zsh-notify(customed)
# export SYS_NOTIFIER="/usr/local/bin/terminal-notifier"
# export NOTIFY_COMMAND_COMPLETE_TIMEOUT=1
# source ~/zsh-notify/notify.plugin.zsh


# show gif
# function command_not_found_handler() {
#   echo "$@ : command not found..." 1>&2
#   if [ -e /Users/takashyx/.iterm2/imgcat ];then
#     if [ -e /Users/takashyx/fail.gif ];then
#       /Users/takashyx/.iterm2/imgcat /Users/takashyx/fail.gif
#     fi
#   fi
#   return 127
# }

# custom grep (ignore case)
function gri { grep -rnIi "$1" . --color=always ; }

# custom find (ignore case)
function fii { find . | grep -i "$1" --color=always ; }

function findlnfrom {
  find / -type l | while read LINK; do
  readlink "$LINK" | grep -Fx $1 >/dev/null && echo "$LINK"
  done
}

# escape sequence to tell pwd so that OSX terminal can restore it
#
chpwd () {print -Pn "\e]2; %~/ \a"}

# fzf
export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=header,grid --line-range :100 {}' --height 80% --reverse --border"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'" # show directory tree


# fbr - checkout git branch
function fzf-checkout-branch() {
  local branches branch
  branches=$(git branch -r | sed -e 's/\(^\* \|^  \)//g' | cut -d " " -f 1) &&
  branch=$(echo "$branches" | fzf --preview "git show --color=always {}") &&
  git checkout $(echo "$branch")
}
zle     -N   fzf-checkout-branch
bindkey "^b" fzf-checkout-branch

# alias

alias ls='ls -alFG'
alias cp='cp -i' # safety
alias mv='mv -i' # safety
alias rm='rm -i' # safety

alias gcd='ghq look `ghq list |fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*"`' # ghq look with readme preview
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


### Added by Zplugin's installer
source "$HOME/.zplugin/bin/zplugin.zsh"
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin installer's chunk

zplugin light zsh-users/zsh-completions
zplugin light zsh-users/zsh-autosuggestions
zplugin light zdharma/fast-syntax-highlighting
zplugin light bhilburn/powerlevel9k

# rbenv
eval "$(rbenv init -)"

