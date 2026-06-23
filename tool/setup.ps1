# First-time setup after git clone on Windows.
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "Git LFS..."
git lfs install
git lfs pull

Write-Host "Flutter pub get..."
flutter pub get

Write-Host ""
Write-Host "Done. Next:"
Write-Host "  flutter run -d chrome"
Write-Host "  flutter run -d android"
Write-Host "  .\tool\build_web.ps1"
Write-Host "  .\tool\init_own_github.ps1 -RepoName babytracker-app"
