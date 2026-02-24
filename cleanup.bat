@echo off
REM ============================================
REM Datadog APM Test Application Cleanup Script
REM ============================================
REM
REM This script will:
REM 1. Stop the running application
REM 2. Remove Windows Firewall rule
REM
REM For full cleanup including Python uninstall,
REM use cleanup.ps1 with PowerShell
REM
REM ============================================

setlocal enabledelayedexpansion

echo.
echo =======================================================
echo   Datadog APM Test Application Cleanup
echo =======================================================
echo.

echo This script will:
echo   1. Stop running Flask application processes
echo   2. Remove Windows Firewall rule
echo.

set /p CONFIRM="Do you want to continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Cleanup cancelled.
    pause
    exit /b 0
)

echo.

REM ============================================
REM Step 1: Stop Application
REM ============================================
echo [*] Stopping Flask application processes...

REM Kill Python processes (simple approach)
taskkill /F /IM python.exe /T >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Python processes stopped
) else (
    echo     No Python processes found or could not stop
)

REM Kill processes on port 5000
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :5000 ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1
    if !errorLevel! equ 0 (
        echo     Stopped process on port 5000: PID %%a
    )
)

REM ============================================
REM Step 2: Remove Firewall Rule
REM ============================================
echo.
echo [*] Removing Windows Firewall rule...

netsh advfirewall firewall delete rule name="Datadog APM Test App" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Firewall rule removed
) else (
    echo     Firewall rule not found or could not remove
)

REM ============================================
REM Step 3: Remove Python Packages (Optional)
REM ============================================
echo.
set /p REMOVE_PKG="Do you want to uninstall Python packages (Flask, ddtrace)? (y/N): "
if /i "%REMOVE_PKG%"=="y" (
    echo [*] Uninstalling Python packages...
    
    if exist "C:\Python311\python.exe" (
        "C:\Python311\python.exe" -m pip uninstall Flask ddtrace -y >nul 2>&1
    ) else (
        python -m pip uninstall Flask ddtrace -y >nul 2>&1
    )
    
    echo [OK] Python packages uninstalled
)

REM ============================================
REM Complete
REM ============================================
echo.
echo =======================================================
echo   Cleanup Complete!
echo =======================================================
echo.
echo   Note: To uninstall Python, go to:
echo   Settings ^> Apps ^> Apps ^& features ^> Python 3.x ^> Uninstall
echo.

pause
