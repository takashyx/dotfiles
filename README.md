# dotfiles

Mac / Windows 共通の設定ファイルをモジュール単位(フォルダ単位)で管理する。

## 構成

``` text
dotfiles/
├── setup.sh        # 配置エントリポイント (Mac): 各フォルダの setup.sh を順に実行
├── setup.ps1       # 配置エントリポイント (Windows): 各フォルダの setup.ps1 を順に実行
├── update.sh       # 取り込みエントリポイント (Mac): 各フォルダの update.sh を順に実行
├── update.ps1      # 取り込みエントリポイント (Windows): 各フォルダの update.ps1 を順に実行
├── nvim/           # Neovim (vscode-neovim) モジュール
│   ├── init.lua    # OS 共通設定 (IME 自動オフ)
│   ├── setup.sh    # Mac 用: macism インストール + init.lua リンク
│   └── setup.ps1   # Windows 用: zenhan 配置 + init.lua リンク
├── vscode/         # VSCode モジュール
│   ├── settings.json   # OS 共通のユーザー設定
│   ├── extensions.txt  # 拡張機能 ID 一覧
│   ├── setup.sh    # Mac 用: 設定リンク + 拡張機能 + フォント (brew cask)
│   ├── setup.ps1   # Windows 用: 設定リンク + 拡張機能 + フォント (zip 展開)
│   ├── update.sh   # Mac 用: 現在の設定 / 拡張機能をリポジトリへ取り込む
│   └── update.ps1  # Windows 用: 同上
└── autohotkey/     # AutoHotkey モジュール (Windows 専用)
    ├── alt-ime_and_leftshiftesc-tilda_ahk_v2.ahk  # Alt 空打ちで IME 切替 / LShift+Esc → ~
    ├── launch_leftshiftesc-tilda.bat              # .ahk 起動用ランチャ
    └── setup.ps1   # Windows 用: ~/dotfiles へ配置 + スタートアップ登録 (setup.sh なし = Mac ではスキップ)
```

方向は 2 つあり、どちらもフォルダ単位で自動的に呼び出される。

| コマンド | 方向 | 用途 |
| --- | --- | --- |
| `setup.sh` / `setup.ps1` | リポジトリ → マシン | 新しいマシンに設定を展開する |
| `update.sh` / `update.ps1` | マシン → リポジトリ | 手元で変えた設定をリポジトリに取り込む |

新しい設定を追加するときは、フォルダを作って `setup.sh` / `setup.ps1` を置くだけでよい。
取り込みも自動化したければ、あわせて `update.sh` / `update.ps1` を置く
(置かないモジュールは単にスキップされる)。

## セットアップ

Mac:

```sh
bash setup.sh
```

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
bash update.sh
```

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\update.ps1
```

書き戻すだけでコミットはしないので、`git diff` で差分を確認してからコミットする。
変更が無いモジュールは「変更なし」と表示してファイルに触らないため、無駄な差分は出ない。

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

## vscode モジュール: 設定 / 拡張機能 / フォントの同期

VSCode のユーザー設定・拡張機能・エディタフォントを Mac / Windows 間で揃える。

`setup.sh` / `setup.ps1` の動作:

1. **`settings.json` をシンボリックリンク**する (既存の実ファイルは `.bak` に退避)
   - Mac: `~/Library/Application Support/Code/User/settings.json`
   - Windows: `%APPDATA%\Code\User\settings.json`
   - リンクなので、VSCode の GUI で設定を変えるとリポジトリ側のファイルが直接書き換わる。
     差分が出たらそのままコミットすればよい
2. **`extensions.txt` の拡張機能を導入**する
   (`code --list-extensions` と比較して未インストールのものだけを入れる)
3. **`editor.fontFamily` のフォント (Moralerspace Neon HW) を導入**する
   - Mac: `brew install --cask font-moralerspace-hw`
   - Windows: [yuru7/moralerspace](https://github.com/yuru7/moralerspace) のリリース zip を
     ダウンロードし、`%LOCALAPPDATA%\Microsoft\Windows\Fonts` へ配置 + HKCU へ登録
     (**管理者権限不要**。約 100MB のダウンロードが発生する。導入済みならスキップ)

`update.sh` / `update.ps1` の動作 (逆方向の取り込み):

1. **`settings.json` を書き戻す**
   - リンク運用ならリポジトリのファイル自体が既に書き換わっているので「取り込み不要」でスキップ
   - コピー運用 (Windows でリンクを作れなかった場合) なら実ファイルをリポジトリへコピーする
2. **`extensions.txt` を再生成**する
   (`code --list-extensions` をソートして書き出し。先頭のコメント行は維持される)

注意点:

- `code` コマンドが PATH に無い場合、拡張機能の導入/取り込みはスキップされる
  (VSCode のコマンドパレットから `Shell Command: Install 'code' command in PATH` を実行する)
- Windows で開発者モードも管理者権限も無い場合はリンクではなく**コピー**になる。
  この場合は自動で双方向同期されないので、設定を変えたら `update.ps1` を実行してから
  コミットすること
- `.bak` は dotfiles 導入前の設定を残すためのものなので、既にある場合は上書きされない
  (未取り込みの変更を消したくない場合は `update` を先に実行する)
- Cursor (`%APPDATA%\Cursor\User`) は対象外。共有したくなったら同じ要領でパスを追加する

## autohotkey モジュール (Windows 専用)

左右 Alt キーの空打ちで IME を切り替え (左=英数 / 右=かな)、Shift+Esc を `~` に
リマップする AutoHotkey v2 スクリプト。Mac 用の `setup.sh` を持たないため、
Mac のエントリポイントからは呼ばれない。

`setup.ps1` の動作:

- スクリプト一式 (`*.ahk` / `*.bat`) を `~/dotfiles/autohotkey` に配置
  (内容が同一なら「配置済み (最新)」と表示してスキップ)
- Windows のスタートアップに `launch_leftshiftesc-tilda.bat` のショートカットを登録し、
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
