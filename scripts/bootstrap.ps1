#Requires -Version 7.0

Write-Host "=== .github Org Meta-Repo Bootstrap ===" -ForegroundColor Green

# This is a governance meta-repo, not a product workspace.
# Bootstrap validates org-level artifacts only.

$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host "git is required" -ForegroundColor Red
    exit 1
}

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host "gh CLI is required for governance ops" -ForegroundColor Red
    exit 1
}

Write-Host "Git version: $(git --version | ForEach-Object { $_.Split(' ')[2] })"
Write-Host "gh version: $(gh --version | Select-Object -First 1 | ForEach-Object { $_.Split(' ')[2] })"

# Validate workflow templates exist
if (Test-Path ".github/workflows/templates") {
    $templateCount = (Get-ChildItem ".github/workflows/templates/*.yml" -ErrorAction SilentlyContinue).Count
    Write-Host "Reusable workflow templates: $templateCount"
} else {
    Write-Host "WARNING: No reusable workflow templates found" -ForegroundColor Yellow
}

# Validate versions.json exists
if (Test-Path "versions.json") {
    Write-Host "Central versions.json: present"
} else {
    Write-Host "WARNING: versions.json missing - version governance unavailable" -ForegroundColor Yellow
}

Write-Host "=== Bootstrap complete ===" -ForegroundColor Green