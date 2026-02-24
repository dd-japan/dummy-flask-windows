@echo off
REM ============================================
REM Datadog APM Test Application Runner
REM ============================================
REM
REM Prerequisites:
REM   - Python 3 installed (run install_python.bat first)
REM   - Datadog Agent installed with APM enabled (for tracing)
REM
REM ============================================

setlocal enabledelayedexpansion

echo.
echo =======================================================
echo   Datadog APM Test Application
echo =======================================================
echo.

set SCRIPT_DIR=%~dp0
set PORT=5000

REM ============================================
REM Find Python
REM ============================================
echo [*] Locating Python...

set PYTHON_EXE=

if exist "C:\Python311\python.exe" (
    set PYTHON_EXE=C:\Python311\python.exe
) else if exist "C:\Python310\python.exe" (
    set PYTHON_EXE=C:\Python310\python.exe
) else if exist "C:\Python39\python.exe" (
    set PYTHON_EXE=C:\Python39\python.exe
) else (
    where python >nul 2>&1
    if %errorLevel% equ 0 (
        for /f "delims=" %%i in ('where python') do set PYTHON_EXE=%%i
    )
)

if "%PYTHON_EXE%"=="" (
    echo [ERROR] Python not found. Please run install_python.bat first.
    pause
    exit /b 1
)

echo [OK] Python found: %PYTHON_EXE%
"%PYTHON_EXE%" --version

REM ============================================
REM Install Dependencies
REM ============================================
echo.
echo [*] Installing/updating dependencies...

"%PYTHON_EXE%" -m pip install --upgrade pip --quiet 2>nul

if exist "%SCRIPT_DIR%requirements.txt" (
    "%PYTHON_EXE%" -m pip install -r "%SCRIPT_DIR%requirements.txt" --quiet
    echo [OK] Dependencies installed from requirements.txt
) else (
    "%PYTHON_EXE%" -m pip install Flask ddtrace --quiet
    echo [OK] Flask and ddtrace installed
)

REM ============================================
REM Configure Environment Variables
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
echo     PORT       = %PORT%

REM ============================================
REM Check Datadog Agent
REM ============================================
echo.
echo [*] Checking Datadog Agent status...

sc query DatadogAgent >nul 2>&1
if %errorLevel% equ 0 (
    sc query DatadogAgent | find "RUNNING" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Datadog Agent is running
    ) else (
        echo     Datadog Agent is installed but not running
        echo     Start with: net start DatadogAgent
    )
) else (
    echo     Datadog Agent is not installed
    echo     For APM, install the Datadog Agent with APM enabled
)

REM ============================================
REM Configure Firewall
REM ============================================
echo.
echo [*] Configuring Windows Firewall...

netsh advfirewall firewall show rule name="Datadog APM Test App" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="Datadog APM Test App" dir=in action=allow protocol=TCP localport=%PORT% >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Firewall rule created for port %PORT%
    ) else (
        echo     Could not create firewall rule (may need admin rights)
    )
) else (
    echo     Firewall rule already exists
)

REM ============================================
REM Start Application
REM ============================================
if not exist "%SCRIPT_DIR%app.py" (
    echo [ERROR] Application file not found: %SCRIPT_DIR%app.py
    pause
    exit /b 1
)

echo.
echo =======================================================
echo   Starting Application
echo =======================================================
echo.
echo   URL: http://localhost:%PORT%
echo.
echo   Press Ctrl+C to stop
echo.

REM Run app directly - ddtrace is initialized via patch_all() in the code
REM Note: ddtrace-run has issues on Windows (OSError: Exec format error)
"%PYTHON_EXE%" "%SCRIPT_DIR%app.py"

pause
