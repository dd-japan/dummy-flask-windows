@echo off
REM ============================================
REM Python 3 Installation Script for Windows Server 2019
REM ============================================
REM
REM Usage: Run as Administrator
REM ============================================

setlocal enabledelayedexpansion

echo.
echo =======================================================
echo   Python 3.11 Installation Script
echo =======================================================
echo.

REM Check for Admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must be run as Administrator
    echo         Right-click and select "Run as administrator"
    pause
    exit /b 1
)

set PYTHON_VERSION=3.11.9
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-amd64.exe
set PYTHON_INSTALLER=%TEMP%\python-installer.exe
set PYTHON_DIR=C:\Python311

REM ============================================
REM Check if Python is already installed
REM ============================================
echo [*] Checking for existing Python installation...

where python >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Python is already installed:
    python --version
    echo.
    set /p REINSTALL="Do you want to reinstall Python? (y/N): "
    if /i not "!REINSTALL!"=="y" (
        echo Skipping Python installation.
        pause
        exit /b 0
    )
)

REM ============================================
REM Download Python
REM ============================================
echo.
echo [*] Downloading Python %PYTHON_VERSION%...
echo     URL: %PYTHON_URL%

powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'}"

if not exist "%PYTHON_INSTALLER%" (
    echo [ERROR] Failed to download Python installer
    pause
    exit /b 1
)

echo [OK] Downloaded Python installer

REM ============================================
REM Install Python
REM ============================================
echo.
echo [*] Installing Python %PYTHON_VERSION%...
echo     This may take a few minutes...

"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1 TargetDir=%PYTHON_DIR%

if %errorLevel% neq 0 (
    echo [ERROR] Python installation failed
    pause
    exit /b 1
)

echo [OK] Python installed successfully

REM Cleanup
del "%PYTHON_INSTALLER%" >nul 2>&1

REM ============================================
REM Verify Installation
REM ============================================
echo.
echo [*] Verifying installation...

REM Refresh PATH for this session
set PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%

if exist "%PYTHON_DIR%\python.exe" (
    echo [OK] Python installed at: %PYTHON_DIR%\python.exe
    "%PYTHON_DIR%\python.exe" --version
    echo.
    echo [OK] pip version:
    "%PYTHON_DIR%\python.exe" -m pip --version
) else (
    echo [ERROR] Python executable not found
    pause
    exit /b 1
)

REM ============================================
REM Complete
REM ============================================
echo.
echo =======================================================
echo   Python Installation Complete!
echo =======================================================
echo.
echo   Python Path: %PYTHON_DIR%\python.exe
echo.
echo   Next Steps:
echo   1. Open a NEW command prompt (to refresh PATH)
echo   2. Run: run_app.bat
echo.

pause
