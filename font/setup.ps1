# font モジュール (Windows): エディタ用フォントの導入
$ErrorActionPreference = 'Stop'

$fontVersion = 'v2.0.0'

# 通常版 (Moralerspace Neon) と HW 版 (Moralerspace Neon HW) の両方を導入する
#   Archive: リリース zip 名 / Prefix: インストール対象 .ttf の接頭辞 / Family: 登録名
$fontSets = @(
    @{ Archive = 'Moralerspace';   Prefix = 'MoralerspaceNeon';   Family = 'Moralerspace Neon' }
    @{ Archive = 'MoralerspaceHW'; Prefix = 'MoralerspaceNeonHW'; Family = 'Moralerspace Neon HW' }
)

# 管理者権限不要なユーザー領域へ配置する
$fontDir    = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

foreach ($set in $fontSets) {
    # 接頭辞の直後にハイフンを要求するため、通常版の判定が HW 版を拾うことはない
    $installedFonts = @(if (Test-Path $fontDir) { Get-ChildItem $fontDir -Filter "$($set.Prefix)-*.ttf" })
    if ($installedFonts.Count -gt 0) {
        Write-Host "==> フォント: $($set.Family) はインストール済み ($($installedFonts.Count) ファイル)"
        continue
    }

    Write-Host "==> フォント $($set.Family) をダウンロードします (約 100MB)"
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    New-Item -Path $fontRegKey -Force | Out-Null
    $zip     = Join-Path $env:TEMP "$($set.Archive).zip"
    $extract = Join-Path $env:TEMP "$($set.Archive)_extract"
    try {
        $url = "https://github.com/yuru7/moralerspace/releases/download/$fontVersion/$($set.Archive)_$fontVersion.zip"
        Invoke-WebRequest -Uri $url -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $extract -Force
        $ttfs = @(Get-ChildItem -Path $extract -Recurse -Filter "$($set.Prefix)-*.ttf")
        if ($ttfs.Count -eq 0) { throw "$($set.Prefix) の .ttf がアーカイブ内に見つかりませんでした" }
        foreach ($ttf in $ttfs) {
            $dest = Join-Path $fontDir $ttf.Name
            Copy-Item $ttf.FullName $dest -Force
            # 例: MoralerspaceNeon-BoldItalic.ttf -> "Moralerspace Neon BoldItalic (TrueType)"
            $style = ($ttf.BaseName -split '-', 2)[1]
            Set-ItemProperty -Path $fontRegKey -Name "$($set.Family) $style (TrueType)" -Value $dest
        }
        Write-Host "==> $($ttfs.Count) ファイルを配置しました: $fontDir"
        Write-Host '    (VSCode で認識されない場合はサインアウト/再起動してください)'
    } finally {
        if (Test-Path $zip)     { Remove-Item $zip -Force }
        if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    }
}
