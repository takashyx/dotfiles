# =====================================================================
# dotfiles 取り込みエントリポイント (Windows)
#   各モジュールフォルダ直下の update.ps1 を順に実行する。
#   現在のマシンの設定をリポジトリ側へ書き戻す (setup.ps1 とは逆方向)。
#   取り込み対象を追加するときは、フォルダに update.ps1 を置くだけでよい。
#   モジュールが失敗しても残りは続行し、最後に結果をサマリー表示する。
# 実行例: powershell -ExecutionPolicy Bypass -File .\update.ps1
# =====================================================================
$ErrorActionPreference = 'Stop'

$results = @()

foreach ($dir in (Get-ChildItem -Path $PSScriptRoot -Directory | Sort-Object Name)) {
    $script = Join-Path $dir.FullName 'update.ps1'
    if (-not (Test-Path $script)) { continue }

    Write-Host ''
    Write-Host "========== モジュール: $($dir.Name) =========="
    try {
        & $script
        $results += [pscustomobject]@{ Module = $dir.Name; Success = $true; Detail = '' }
    } catch {
        Write-Host "==> エラー: $($_.Exception.Message)"
        $results += [pscustomobject]@{ Module = $dir.Name; Success = $false; Detail = $_.Exception.Message }
    }
}

Write-Host ''
Write-Host '========== 取り込み結果 ==========' -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host '  実行されたモジュールはありません'
} else {
    foreach ($r in $results) {
        if ($r.Success) {
            Write-Host "  [OK] $($r.Module): 成功" -ForegroundColor Green
        } else {
            Write-Host "  [NG] $($r.Module): 失敗 - $($r.Detail)" -ForegroundColor Red
        }
    }
    Write-Host ''
    Write-Host '  git diff で差分を確認してからコミットしてください'
}

$failed = @($results | Where-Object { -not $_.Success }).Count
if ($failed -gt 0) { exit 1 } else { exit 0 }
