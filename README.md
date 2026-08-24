# dotfiles

Mac / Windows / WSL 共通の設定ファイルをモジュール単位(フォルダ単位)で管理する。

## 構成

``` text
dotfiles/
├── setup.sh        # 配置エントリポイント (Mac): 各フォルダの setup.sh を順に実行
├── setup.wsl.sh    # 配置エントリポイント (WSL): 各フォルダの setup.wsl.sh を順に実行
├── setup.ps1       # 配置エントリポイント (Windows): 各フォルダの setup.ps1 を順に実行
├── capture.sh      # 取り込みエントリポイント (Mac): 各フォルダの capture.sh を順に実行
├── capture.ps1     # 取り込みエントリポイント (Windows): 各フォルダの capture.ps1 を順に実行
├── nvim/           # Neovim (vscode-neovim) モジュール
│   ├── init.lua    # OS 共通設定 (IME 自動オフ)
│   ├── setup.sh    # Mac 用: macism インストール + init.lua リンク
│   └── setup.ps1   # Windows 用: zenhan 配置 + init.lua リンク
├── zsh/            # zsh モジュール (Mac / WSL)
│   ├── .zshrc         # ~/.zshrc にリンク (sheldon の起動のみ)
│   ├── plugins.toml   # ~/.config/sheldon/plugins.toml にリンク (sheldon の設定。powerlevel10k 等)
│   ├── p10k.zsh       # ~/.p10k.zsh にリンク (`p10k configure` の生成物)
│   ├── sync/          # sheldon が即時 source する実体設定 (*.zsh)
│   ├── setup.sh       # Mac 用: 上記のリンク + brew install powerlevel10k + フォント + ~/dotfiles リンクを作成
│   └── setup.wsl.sh   # WSL 用: 上記のリンク + sheldon / powerlevel10k 導入 + ~/dotfiles リンクを作成
├── font/           # フォントモジュール (Moralerspace Neon / Neon HW の両方)
│   ├── setup.sh    # Mac 用: brew cask で導入
│   └── setup.ps1   # Windows 用: リリース zip をユーザー領域へ展開 + HKCU 登録
├── vscode/         # VSCode モジュール (何も配置しない。移行済みの案内のみ)
│   ├── setup.sh    # Mac 用: Settings Sync へ移行済みの NOTE を出力するだけ
│   └── setup.ps1   # Windows 用: 同上
└── autohotkey/     # AutoHotkey モジュール (Windows 専用)
    ├── alt-ime_and_leftshiftesc-tilda_ahk_v3.ahk   # Alt 空打ちで IME 切替 (左=英数 / 右=かな) + Shift+Esc でチルダ
    ├── launch_alt-ime.bat   # .ahk 起動用ランチャ
    └── setup.ps1   # Windows 用: ~/dotfiles へ配置 + スタートアップ登録 (setup.sh なし = Mac ではスキップ)
```

方向は 2 つあり、どちらもフォルダ単位で自動的に呼び出される。

| コマンド | 方向 | 用途 |
| --- | --- | --- |
| `setup.sh` / `setup.wsl.sh` / `setup.ps1` | リポジトリ → マシン | 新しいマシンに設定を展開する |
| `capture.sh` / `capture.ps1` | マシン → リポジトリ | 手元で変えた設定をリポジトリに取り込む |

> [!IMPORTANT]
> `capture` は**リポジトリ側のファイルを現在のマシンの状態で上書きする**コマンドで、
> 「リポジトリの最新をマシンに反映する」ものではない (それは `setup` の役割)。

新しい設定を追加するときは、フォルダを作って `setup.sh` / `setup.wsl.sh` / `setup.ps1` を置くだけでよい。
取り込みも自動化したければ、あわせて `capture.sh` / `capture.ps1` を置く
(置かないモジュールは単にスキップされる)。

### NOTE 行 (サマリへの伝達)

モジュールが `NOTE: ...` という行を標準出力へ書くと、その行はモジュールの実行ログには
表示されず、最後のサマリに `- ...` として黄色で表示される。
毎回の実行で必ず目に入れたい注意書き (移行済みの案内など) に使う。

```text
========== セットアップ結果 ==========
  [OK] vscode: 成功
       - VSCode の設定は VSCode 内蔵の Settings Sync に移行しました
```

## セットアップ

Mac:

```sh
bash setup.sh
```

WSL (WSL 内のシェルから):

```sh
bash setup.wsl.sh
```

