# vscode モジュール (Windows): settings.json のリンク / 拡張機能 / フォントの導入
$ErrorActionPreference = 'Stop'

# settings.json の editor.fontFamily で指定しているフォント
$fontVersion = 'v2.0.0'
$fontZipUrl  = "https://github.com/yuru7/moralerspace/releases/download/$fontVersion/MoralerspaceHW_$fontVersion.zip"
$fontPrefix  = 'MoralerspaceNeonHW'   # この接頭辞の .ttf だけインストールする
$fontFamily  = 'Moralerspace Neon HW' # レジストリ登録名に使う表示名

# 1. settings.json をリンク (シンボリックリンク不可の環境ではコピー)
$userDir = Join-Path $env:APPDATA 'Code\User'
New-Item -ItemType Directory -Force -Path $userDir | Out-Null
$target = Join-Path $userDir 'settings.json'
$source = Join-Path $PSScriptRoot 'settings.json'

if ((Test-Path $target) -and -not (Get-Item $target).LinkType) {
    if ((Get-FileHash $target).Hash -eq (Get-FileHash $source).Hash) {
        Write-Host '==> settings.json: 配置済み (最新)'
    } elseif (Test-Path "$target.bak") {
        # dotfiles 導入前の設定を保持したいので、既存の .bak は上書きしない
        Write-Host '==> settings.json.bak は既にあるため退避をスキップします'
        Write-Host '    (未取り込みの変更があるなら update.ps1 を先に実行してください)'
    } else {
        Move-Item $target "$target.bak"
        Write-Host '==> 既存の settings.json を settings.json.bak に退避しました'
    }
}
if (Test-Path $target) { Remove-Item $target -Force }
try {
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    Write-Host "==> シンボリックリンク作成: $target -> $source"
} catch {
    # シンボリックリンクには開発者モードまたは管理者権限が必要なためコピーで代替
    Copy-Item $source $target
    Write-Host "==> シンボリックリンクを作成できないためコピーしました: $target"
    Write-Host '    (リポジトリ更新時・設定変更時は双方向に手動同期が必要です)'
}

# 2. 拡張機能のインストール (extensions.txt との差分のみ)
$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($null -eq $codeCmd) {
    Write-Host '==> 警告: code コマンドが見つからないため拡張機能をスキップします'
    Write-Host '    (VSCode の コマンドパレット > "Shell Command: Install ''code'' command in PATH" を実行してください)'
} else {
    # BOM なし UTF-8 を既定の Get-Content で読むと ANSI 扱いになるため明示する
    $wanted = Get-Content (Join-Path $PSScriptRoot 'extensions.txt') -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
    $installed = @(& $codeCmd.Source --list-extensions)
    $missing = $wanted | Where-Object { $installed -notcontains $_ }

    if ($missing.Count -eq 0) {
        Write-Host "==> 拡張機能: $($wanted.Count) 件すべてインストール済み"
    } else {
        Write-Host "==> 拡張機能: $($missing.Count) 件をインストールします"
        foreach ($ext in $missing) {
            & $codeCmd.Source --install-extension $ext --force
            if ($LASTEXITCODE -ne 0) { Write-Host "    [NG] $ext のインストールに失敗しました" }
        }
    }
}

# 3. フォントのインストール (管理者権限不要なユーザー領域へ配置)
$fontDir    = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$installedFonts = @(if (Test-Path $fontDir) { Get-ChildItem $fontDir -Filter "$fontPrefix-*.ttf" })

if ($installedFonts.Count -gt 0) {
    Write-Host "==> フォント: $fontFamily はインストール済み ($($installedFonts.Count) ファイル)"
} else {
    Write-Host "==> フォント $fontFamily をダウンロードします (約 100MB)"
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    New-Item -Path $fontRegKey -Force | Out-Null
    $zip     = Join-Path $env:TEMP 'moralerspace.zip'
    $extract = Join-Path $env:TEMP 'moralerspace_extract'
    try {
        Invoke-WebRequest -Uri $fontZipUrl -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $extract -Force
        $ttfs = @(Get-ChildItem -Path $extract -Recurse -Filter "$fontPrefix-*.ttf")
        if ($ttfs.Count -eq 0) { throw "$fontPrefix の .ttf がアーカイブ内に見つかりませんでした" }
        foreach ($ttf in $ttfs) {
            $dest = Join-Path $fontDir $ttf.Name
            Copy-Item $ttf.FullName $dest -Force
            # 例: MoralerspaceNeonHW-BoldItalic.ttf -> "Moralerspace Neon HW BoldItalic (TrueType)"
            $style = ($ttf.BaseName -split '-', 2)[1]
            Set-ItemProperty -Path $fontRegKey -Name "$fontFamily $style (TrueType)" -Value $dest
        }
        Write-Host "==> $($ttfs.Count) ファイルを配置しました: $fontDir"
        Write-Host '    (VSCode で認識されない場合はサインアウト/再起動してください)'
    } finally {
        if (Test-Path $zip)     { Remove-Item $zip -Force }
        if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    }
}
