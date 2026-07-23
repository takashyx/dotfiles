# nvim モジュール (Windows): zenhan の配置と init.lua のリンク
$ErrorActionPreference = 'Stop'

$binDir    = Join-Path $env:USERPROFILE 'bin'
$zenhanExe = Join-Path $binDir 'zenhan.exe'

# 1. zenhan のダウンロードと配置 (~/bin/zenhan.exe)
if (Test-Path $zenhanExe) {
    Write-Host '==> zenhan: インストール済み'
} else {
    Write-Host '==> zenhan をダウンロードします'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $zip     = Join-Path $env:TEMP 'zenhan.zip'
    $extract = Join-Path $env:TEMP 'zenhan_extract'
    Invoke-WebRequest -Uri 'https://github.com/iuchim/zenhan/releases/download/v0.0.1/zenhan.zip' -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    # zip 構造: zenhan/bin64/zenhan.exe (64bit) / zenhan/bin32/zenhan.exe (32bit)
    $exe = Get-ChildItem -Path $extract -Recurse -Filter 'zenhan.exe' |
        Where-Object { $_.FullName -match 'bin64' } | Select-Object -First 1
    if ($null -eq $exe) { throw 'zenhan.exe (64bit) がアーカイブ内に見つかりませんでした' }
    Copy-Item $exe.FullName $zenhanExe
    Remove-Item $zip -Force
    Remove-Item $extract -Recurse -Force
    Write-Host "==> 配置しました: $zenhanExe"
}

# 2. ユーザー PATH に ~/bin を追加 (init.lua は絶対パスでも探すので必須ではない)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $binDir) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir", 'User')
    Write-Host "==> ユーザー PATH に $binDir を追加しました (新しいプロセスから有効)"
}

# 3. init.lua をリンク (シンボリックリンク不可の環境ではコピー)
$nvimDir = Join-Path $env:LOCALAPPDATA 'nvim'
New-Item -ItemType Directory -Force -Path $nvimDir | Out-Null
$target = Join-Path $nvimDir 'init.lua'
$source = Join-Path $PSScriptRoot 'init.lua'

if ((Test-Path $target) -and -not (Get-Item $target).LinkType) {
    Move-Item $target "$target.bak" -Force
    Write-Host '==> 既存の init.lua を init.lua.bak に退避しました'
}
if (Test-Path $target) { Remove-Item $target -Force }
try {
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
    Write-Host "==> シンボリックリンク作成: $target -> $source"
} catch {
    # シンボリックリンクには開発者モードまたは管理者権限が必要なためコピーで代替
    Copy-Item $source $target
    Write-Host "==> シンボリックリンクを作成できないためコピーしました: $target"
    Write-Host '    (リポジトリ更新時は setup.ps1 を再実行してください)'
}
