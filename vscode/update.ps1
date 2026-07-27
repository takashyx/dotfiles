# vscode モジュール (Windows): 現在の VSCode 設定をリポジトリへ取り込む
$ErrorActionPreference = 'Stop'

$live = Join-Path $env:APPDATA 'Code\User\settings.json'
$repo = Join-Path $PSScriptRoot 'settings.json'
$txt  = Join-Path $PSScriptRoot 'extensions.txt'

# 1. settings.json の取り込み
if (-not (Test-Path $live)) {
    Write-Host "==> 警告: $live が見つかりません (setup.ps1 未実行?)"
} elseif ((Get-Item $live).LinkType) {
    # リンク運用ならリポジトリのファイル自体が書き換わっているので取り込み不要
    Write-Host '==> settings.json: リンク運用のため取り込み不要'
} elseif ((Get-FileHash $live).Hash -eq (Get-FileHash $repo).Hash) {
    Write-Host '==> settings.json: 変更なし'
} else {
    Copy-Item $live $repo -Force
    Write-Host "==> settings.json を取り込みました: $live"
}

# 2. extensions.txt の取り込み
$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($null -eq $codeCmd) {
    Write-Host '==> 警告: code コマンドが見つからないため拡張機能をスキップします'
} else {
    $list = @(& $codeCmd.Source --list-extensions | Where-Object { $_ } | Sort-Object)
    if ($list.Count -eq 0) { throw 'code --list-extensions が空を返しました' }

    # BOM なし UTF-8 を Get-Content で読むと ANSI 扱いで文字化けするため .NET で読む
    $old = if (Test-Path $txt) { [System.IO.File]::ReadAllText($txt) } else { '' }

    # 既存ファイル先頭のコメント行 (ヘッダ) は維持する
    $header = @()
    foreach ($line in ($old -split "`r?`n")) {
        if ($line.TrimStart().StartsWith('#')) { $header += $line } else { break }
    }

    # LF / BOM なし UTF-8 で書き出す (Mac 側の update.sh と差分が出ないようにする)
    $new = (($header + $list) -join "`n") + "`n"
    if ($new -eq ($old -replace "`r`n", "`n")) {
        Write-Host "==> extensions.txt: 変更なし ($($list.Count) 件)"
    } else {
        [System.IO.File]::WriteAllText($txt, $new, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "==> extensions.txt を更新しました ($($list.Count) 件)"
    }
}
