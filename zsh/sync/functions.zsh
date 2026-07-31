# custom grep (ignore case)
function gri { grep -rnIi "$1" . --color=always ; }

# custom find (ignore case)
function fii { find . | grep -i "$1" --color=always ; }

# /配下のシンボリックリンクを再帰的に探索し、リンク先が $1 と一致するものを列挙する
function findlnfrom {
  find / -type l 2>/dev/null | while read -r LINK; do
    readlink "$LINK" | grep -Fx "$1" >/dev/null && echo "$LINK"
  done
}

# escape sequence to tell pwd so that OSX terminal can restore it
chpwd () {print -Pn "\e]2; %~/ \a"}
