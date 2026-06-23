# Shrink noise MP3 for web/mobile (needs ffmpeg in PATH).
# Originals -> assets/audio/originals/, optimized -> assets/audio/
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "Install ffmpeg: winget install Gyan.FFmpeg"
}

$srcDir = Join-Path (Get-Location) "assets\audio"
$bakDir = Join-Path $srcDir "originals"
New-Item -ItemType Directory -Path $bakDir -Force | Out-Null

Get-ChildItem $srcDir -Filter "*.mp3" | ForEach-Object {
    $name = $_.Name
    $bak = Join-Path $bakDir $name
    if (-not (Test-Path $bak)) {
        Copy-Item $_.FullName $bak
        Write-Host "Backup: $name"
    }

    $tmp = Join-Path $srcDir ("_" + $name)
    # 2 min loop, mono, 64 kbps — enough for noise, ~1 MB per file
    ffmpeg -y -i $bak -t 120 -ac 1 -b:a 64k $tmp
    Move-Item -Force $tmp $_.FullName
    $kb = [math]::Round((Get-Item $_.FullName).Length / 1KB)
    Write-Host "OK $name -> ${kb} KB"
}

Write-Host ""
Write-Host "Done. Commit and push assets/audio/*.mp3 (git lfs)."
