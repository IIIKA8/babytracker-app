# Push clean copy to YOUR GitHub without old Git LFS history.
# Run from any folder:
#   .\tool\sync_to_own_github.ps1 -GitHubUser LiDusik7 -RepoName babytracker-app
param(
    [Parameter(Mandatory = $true)][string]$GitHubUser,
    [string]$RepoName = "babytracker-app",
    [string]$Upstream = "https://github.com/IIIKA8/babytracker-app.git"
)

$ErrorActionPreference = "Stop"
$dest = Join-Path $env:TEMP "babytracker-sync-$(Get-Random)"
$origin = "https://github.com/$GitHubUser/$RepoName.git"

Write-Host "Clone upstream (no LFS hooks)..."
$env:GIT_LFS_SKIP_SMUDGE = "1"
git clone $Upstream $dest
Set-Location $dest
git lfs uninstall 2>$null

Write-Host "Create single commit without LFS history..."
git checkout --orphan clean-main
git add -A
git commit -m "Baby Tracker sync from upstream"

Write-Host "Push to $origin ..."
git remote remove origin 2>$null
git remote add origin $origin
git branch -M main
git push origin main --force

Write-Host ""
Write-Host "Done: $origin"
Write-Host "Check Actions -> Deploy Web to Firebase Hosting"