リポジトリは Windows 側の `/mnt/c/...` にあるままでよい (各リンクがそこを指す)。
シェルスクリプト類は `.gitattributes` で LF 固定にしてあるため、
Windows でチェックアウトしても WSL の bash / zsh がそのまま読める。

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

**管理者権限は不要**(通常のPowerShellで実行可能)。

- zenhan は `%USERPROFILE%\bin` に配置し、PATH 追加もユーザー環境変数のみを変更する
- `init.lua` のシンボリックリンク作成には管理者権限または開発者モードが必要だが、
  どちらもない場合は自動的にコピーにフォールバックする
  (コピー運用の場合、リポジトリ更新時は `setup.ps1` を再実行すること)
- リンク運用にしたい場合は、Windows の設定で開発者モードを有効にするか、
  管理者権限の PowerShell で実行する

各モジュールが失敗しても残りは続行され、最後に結果がサマリー表示される
(1つでも失敗があれば終了コード 1)。

## 現在の設定の取り込み

手元のマシンで変更した設定をリポジトリ側へ書き戻す (`setup` の逆方向)。

Mac:

```sh
bash capture.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\capture.ps1
```

書き戻すだけでコミットはしないので、`git diff` で差分を確認してからコミットする。
変更が無いモジュールは「変更なし」と表示してファイルに触らないため、無駄な差分は出ない。

> [!NOTE]
> 現在 `capture.sh` / `capture.ps1` を持つモジュールは無いため、実行しても
> 「実行されたモジュールはありません」と表示されるだけ。取り込みが必要なモジュールを
> 追加したときのための仕組みとして残している。

## nvim モジュール: IME 自動オフ

vscode-neovim (VSCode / Cursor) やターミナル Neovim で、インサートモードを抜けて
ノーマルモードに戻った際に IME を自動的に半角英数へ切り替える。

