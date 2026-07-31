## 補完候補をカラー表示
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion::complete:*' use-cache true

## コマンドにsudoを付けても補完
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
## スペルチェック
setopt correct
## TAB で順に補完候補を切り替える
setopt auto_menu
## 補完候補を一覧表示
setopt auto_list
## 補完候補を詰めて表示
setopt list_packed
## 補完候補一覧でファイルの種別をマーク表示
setopt list_types
## 最後のスラッシュを自動的に削除しない
setopt noautoremoveslash
## 大文字，小文字を区別しないで補完（大文字は開始は大文字限定）
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## カッコの対応などを自動的に補完
setopt auto_param_keys
## --prefix=/usr などの = 以降も補完
setopt magic_equal_subst
## 出力の文字列末尾に改行コードが無い場合でも表示
unsetopt promptcr
## ファイル名の展開で辞書順ではなく数値的にソート
setopt numeric_glob_sort
## 出力時8ビットを通す
setopt print_eight_bit
