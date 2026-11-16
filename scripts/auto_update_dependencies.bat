@echo off
echo ==========================================================
echo  Naik Notes - Automated Dependency & Plugin Upgrade Tool
echo ==========================================================

echo.
echo [1/3] Checking available package updates...
call flutter pub outdated

echo.
echo [2/3] Upgrading all packages...
call flutter pub upgrade

echo.
echo [3/3] Running flutter analyze...
call flutter analyze

echo.
echo ==========================================================
echo  Auto-update finished.
echo ==========================================================

