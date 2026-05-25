#Requires -Version 7.0

Write-Host "doctor_version=1"

# Tool versions
$gitVersion = (Get-Command git -ErrorAction SilentlyContinue).Source ? (git --version 2>$null | ForEach-Object { $_.Split(' ')[2] }) : "missing"
$ghVersion = (Get-Command gh -ErrorAction SilentlyContinue).Source ? (gh --version 2>$null | Select-Object -First 1 | ForEach-Object { $_.Split(' ')[2] }) : "missing"
$nodeVersion = (Get-Command node -ErrorAction SilentlyContinue).Source ? (node -v) : "missing"

Write-Host "git=$gitVersion"
Write-Host "gh=$ghVersion"
Write-Host "node=$nodeVersion"

# Git status
$gitStatus = git status --porcelain 2>$null
if ([string]::IsNullOrEmpty($gitStatus)) {
    Write-Host "git_status=clean"
} else {
    Write-Host "git_status=dirty"
}

# Org meta-repo specific checks
if (Test-Path "versions.json") {
    Write-Host "versions_json=present"
} else {
    Write-Host "versions_json=missing"
}

if (Test-Path ".github/workflows/templates") {
    $templateCount = (Get-ChildItem ".github/workflows/templates/*.yml" -ErrorAction SilentlyContinue).Count
    Write-Host "workflow_templates=$templateCount"
} else {
    Write-Host "workflow_templates=0"
}

if (Test-Path ".github/workflows/governance-drift.yml") {
    Write-Host "drift_detection=active"
} else {
    Write-Host "drift_detection=missing"
}

# This is a meta-repo — no workspace_status or build gate
Write-Host "repo_posture=org-governance"

# Exit code
if ($gitVersion -ne "missing") {
    exit 0
} else {
    exit 1
}