# dotfiles

Mac / Windows 共通の設定ファイルをモジュール単位(フォルダ単位)で管理する。

## 構成

```
dotfiles/
├── setup.sh      # エントリポイント (Mac): 各フォルダの setup.sh を順に実行
├── setup.ps1     # エントリポイント (Windows): 各フォルダの setup.ps1 を順に実行
└── nvim/         # Neovim (vscode-neovim) モジュール
    ├── init.lua  # OS 共通設定 (IME 自動オフ)
    ├── setup.sh  # Mac 用: macism インストール + init.lua リンク
    └── setup.ps1 # Windows 用: zenhan 配置 + init.lua リンク
```

新しい設定を追加するときは、フォルダを作って `setup.sh` / `setup.ps1` を置くだけで
エントリポイントから自動的に呼び出される。

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
