# Build web when project path contains non-ASCII chars (Cyrillic etc.).
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)
$out = Join-Path ([System.IO.Path]::GetTempPath()) "babytracker_web_build"
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Path $out -Force | Out-Null
flutter build web --release --no-wasm-dry-run -o $out
Write-Host ""
Write-Host "Done: $out"