- Mac: [macism](https://github.com/laishulu/macism)
- Windows: [zenhan](https://github.com/iuchim/zenhan)

特徴:

- Mac / Windows で同一の `init.lua` を使用 (OS 判定して呼び出すツールを切替)
- CLI ツールを非同期で呼び出すため、エディタが遅延しない
- `<Esc>` のグローバルリマップ (Karabiner 等) を使わないため OS 標準の挙動を壊さない
- Windows では zenhan が IME の ON/OFF を直接切り替えるため、
  英語キーボードレイアウトを追加する必要がない

注意点:

- Mac で Google 日本語入力を使う場合は、`init.lua` の `MAC_OFF_SOURCE` を
  `com.google.inputmethod.Japanese.Roman` に変更する
  (現在の入力ソース ID は IME オン状態で `macism` を引数なし実行すると確認できる)
- Mac の初回切り替え時にアクセシビリティ権限を求められた場合は、
  VSCode (または使用中のターミナル) に権限を付与する

## zsh モジュール: .zshrc の同期 (Mac / WSL)

`zsh/.zshrc` を `~/.zshrc` に、`zsh/plugins.toml` ([sheldon](https://github.com/rossmacarthur/sheldon)
の設定) を `~/.config/sheldon/plugins.toml` にそれぞれシンボリックリンクする。
既存の実ファイルがあれば `.bak` に退避してからリンクを張る。

Mac は `zsh/setup.sh`、WSL は `zsh/setup.wsl.sh` が担当する (それぞれ
エントリポイント `setup.sh` / `setup.wsl.sh` から呼ばれる)。リンクの張り方は
共通で、ツールの導入方法だけが異なる。

| | Mac (`zsh/setup.sh`) | WSL (`zsh/setup.wsl.sh`) |
| --- | --- | --- |
| powerlevel10k | Homebrew (`brew install powerlevel10k`) | `~/.local/share/powerlevel10k` へ git clone |
| sheldon | 手動導入 (`brew install sheldon`) | 未導入なら `~/.local/bin` へ自動導入 |
| MesloLGS NF フォント | brew cask で導入 | Windows 側へ[手動導入](https://github.com/romkatv/powerlevel10k#fonts) (描画は Windows のターミナルが行うため) |

powerlevel10k の置き場所が OS で異なるため、`plugins.toml` 側は inline
プラグインで OS 判定してどちらかを source する。`.zshrc` は `~/.local/bin` を
PATH に追加する (WSL の sheldon 用。Mac では実害なし)。

さらに `~/dotfiles` をリポジトリ本体へのシンボリックリンクとして作成する。
`plugins.toml` の `dotfiles-sync` プラグイン (`local = '~/dotfiles/zsh/sync'`)
が固定パスを参照するため。既に `~/dotfiles` が別の実ディレクトリとして存在する
場合は上書きせず警告を出すだけなので、その場合は手動で確認する。

リンク運用のため、リンク先を直接編集すればそのままリポジトリ側にも反映される
(nvim モジュールと同じ考え方)。そのため取り込み用の `capture.sh` は無い。

`.zshrc` 自体は sheldon を起動するだけで、実際の関数・alias・補完・プロンプト
などの設定は `zsh/sync/*.zsh` に分割して置いてあり、sheldon が
`local` プラグインとしてまとめて読み込む。各ファイルの詳細は
[zsh/README.md](zsh/README.md) を参照。

WSL では WSL 内のシェルから `bash setup.wsl.sh` を実行する。zsh 本体が
未導入の場合は警告を出すので、`sudo apt install zsh` の後、
`chsh -s $(which zsh)` でログインシェルに設定する。

Windows ネイティブ (PowerShell) 版は無いため、Windows のエントリポイント
(`setup.ps1`) からは呼ばれない。

## vscode モジュール: 案内のみ

VSCode 本体の設定 (`settings.json`) と拡張機能は**このリポジトリでは同期しない**。
VSCode 内蔵の Settings Sync に移行済み。

このモジュールは何も配置せず、`setup` のサマリに次の NOTE を出すだけ。

```text
  [OK] vscode: 成功
       - VSCode の設定は VSCode 内蔵の Settings Sync に移行しました
```

エディタフォントだけは Settings Sync では配布されないため、`font/` モジュールが担当する。

## font モジュール: エディタフォントの導入

`editor.fontFamily` で使う Moralerspace Neon を**通常版と HW 版の両方**導入する
(HW 版は半角幅が異なるので、用途に応じて `settings.json` 側で使い分ける)。
設定ファイルの同期とは独立したモジュールなので、フォント名を指定するのは各マシンの責任。

| 版 | Mac (cask) | Windows (リリース zip) | フォント名 |
| --- | --- | --- | --- |
| 通常 | `font-moralerspace` | `Moralerspace_v2.0.0.zip` | `Moralerspace Neon` |
| HW | `font-moralerspace-hw` | `MoralerspaceHW_v2.0.0.zip` | `Moralerspace Neon HW` |

- Mac: `brew install --cask` で両方を導入する
- Windows: [yuru7/moralerspace](https://github.com/yuru7/moralerspace) のリリース zip を
  ダウンロードし、`%LOCALAPPDATA%\Microsoft\Windows\Fonts` へ配置 + HKCU へ登録
  (**管理者権限不要**。1 版あたり約 100MB のダウンロードが発生する。導入済みならスキップ)
- 判定は版ごとに独立しているので、片方だけ未導入ならその版だけダウンロードする

取り込み (`capture`) は無いため、フォントは常に「リポジトリ → マシン」の一方向のみ。

```jsonc
// settings.json 側で指定する内容 (参考)
"editor.fontFamily": "'Moralerspace Neon', monospace",
"editor.fontLigatures": "true",
```

## autohotkey モジュール (Windows 専用)

左右 Alt キーの空打ちで IME を切り替える (左=英数 / 右=かな) AutoHotkey v2
スクリプト。Mac 用の `setup.sh` を持たないため、Mac のエントリポイントからは呼ばれない。

`setup.ps1` の動作:

- スクリプト一式 (`*.ahk` / `*.bat`) を `~/dotfiles/autohotkey` に配置
  (内容が同一なら「配置済み (最新)」と表示してスキップ。
  リポジトリに無いファイルは配置先から削除するミラー同期)
- Windows のスタートアップに `launch_alt-ime.bat` のショートカットを登録し、
  ログオン時に自動起動する (リンク先が正しければ「登録済み」でスキップ、
  異なる場合は再作成する自己修復動作)
- 手動起動用に**デスクトップにもショートカットを生成**する (同じく自己修復動作)
- **AutoHotkey v2 の有無を確認し、未インストールなら警告する**
  (処理は継続。`.ahk` は `#Requires AutoHotkey v2.0` のため v2 が必要。
  <https://www.autohotkey.com/> から v2 を導入する)

> [!NOTE]
> タスクバーへのピン留めは Windows 10 以降、Microsoft が API/シェル verb を
> 削除しているためスクリプトからは自動化できない (Windows 11 25H2 で verb 不在を確認済み)。
> そのためデスクトップショートカットで代替している。タスクバーに置きたい場合は、
> 生成されたデスクトップショートカットを手動でタスクバーへドラッグして固定する。
