# zsh モジュールの構成

```text
zsh/
├── .zshrc        # ~/.zshrc にリンク。sheldon の起動だけを行う
├── plugins.toml  # ~/.config/sheldon/plugins.toml にリンク。sheldon の設定
├── p10k.zsh      # ~/.p10k.zsh にリンク。`p10k configure` の生成物
└── sync/         # dotfiles-sync プラグインが即時 source する設定 (*.zsh)
    ├── functions.zsh
    ├── alias.zsh
    ├── history.zsh
    └── completion.zsh
```

`.zshrc` 本体は sheldon の起動 1 行のみで、実際の設定はすべて
`zsh/sync/*.zsh` に置く。sheldon の `plugins.toml` で `local` プラグイン
として `~/dotfiles/zsh/sync` 配下の `*.zsh` をまとめて読み込んでいる
(`~/dotfiles` は `setup.sh` が作るリポジトリ本体へのシンボリックリンク。
固定パスを使う sheldon の `local` 指定に合わせるため)。配置方法は
[../README.md](../README.md#zsh-モジュール-zshrc-の同期-mac-専用) を参照。

> [!NOTE]
> sheldon は `local` プラグインの glob 結果もロックファイルにキャッシュする。
> `zsh/sync/` に新しい `*.zsh` を追加しただけでは次回シェル起動時に反映
> されないことがあるため、その場合は `sheldon lock --update` を実行する。

## 前提となる外部ツール

無くても `command -v` でガードしているのでエラーにはならないが、
入っていると有効化される機能。

| ツール | 用途 | 未導入時の挙動 |
| --- | --- | --- |
| [sheldon](https://github.com/rossmacarthur/sheldon) | zsh プラグインマネージャ (`zsh/sync/` の読み込みも兼ねる) | `.zshrc` が何もしない |
| [powerlevel10k](https://github.com/romkatv/powerlevel10k) | プロンプトテーマ。`setup.sh` が Homebrew で導入する | プロンプトテーマが読み込まれず、zsh 標準の素のプロンプトになる |
| `MesloLGS NF` フォント (`font-meslo-for-powerlevel10k`) | powerlevel10k のアイコン表示。`setup.sh` が導入するが、ターミナルのフォント設定は手動変更が必要 | アイコンが文字化けして表示される |
| [eza](https://github.com/eza-community/eza) | `ls` の代替 (ツリー表示) | 通常の `ls` にフォールバック |
| [bat](https://github.com/sharkdp/bat) | `cat` の代替 (シンタックスハイライト) | 通常の `cat` のまま |
| `less` | `ls` の結果のページング | (macOS 標準搭載) |

## `.zshrc` (sheldon の起動)

```sh
command -v sheldon >/dev/null 2>&1 && eval "$(sheldon source)"
```

`sheldon` がインストールされていれば、その出力 (プラグイン読み込みスクリプト)
を `eval` する。

## plugins.toml のプラグイン構成

[`zsh/plugins.toml`](plugins.toml) は起動時間を短縮するため、
[zsh-defer](https://github.com/romkatv/zsh-defer) で重い処理を
「zle がアイドルになったタイミング」まで遅延させる構成になっている。
`sheldon source` が生成するスクリプトは以下の順で実行される
(この順序が重要。後述)。

| 順 | プラグイン | 内容 | 実行 |
| --- | --- | --- | --- |
| 1 | `zsh-defer` | [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer) 本体 | 即時 (これ以降が `zsh-defer` を使うための前提) |
| 2 | `powerlevel10k` | `$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme` を source (Homebrew でインストール) | 即時 (プロンプトはすぐ確定させたいので defer しない) |
| 3 | `powerlevel10k-config` | `~/.p10k.zsh` があれば source (`zsh/p10k.zsh` をリンクしたもの) | 即時 |
| 4 | `compinit` | `autoload -Uz compinit && zsh-defer compinit -u` | 呼び出しは即時、実体は遅延 |
| 5 | `colors` | `autoload -Uz colors && zsh-defer colors` | 呼び出しは即時、実体は遅延 |
| 6 | `zsh-autosuggestions` | 入力履歴からのサジェスト | 遅延 |
| 7 | `zsh-syntax-highlighting` | コマンドラインのシンタックスハイライト | 遅延 |
| 8 | `dotfiles-sync` | `zsh/sync/*.zsh` | 即時 |

`zsh-defer` の遅延タスクは登録順 (= このテーブルの順) に実行される。
プロンプトは powerlevel10k が管理するため (旧 `check_git_status` を使った
自作プロンプトは廃止)、`colors` などへの依存を気にする必要はない。

powerlevel10k は `setup.sh` が `brew install powerlevel10k` でインストール
する。設定ファイルは `p10k configure` で対話的に生成される
[`zsh/p10k.zsh`](p10k.zsh) で、`~/.zshrc` などと同じくリンク運用
(`setup.sh` が `~/.p10k.zsh` にリンクする)。見た目を変えたい場合は
`p10k configure` を再実行し、生成し直された `~/.p10k.zsh` を
`zsh/p10k.zsh` に上書きコピーしてコミットする。

プラグインの追加は `sheldon add <name> --github <owner/repo>` するか
`plugins.toml` を直接編集し、`sheldon lock` (または新しいシェルの起動) で
反映する。

## zsh/sync/ の各ファイル解説

### `functions.zsh`

- `gri <pattern>` : `grep -rnIi` のショートカット (再帰・大文字小文字無視・
  バイナリ除外)。
- `fii <pattern>` : `find .` の結果を大文字小文字無視でフィルタ。
- `findlnfrom <path>` : `/` 以下のシンボリックリンクを総当たりで探索し、
  リンク先が `<path>` と一致するものを列挙する (実行コストが高いので注意。
  権限のないディレクトリのエラーは `2>/dev/null` で抑制している)。

#### `chpwd` (ターミナルタイトルへのカレントディレクトリ反映)

```sh
chpwd () {print -Pn "\e]2; %~/ \a"}
```

ディレクトリ移動のたびにエスケープシーケンスでウィンドウタイトルを更新し、
macOS のターミナルがウィンドウ復元時に cwd を復元できるようにする。

### `alias.zsh` (`ls` / `cat` の代替コマンド)

```sh
if command -v eza >/dev/null 2>&1; then
  function ls { eza -lT --color=always "$@" | less -FRX ; }
else
  function ls { CLICOLOR_FORCE=1 command ls -alFG "$@" | less -FRX ; }
fi
command -v bat >/dev/null 2>&1 && alias cat='bat'
```

- `eza` があれば `-l` (詳細表示) `-T` (ツリー表示) で実行し、無ければ通常の
  `ls -alFG` (全ファイル・詳細・種別記号・色付き) にフォールバックする。
  いずれも結果を `less -FRX` に渡す
  (`-F`: 1画面に収まるならページャを起動せずそのまま表示 /
  `-R`: 色エスケープをそのまま解釈 / `-X`: 終了時に画面をクリアしない)。
  `CLICOLOR_FORCE` は `ls -G` がパイプ先 (非 tty) では自動的に色を無効化する
  ため、それを強制的に有効化するために付けている。
- `bat` があれば `cat` を丸ごと置き換える (シンタックスハイライト表示)。
- 引数はどちらも `"$@"` でそのまま透過するので、`ls <dir>` のような通常の
  使い方ができる (alias ではなく function にしているのはこのため。
  alias だと引数がパイプ末尾の `less` に渡ってしまい壊れる)。

続くセーフティ alias:

```sh
alias cp='cp -i' # safety
alias mv='mv -i' # safety
alias rm='rm -i' # safety
```

`cp` / `mv` / `rm` は上書き前に確認する。

### `history.zsh`

```sh
setopt extended_history       # zsh の開始, 終了時刻をヒストリファイルに書き込む
setopt share_history          # ヒストリを共有
setopt hist_verify            # ヒストリを呼び出してから実行する間に一旦編集
setopt hist_ignore_dups       # 重複を無視
```

複数ターミナル間でヒストリを共有し (`share_history`)、履歴呼び出し時は
即実行せず編集可能にする (`hist_verify`)。`HISTFILE` / `HISTSIZE` /
`SAVEHIST` は明示していないため zsh のデフォルト
(`~/.zsh_history` / 2000 / 1000) に依存する。

### `completion.zsh`

`compinit` の呼び出しは `plugins.toml` の `[plugins.compinit]` (遅延実行) 側に
移したため、ここには補完のスタイル・オプション設定のみを置く。

```sh
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

setopt correct               # スペルチェック
setopt auto_menu             # TAB で順に補完候補を切り替える
setopt auto_list             # 補完候補を一覧表示
setopt list_packed           # 補完候補を詰めて表示
setopt list_types            # 補完候補一覧でファイルの種別をマーク表示
setopt noautoremoveslash     # 最後のスラッシュを自動的に削除しない
setopt auto_param_keys       # カッコの対応などを自動的に補完
setopt magic_equal_subst     # --prefix=/usr などの = 以降も補完
unsetopt promptcr            # 出力の文字列末尾に改行コードが無い場合でも表示
setopt numeric_glob_sort     # ファイル名の展開で辞書順ではなく数値的にソート
setopt print_eight_bit       # 出力時8ビットを通す
```

- 補完候補の色付けは `LS_COLORS` を参照する (GNU 形式。macOS 標準の `ls -G`
  は `LSCOLORS` (BSD 形式) を使うため、`LS_COLORS` が未設定だと補完候補の
  色付けだけ効かない)。
- `sudo <TAB>` でも一般ユーザーの PATH が通っていないディレクトリ
  (`/usr/local/sbin` 等) のコマンドを補完できるようにしている。
- `matcher-list` により大文字小文字を区別せず補完できる
  (先頭が大文字の場合は大文字のみにマッチ)。

## プロンプト (powerlevel10k)

プロンプトは自作コードではなく [powerlevel10k](https://github.com/romkatv/powerlevel10k)
に任せている。`setup.sh` が `brew install powerlevel10k` で導入し、
`plugins.toml` が `$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme`
を source する。

アイコン等のグリフ表示には powerlevel10k 推奨の `MesloLGS NF` フォント
(4書体) が必要。`setup.sh` が `font-meslo-for-powerlevel10k` cask で導入
するが、**ターミナル (iTerm2 など) 側のフォント設定を手動で `MesloLGS NF`
に変更する必要がある** (自動化不可)。

`zsh/p10k.zsh` (= `~/.p10k.zsh`) が無い状態でシェルを起動すると、対話式の
`p10k configure` ウィザードが自動的に起動する (見た目・表示項目を選ぶだけの
質問形式)。見た目を変えたくなったら `p10k configure` を再実行し、
生成し直された `~/.p10k.zsh` を `zsh/p10k.zsh` に上書きコピーしてコミット
する。
