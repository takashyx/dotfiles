# nvim モジュール (Windows): zenhan の配置と init.lua のリンク
$ErrorActionPreference = 'Stop'

function Invoke-DownloadWithMbProgress {
    param(
        [Parameter(Mandatory = $true)] [string] $Uri,
        [Parameter(Mandatory = $true)] [string] $OutFile
    )

    $webClient = [System.Net.WebClient]::new()
    $progressId = 1
    $subscription = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
        $args = $Event.SourceEventArgs
        $received = [Math]::Round($args.BytesReceived / 1MB, 1)
        $total = $args.TotalBytesToReceive
        $totalMb = if ($total -gt 0) { [Math]::Round($total / 1MB, 1) } else { 'unknown' }
        $percent = if ($total -gt 0) { [Math]::Round(($args.BytesReceived / $total) * 100, 1) } else { 0 }
        Write-Progress -Id $progressId -Activity 'ダウンロード中' -Status "$received MB / $totalMb MB" -PercentComplete $percent
    }

    try {
        $webClient.DownloadFile($Uri, $OutFile)
    } finally {
        Write-Progress -Id $progressId -Activity 'ダウンロード中' -Completed
        Unregister-Event -SubscriptionId $subscription.Id
        $webClient.Dispose()
    }
}

$binDir    = Join-Path $env:USERPROFILE 'bin'
$zenhanExe = Join-Path $binDir 'zenhan.exe'
$neovimExe = Join-Path $binDir 'nvim.exe'

function Ensure-NeovimInstalled {
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        Write-Host '==> Neovim: インストール済み'
        return
    }

    if (Test-Path $neovimExe) {
        Write-Host '==> Neovim: ~/bin に配置済み'
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host '==> winget で Neovim をインストールします'
        New-Item -ItemType Directory -Force -Path $binDir | Out-Null
        & winget install --id Neovim.Neovim --exact --accept-source-agreements --accept-package-agreements --silent
        if ($LASTEXITCODE -ne 0) {
            throw 'winget による Neovim のインストールに失敗しました'
        }
        return
    }

    Write-Host '==> Neovim をダウンロードして ~/bin に配置します'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $zip = Join-Path $env:TEMP 'nvim-win64.zip'
    $extract = Join-Path $env:TEMP 'nvim-win64'
    Invoke-DownloadWithMbProgress -Uri 'https://github.com/neovim/neovim/releases/latest/download/nvim-win64.zip' -OutFile $zip
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $extract -Force

    $portableRoot = Get-ChildItem -Path $extract -Directory | Select-Object -First 1
    if ($null -eq $portableRoot) { throw 'nvim-win64 の展開先が見つかりませんでした' }

    $portableExe = Join-Path $portableRoot.FullName 'bin\nvim.exe'
    if (-not (Test-Path $portableExe)) { throw 'nvim.exe が展開先に見つかりませんでした' }
    Copy-Item $portableExe $neovimExe
    Remove-Item $zip -Force
    Remove-Item $extract -Recurse -Force
    Write-Host "==> 配置しました: $neovimExe"
}

# 1. Neovim の導入 (既存ならスキップ)
Ensure-NeovimInstalled

# 2. zenhan のダウンロードと配置 (~/bin/zenhan.exe)
if (Test-Path $zenhanExe) {
    Write-Host '==> zenhan: インストール済み'
} else {
    Write-Host '==> zenhan をダウンロードします'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $zip     = Join-Path $env:TEMP 'zenhan.zip'
    $extract = Join-Path $env:TEMP 'zenhan_extract'
    Invoke-DownloadWithMbProgress -Uri 'https://github.com/iuchim/zenhan/releases/download/v0.0.1/zenhan.zip' -OutFile $zip
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

# 3. ユーザー PATH に ~/bin を追加 (init.lua は絶対パスでも探すので必須ではない)
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $binDir) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir", 'User')
    Write-Host "==> ユーザー PATH に $binDir を追加しました (新しいプロセスから有効)"
}

# 4. init.lua をリンク (シンボリックリンク不可の環境ではコピー)
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
