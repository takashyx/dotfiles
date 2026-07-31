# alias
if command -v eza >/dev/null 2>&1; then
  # -l: 詳細表示 / -T: ツリー表示 (-L 2 で深さ制限。無制限だと大きいディレクトリで
  # 実質固まったように見えるほど時間がかかることがある)。結果を less でページング表示する
  # 引数無しのときは "." を明示的に渡す (eza は無引数だと何も出力しないことがある)
  function ls { eza -lT -L 2 --color=always "${@:-.}" | less -FRX ; }
else
  # ls -alFG の結果を less でページング表示する (CLICOLOR_FORCE で非 tty でも色を強制)
  # -F: 1画面に収まるならページャを起動せずそのまま表示 / -R: 色エスケープをそのまま解釈 / -X: 終了時に画面をクリアしない
  function ls { CLICOLOR_FORCE=1 command ls -alFG "$@" | less -FRX ; }
fi
# cat の代わりに bat (シンタックスハイライト付き) があれば使う
command -v bat >/dev/null 2>&1 && alias cat='bat'
alias cp='cp -i' # safety
alias mv='mv -i' # safety
alias rm='rm -i' # safety
