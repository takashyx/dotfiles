# alias
if command -v eza >/dev/null 2>&1; then
  # -l: 詳細表示
  # 引数無しのときは "." を明示的に渡す (eza は無引数だと何も出力しないことがある)
  function ls { eza -l --color=always "${@:-.}" ; }
else
  # -F: ファイル種別を示す記号を付与 / -G: 色付け (CLICOLOR_FORCE で非 tty でも色を強制)
  function ls { CLICOLOR_FORCE=1 command ls -alFG "$@" ; }
fi
# cat の代わりに bat (シンタックスハイライト付き) があれば使う
command -v bat >/dev/null 2>&1 && alias cat='bat'
alias cp='cp -i' # safety
alias mv='mv -i' # safety
alias rm='rm -i' # safety
