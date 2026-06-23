# Create a repo on YOUR GitHub and push this project.
# Run from project root:
#   .\tool\init_own_github.ps1 -RepoName babytracker-app
#   .\tool\init_own_github.ps1 -RepoName babytracker-app -Public
param(
    [string]$RepoName = "babytracker-app",
    [switch]$Public
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then run: gh auth login"
}

$login = gh api user -q .login
$visibility = if ($Public) { "public" } else { "private" }
$remoteUrl = "https://github.com/$login/$RepoName.git"

Write-Host "GitHub account: $login"
Write-Host "New repository: $login/$RepoName ($visibility)"
Write-Host ""

if (git remote get-url origin 2>$null) {
    $old = git remote get-url origin
    Write-Host "Current origin: $old"
    $ans = Read-Host "Replace origin with your repo? (y/n)"
    if ($ans -ne "y") { exit 0 }
    git remote remove origin
}

Write-Host "Creating GitHub repository..."
if ($Public) {
    gh repo create "$login/$RepoName" --public --source=. --remote=origin --push
} else {
    gh repo create "$login/$RepoName" --private --source=. --remote=origin --push
}

Write-Host ""
Write-Host "Done: $remoteUrl"
Write-Host ""
Write-Host "Next steps (one time):"
Write-Host "  1. npm install -g firebase-tools"
Write-Host "  2. firebase login"
Write-Host "  3. firebase login:ci  (copy the token)"
Write-Host "  4. GitHub -> Settings -> Secrets -> Actions"
Write-Host "     Secret name: FIREBASE_TOKEN"
Write-Host "  5. Actions -> Deploy Web to Firebase Hosting -> Run workflow"
Write-Host ""
Write-Host "Optional - your own Firebase project:"
Write-Host "  dart pub global activate flutterfire_cli"
Write-Host "  flutterfire configure"
