# autohotkey モジュール (Windows 専用)
#   設定一式を ~/dotfiles/autohotkey に配置し、Windows 起動時に
#   launch_alt-ime.bat を自動起動するショートカットをスタートアップに登録する。
#   AutoHotkey v2 の有無を確認し、無ければ警告する (処理は継続)。
#   ※ このモジュールには setup.sh を置かないため、Mac のエントリポイントからは呼ばれない。
$ErrorActionPreference = 'Stop'

$srcDir  = $PSScriptRoot
$destDir = Join-Path $env:USERPROFILE 'dotfiles\autohotkey'

# 1. AutoHotkey v2 の存在確認 (無ければ警告のみ、処理は継続)
#    .ahk は #Requires AutoHotkey v2.0 のため v2 が必須。
$c1 = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'
$c2 = Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey32.exe'
$c3 = Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'
$c4 = Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey32.exe'
$ahkV2 = $null
foreach ($c in @($c1, $c2, $c3, $c4)) {
    if (Test-Path $c) { $ahkV2 = $c; break }
}

if ($ahkV2) {
    Write-Host "==> AutoHotkey v2: 検出 ($ahkV2)"
} else {
    Write-Host '==> [警告] AutoHotkey v2 が見つかりません' -ForegroundColor Yellow
    Write-Host '           この .ahk は AutoHotkey v2 が必要です。https://www.autohotkey.com/ から v2 をインストールしてください' -ForegroundColor Yellow
    Write-Host '           (インストール後、.ahk がファイル関連付けされていれば起動時に自動実行されます)' -ForegroundColor Yellow
}

# 2. 設定ファイルを ~/dotfiles/autohotkey へ配置 (setup スクリプトは除外。内容が同一ならスキップ)
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
foreach ($f in Get-ChildItem -Path $srcDir -File |
        Where-Object { $_.Name -notin @('setup.ps1', 'setup.sh') }) {
    $target = Join-Path $destDir $f.Name
    $same = (Test-Path $target) -and
            ((Get-FileHash $target).Hash -eq (Get-FileHash $f.FullName).Hash)
    if ($same) {
        Write-Host "==> $($f.Name): 配置済み (最新)"
    } else {
        Copy-Item $f.FullName $target -Force
        Write-Host "==> $($f.Name): 配置しました -> $target"
    }
}

# リポジトリに無いファイルは配置先から削除 (ミラー同期。旧名の .ahk / .bat が残らないように)
$srcNames = (Get-ChildItem -Path $srcDir -File |
        Where-Object { $_.Name -notin @('setup.ps1', 'setup.sh') }).Name
foreach ($f in Get-ChildItem -Path $destDir -File |
        Where-Object { $_.Name -notin $srcNames }) {
    Remove-Item $f.FullName -Force -Confirm:$false
    Write-Host "==> $($f.Name): リポジトリに無いため配置先から削除しました"
}

# bat は %~dp0 で自身のフォルダへ cd するため、ショートカット経由でも .ahk を正しく解決できる。
$batTarget = Join-Path $destDir 'launch_alt-ime.bat'
$shell     = New-Object -ComObject WScript.Shell

# ショートカットを作成/修復するヘルパー (リンク先が一致すればスキップ、異なれば再作成)
function Set-Shortcut {
    param([string]$LnkPath, [int]$WindowStyle, [string]$Label)
    if ((Test-Path $LnkPath) -and
        ($shell.CreateShortcut($LnkPath).TargetPath -eq $batTarget)) {
        Write-Host "==> ${Label}: 登録済み"
        return
    }
    if (Test-Path $LnkPath) { Write-Host "==> ${Label}: リンク先が異なるため再作成します" }
    $lnk = $shell.CreateShortcut($LnkPath)
    $lnk.TargetPath       = $batTarget
    $lnk.WorkingDirectory = $destDir
    $lnk.WindowStyle      = $WindowStyle
    $lnk.Description      = 'AutoHotkey: Alt-IME'
    $lnk.Save()
    Write-Host "==> ${Label}に登録しました: $LnkPath"
}

# 3. 旧名のショートカットが残っていれば削除 (leftshiftesc-tilda 時代の名残)
$oldLnks = @(
    (Join-Path ([Environment]::GetFolderPath('Startup')) 'ahk-leftshiftesc-tilda.lnk'),
    (Join-Path ([Environment]::GetFolderPath('Desktop')) 'AutoHotkey (IME + Shift+Esc).lnk')
)
foreach ($old in $oldLnks) {
    if (Test-Path $old) {
        Remove-Item $old -Force -Confirm:$false
        Write-Host "==> 旧ショートカットを削除しました: $old"
    }
}

# 4. スタートアップに登録 (ログオン時に最小化で自動起動)
$startupLnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'ahk-alt-ime.lnk'
Set-Shortcut -LnkPath $startupLnk -WindowStyle 7 -Label 'スタートアップ'

# 5. デスクトップにショートカットを生成 (タスクバーへのピン留めは Windows 10/11 で
#    プログラムからは不可のため、手動起動用にデスクトップへ配置する)
$desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'AutoHotkey (Alt-IME).lnk'
Set-Shortcut -LnkPath $desktopLnk -WindowStyle 7 -Label 'デスクトップ'
