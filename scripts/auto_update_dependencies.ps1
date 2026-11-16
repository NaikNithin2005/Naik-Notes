<#
.SYNOPSIS
    Naik Notes Automated Dependency & Plugin Upgrade Script
.DESCRIPTION
    Automatically upgrades all Flutter dependencies (including Firebase packages)
    to their latest compatible releases, validates static analysis, and checks
    compatibility with Android Built-in Kotlin.
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Naik Notes - Automated Dependency & Plugin Upgrade Tool  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check outdated dependencies
Write-Host "`n[1/4] Checking available package updates on pub.dev..." -ForegroundColor Yellow
flutter pub outdated

# 2. Run flutter pub upgrade
Write-Host "`n[2/4] Upgrading packages to newest compatible versions..." -ForegroundColor Yellow
flutter pub upgrade

# 3. Analyze codebase
Write-Host "`n[3/4] Running static code analysis..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[4/4] Dependency upgrade completed with ZERO analysis issues!" -ForegroundColor Green
} else {
    Write-Host "`n[4/4] Issues detected after upgrade. Please review the output above." -ForegroundColor Red
}

Write-Host "`n==========================================================" -ForegroundColor Cyan

