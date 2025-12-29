<#
.SYNOPSIS
    Advanced Git cleanup script with user confirmation steps.
.DESCRIPTION
    Includes checks for local-only branches and stashed changes before destructive actions.
#>

Write-Host "--- Starting Maintenance for: $(Get-Location) ---" -ForegroundColor Cyan

# 1. Validar si es un repo de Git
if (!(Test-Path .git)) {
    Write-Error "Error: Current directory is not a Git repository."
    return
}

Write-Host "`n[STEP] Checking for local branches with no remote tracking..." -ForegroundColor Yellow
# Comparamos ramas locales contra sus upstream (las que NO tienen [origin/...])
$localOnlyBranches = git branch -vv | Where-Object { $_ -notmatch '\[.*\]' -and $_ -match '\S' }

if ($localOnlyBranches) {
    Write-Host "The following branches exist ONLY locally and might be lost if deleted:" -ForegroundColor Cyan
    $localOnlyBranches | ForEach-Object { Write-Host "  - $($_.Trim())" }
    
    $confirmBranches = Read-Host "`nDo you want to proceed with the cleanup? (y/n)"
    if ($confirmBranches -ne 'y') {
        Write-Host "Skipping local branches check." -ForegroundColor Yellow
    }
} else {
    Write-Host "No local-only branches found. Safe to proceed." -ForegroundColor Green
}

Write-Host "`n[STEP] Checking for stashed changes..." -ForegroundColor Yellow
$stashList = git stash list

if ($stashList) {
    Write-Host "Current Stash List:" -ForegroundColor Cyan
    $stashList | ForEach-Object { Write-Host "  - $_" }
    
    $confirmStash = Read-Host "`nDo you want to CLEAR the stash? (y/n/skip)"
    if ($confirmStash -eq 'y') {
        git stash clear
        Write-Host "Stash cleared." -ForegroundColor Green
    } else {
        Write-Host "Stash preserved." -ForegroundColor Gray
    }
} else {
    Write-Host "Stash is already empty." -ForegroundColor Green
}

# --- EJECUCIÓN DE LIMPIEZA ---
Write-Host "`n[STEP] Cleaning untracked files (git clean -fdx)..." -ForegroundColor Yellow
$confirmClean = Read-Host "This will delete all untracked files. Continue? (y/n)"
if ($confirmClean -eq 'y') {
    git clean -fdx
    Write-Host "Untracked files cleaned." -ForegroundColor Green
} else {
    Write-Host "Skipped cleaning untracked files." -ForegroundColor Yellow
}

Write-Host "`n[STEP] Pruning remote tracking branches..." -ForegroundColor Yellow
$confirmPrune = Read-Host "Continue with pruning? (y/n)"
if ($confirmPrune -eq 'y') {
    git fetch --prune --all
    Write-Host "Remote branches pruned." -ForegroundColor Green
} else {
    Write-Host "Skipped pruning remote branches." -ForegroundColor Yellow
}

Write-Host "`n[STEP] Running Aggressive Garbage Collection..." -ForegroundColor Yellow
$confirmGC = Read-Host "Continue with garbage collection? (y/n)"
if ($confirmGC -eq 'y') {
    git gc --prune=now --aggressive
    Write-Host "Garbage collection completed." -ForegroundColor Green
} else {
    Write-Host "Skipped garbage collection." -ForegroundColor Yellow
}

Write-Host "`n--- Cleanup Complete! ---" -ForegroundColor Green
$size = (Get-ChildItem .git -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Current .git folder size: $([Math]::Round($size, 2)) MB"