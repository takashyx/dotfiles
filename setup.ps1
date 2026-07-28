# =====================================================================
# dotfiles セットアップエントリポイント (Windows)
#   各モジュールフォルダ直下の setup.ps1 を順に実行する。
#   新しい設定を追加するときは、フォルダを作って setup.ps1 を置くだけでよい。
#   モジュールが失敗しても残りは続行し、最後に結果をサマリー表示する。
# 実行例: powershell -ExecutionPolicy Bypass -File .\setup.ps1
# =====================================================================
$ErrorActionPreference = 'Stop'

$results = @()
$notes   = @()

foreach ($dir in (Get-ChildItem -Path $PSScriptRoot -Directory | Sort-Object Name)) {
    $script = Join-Path $dir.FullName 'setup.ps1'
    if (-not (Test-Path $script)) { continue }

    Write-Host ''
    Write-Host "========== モジュール: $($dir.Name) =========="
    try {
        # モジュールが 'NOTE: ...' を出力した場合はサマリ側に回す (ここでは表示しない)
        & $script | ForEach-Object {
            if ("$_" -match '^\s*NOTE:\s*(.+)$') {
                $notes += [pscustomobject]@{ Module = $dir.Name; Text = $Matches[1] }
            } else {
                Write-Host $_
            }
        }
        $results += [pscustomobject]@{ Module = $dir.Name; Success = $true; Detail = '' }
    } catch {
        Write-Host "==> エラー: $($_.Exception.Message)"
        $results += [pscustomobject]@{ Module = $dir.Name; Success = $false; Detail = $_.Exception.Message }
    }
}

Write-Host ''
Write-Host '========== セットアップ結果 ==========' -ForegroundColor Cyan

if ($results.Count -eq 0) {
    Write-Host '  実行されたモジュールはありません'
} else {
    foreach ($r in $results) {
        if ($r.Success) {
            Write-Host "  [OK] $($r.Module): 成功" -ForegroundColor Green
        } else {
            Write-Host "  [NG] $($r.Module): 失敗 - $($r.Detail)" -ForegroundColor Red
        }
        foreach ($n in @($notes | Where-Object { $_.Module -eq $r.Module })) {
            Write-Host "       - $($n.Text)" -ForegroundColor Yellow
        }
    }
}

$failed = @($results | Where-Object { -not $_.Success }).Count
if ($failed -gt 0) { exit 1 } else { exit 0 }
