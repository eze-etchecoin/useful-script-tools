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
# Comparamos ramas locales contra sus upstream
$localOnlyBranches = git branch -vv | Where-Object { $_ -notmatch '\[origin/.*\]' }

if ($localOnlyBranches) {
    Write-Host "The following branches exist ONLY locally and might be lost if deleted:" -ForegroundColor Cyan
    $localOnlyBranches | ForEach-Object { Write-Host "  - $($_.Trim())" }
    
    $confirmBranches = Read-Host "`nDo you want to proceed with the cleanup? (y/n)"
    if ($confirmBranches -ne 'y') {
        Write-Host "Cleanup aborted by user." -ForegroundColor Red
        return
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
git clean -fdx

Write-Host "[STEP] Pruning remote tracking branches..." -ForegroundColor Yellow
git fetch --prune --all

Write-Host "[STEP] Running Aggressive Garbage Collection..." -ForegroundColor Yellow
git gc --prune=now --aggressive

Write-Host "`n--- Cleanup Complete! ---" -ForegroundColor Green
$size = (Get-ChildItem .git -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Current .git folder size: $([Math]::Round($size, 2)) MB"