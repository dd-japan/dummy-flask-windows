@echo off
REM ============================================
REM Datadog APM Python Test Application
REM Quick Deploy Script for Windows Server 2019
REM ============================================
REM
REM This script provides a simpler alternative to deploy.ps1
REM For full functionality, use deploy.ps1
REM
REM Prerequisites:
REM - Run as Administrator
REM - Internet access
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ===============================================
echo  Datadog APM Python Test Application Deployer
echo ===============================================
echo.

REM Check for Admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must be run as Administrator
    echo         Right-click and select "Run as administrator"
    pause
    exit /b 1
)

set SCRIPT_DIR=%~dp0
set PYTHON_VERSION=3.11.9
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-amd64.exe
set PYTHON_INSTALLER=%TEMP%\python-installer.exe
set PORT=5000

REM ============================================
REM Step 1: Check/Install Python
REM ============================================
echo [*] Checking for Python installation...

where python >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Python is already installed
    python --version
    goto :install_packages
)

echo [*] Python not found. Downloading Python %PYTHON_VERSION%...

REM Download Python installer using PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%'}"

if not exist "%PYTHON_INSTALLER%" (
    echo [ERROR] Failed to download Python installer
    pause
    exit /b 1
)

echo [*] Installing Python %PYTHON_VERSION%...
echo     This may take a few minutes...

"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_pip=1

REM Wait for installation to complete
timeout /t 10 /nobreak >nul

REM Refresh PATH
set PATH=C:\Python311;C:\Python311\Scripts;%PATH%

REM Cleanup
del "%PYTHON_INSTALLER%" >nul 2>&1

echo [OK] Python installed

:install_packages
REM ============================================
REM Step 2: Install Dependencies
REM ============================================
echo.
echo [*] Installing Python packages...

python -m pip install --upgrade pip --quiet
python -m pip install -r "%SCRIPT_DIR%requirements.txt" --quiet

if %errorLevel% neq 0 (
    echo [*] Installing packages manually...
    python -m pip install Flask ddtrace --quiet
)

echo [OK] Packages installed

REM ============================================
REM Step 3: Configure Environment
REM ============================================
echo.
echo [*] Configuring Datadog APM environment...

set DD_SERVICE=apm-test-python
set DD_ENV=windows-test
set DD_VERSION=1.0.0
set DD_LOGS_INJECTION=true
set DD_TRACE_SAMPLE_RATE=1

echo     DD_SERVICE = %DD_SERVICE%
echo     DD_ENV     = %DD_ENV%
echo     DD_VERSION = %DD_VERSION%

REM ============================================
REM Step 4: Configure Firewall
REM ============================================
echo.
echo [*] Configuring Windows Firewall...

netsh advfirewall firewall show rule name="Datadog APM Test App" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="Datadog APM Test App" dir=in action=allow protocol=TCP localport=%PORT% >nul
    echo [OK] Firewall rule created
) else (
    echo [OK] Firewall rule already exists
)

REM ============================================
REM Step 5: Start Application
REM ============================================
echo.
echo ===============================================
echo  Starting Application
echo ===============================================
echo.
echo  Access the application at:
echo  http://localhost:%PORT%
echo.
echo  Press Ctrl+C to stop
echo.
echo ===============================================
echo.

python -m ddtrace.commands.ddtrace_run "%SCRIPT_DIR%app.py"

pause
