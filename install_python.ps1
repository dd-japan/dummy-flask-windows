# ============================================
# Python 3 Installation Script for Windows Server 2019
# ============================================
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Run: powershell -ExecutionPolicy Bypass -File .\install_python.ps1
#
# ============================================

param(
    [string]$PythonVersion = "3.11.9"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$PythonInstallerUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe"
$PythonInstallerPath = "$env:TEMP\python-$PythonVersion-installer.exe"
$PythonInstallDir = "C:\Python311"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# ============================================
# Check Prerequisites
# ============================================
Write-Header "Python $PythonVersion Installation"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-ErrorMsg "This script must be run as Administrator"
    Write-Host "    Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Gray
    exit 1
}
Write-Success "Running with Administrator privileges"

# Check Windows version
$osInfo = Get-CimInstance Win32_OperatingSystem
Write-Success "Operating System: $($osInfo.Caption)"

# ============================================
# Check if Python is already installed
# ============================================
Write-Step "Checking for existing Python installation..."

$pythonExists = $false
try {
    $pythonVersion = & python --version 2>&1
    if ($pythonVersion -match "Python 3") {
        $pythonExists = $true
        Write-Success "Python is already installed: $pythonVersion"
        Write-Host ""
        $response = Read-Host "Do you want to reinstall Python? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Skipping Python installation." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Python location:" -ForegroundColor Cyan
            & where python
            exit 0
        }
    }
} catch {
    Write-Host "    Python not found, proceeding with installation..." -ForegroundColor Gray
}

# ============================================
# Download Python
# ============================================
Write-Step "Downloading Python $PythonVersion..."
Write-Host "    URL: $PythonInstallerUrl" -ForegroundColor Gray

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $PythonInstallerUrl -OutFile $PythonInstallerPath -UseBasicParsing
    Write-Success "Downloaded Python installer"
} catch {
    Write-ErrorMsg "Failed to download Python installer: $_"
    exit 1
}

# ============================================
# Install Python
# ============================================
Write-Step "Installing Python $PythonVersion..."
Write-Host "    This may take a few minutes..." -ForegroundColor Gray

$installArgs = @(
    "/quiet",
    "InstallAllUsers=1",
    "PrependPath=1",
    "Include_test=0",
    "Include_pip=1",
    "TargetDir=$PythonInstallDir"
)

try {
    Start-Process -FilePath $PythonInstallerPath -ArgumentList $installArgs -Wait -NoNewWindow
    Write-Success "Python installed successfully"
} catch {
    Write-ErrorMsg "Failed to install Python: $_"
    exit 1
}

# Cleanup installer
Remove-Item -Path $PythonInstallerPath -Force -ErrorAction SilentlyContinue

# ============================================
# Refresh Environment
# ============================================
Write-Step "Refreshing environment variables..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# ============================================
# Verify Installation
# ============================================
Write-Step "Verifying Python installation..."

$pythonExe = "$PythonInstallDir\python.exe"
if (Test-Path $pythonExe) {
    Write-Success "Python executable found at: $pythonExe"
    & $pythonExe --version
    
    Write-Step "Verifying pip installation..."
    & $pythonExe -m pip --version
    Write-Success "pip is available"
} else {
    Write-ErrorMsg "Python executable not found at expected location"
    Write-Host "    Searching for Python..." -ForegroundColor Gray
    try {
        $pythonExe = (Get-Command python -ErrorAction Stop).Source
        Write-Success "Python found at: $pythonExe"
        & python --version
    } catch {
        Write-ErrorMsg "Could not locate Python. Please verify installation manually."
        exit 1
    }
}

# ============================================
# Complete
# ============================================
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  Python Installation Complete!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Python Path: $pythonExe" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open a NEW PowerShell window (to refresh PATH)" -ForegroundColor Gray
Write-Host "  2. Run: .\run_app.ps1" -ForegroundColor Gray
Write-Host ""
