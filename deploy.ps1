# ============================================
# Datadog APM Python Test Application Deployment Script
# For Windows Server 2019
# ============================================
# 
# This script will:
# 1. Download and install Python 3.11
# 2. Install required Python packages (Flask, ddtrace)
# 3. Configure and start the APM test application
#
# Prerequisites:
# - Windows Server 2019
# - Administrator privileges
# - Internet access
# - Datadog Agent installed with APM enabled (optional but recommended)
#
# Usage:
#   1. Open PowerShell as Administrator
#   2. Set execution policy if needed: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#   3. Run: .\deploy.ps1
#
# Environment Variables (optional):
#   DD_SERVICE      - Service name in Datadog (default: apm-test-python)
#   DD_ENV          - Environment name (default: windows-test)
#   DD_VERSION      - Application version (default: 1.0.0)
#   DD_AGENT_HOST   - Datadog Agent host (default: localhost)
#   PORT            - Application port (default: 5000)
# ============================================

param(
    [string]$PythonVersion = "3.11.9",
    [int]$Port = 5000,
    [string]$ServiceName = "apm-test-python",
    [string]$Environment = "windows-test",
    [string]$AppVersion = "1.0.0",
    [switch]$SkipPythonInstall,
    [switch]$RunInBackground
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonInstallerUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.exe"
$PythonInstallerPath = "$env:TEMP\python-$PythonVersion-installer.exe"
$PythonInstallDir = "C:\Python311"

# Colors for output
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

# ============================================
# Step 1: Check Prerequisites
# ============================================
Write-Header "Checking Prerequisites"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator"
    Write-Info "Right-click PowerShell and select 'Run as Administrator'"
    exit 1
}
Write-Success "Running with Administrator privileges"

# Check Windows version
$osInfo = Get-CimInstance Win32_OperatingSystem
Write-Success "Operating System: $($osInfo.Caption) $($osInfo.Version)"

# ============================================
# Step 2: Install Python
# ============================================
Write-Header "Installing Python $PythonVersion"

if ($SkipPythonInstall) {
    Write-Info "Skipping Python installation (--SkipPythonInstall flag set)"
} else {
    # Check if Python is already installed
    $pythonExists = $false
    try {
        $pythonVersion = & python --version 2>&1
        if ($pythonVersion -match "Python 3") {
            $pythonExists = $true
            Write-Info "Python is already installed: $pythonVersion"
        }
    } catch {
        # Python not found
    }

    if (-not $pythonExists) {
        Write-Step "Downloading Python $PythonVersion installer..."
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $PythonInstallerUrl -OutFile $PythonInstallerPath -UseBasicParsing
            Write-Success "Downloaded Python installer"
        } catch {
            Write-Error "Failed to download Python installer: $_"
            exit 1
        }

        Write-Step "Installing Python $PythonVersion..."
        Write-Info "This may take a few minutes..."
        
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
            Write-Error "Failed to install Python: $_"
            exit 1
        }

        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Cleanup installer
        Remove-Item -Path $PythonInstallerPath -Force -ErrorAction SilentlyContinue
    }
}

# Verify Python installation
Write-Step "Verifying Python installation..."
$pythonPaths = @(
    "$PythonInstallDir\python.exe",
    "C:\Python311\python.exe",
    "C:\Python310\python.exe",
    "C:\Python39\python.exe"
)

$pythonExe = $null
foreach ($path in $pythonPaths) {
    if (Test-Path $path) {
        $pythonExe = $path
        break
    }
}

if (-not $pythonExe) {
    try {
        $pythonExe = (Get-Command python -ErrorAction Stop).Source
    } catch {
        Write-Error "Python executable not found. Please ensure Python is installed."
        exit 1
    }
}

$pipExe = Join-Path (Split-Path $pythonExe) "Scripts\pip.exe"
if (-not (Test-Path $pipExe)) {
    $pipExe = "pip"
}

Write-Success "Python found at: $pythonExe"
& $pythonExe --version

# ============================================
# Step 3: Install Dependencies
# ============================================
Write-Header "Installing Python Dependencies"

Write-Step "Upgrading pip..."
& $pythonExe -m pip install --upgrade pip --quiet

Write-Step "Installing required packages..."
$requirementsPath = Join-Path $ScriptDir "requirements.txt"

if (Test-Path $requirementsPath) {
    & $pythonExe -m pip install -r $requirementsPath --quiet
    Write-Success "Installed packages from requirements.txt"
} else {
    Write-Info "requirements.txt not found, installing packages manually..."
    & $pythonExe -m pip install Flask ddtrace --quiet
    Write-Success "Installed Flask and ddtrace"
}

# Verify installations
Write-Step "Verifying package installations..."
& $pythonExe -c "import flask; print(f'Flask version: {flask.__version__}')"
& $pythonExe -c "import ddtrace; print(f'ddtrace version: {ddtrace.__version__}')"

# ============================================
# Step 4: Configure Datadog Environment
# ============================================
Write-Header "Configuring Datadog APM Environment"

# Set environment variables
$env:DD_SERVICE = $ServiceName
$env:DD_ENV = $Environment
$env:DD_VERSION = $AppVersion
$env:DD_LOGS_INJECTION = "true"
$env:DD_TRACE_SAMPLE_RATE = "1"
$env:DD_PROFILING_ENABLED = "true"
$env:PORT = $Port

Write-Info "DD_SERVICE    = $env:DD_SERVICE"
Write-Info "DD_ENV        = $env:DD_ENV"
Write-Info "DD_VERSION    = $env:DD_VERSION"
Write-Info "DD_LOGS_INJECTION = $env:DD_LOGS_INJECTION"
Write-Info "PORT          = $env:PORT"

# Check if Datadog Agent is running
Write-Step "Checking Datadog Agent status..."
$agentService = Get-Service -Name "DatadogAgent" -ErrorAction SilentlyContinue
if ($agentService) {
    if ($agentService.Status -eq "Running") {
        Write-Success "Datadog Agent is running"
    } else {
        Write-Info "Datadog Agent is installed but not running"
        Write-Info "Start the agent with: Start-Service DatadogAgent"
    }
} else {
    Write-Info "Datadog Agent is not installed"
    Write-Info "For full APM functionality, install the Datadog Agent:"
    Write-Info "https://docs.datadoghq.com/agent/basic_agent_usage/windows/"
}

# ============================================
# Step 5: Start Application
# ============================================
Write-Header "Starting APM Test Application"

$appPath = Join-Path $ScriptDir "app.py"

if (-not (Test-Path $appPath)) {
    Write-Error "Application file not found: $appPath"
    exit 1
}

Write-Info "Application: $appPath"
Write-Info "Port: $Port"
Write-Info ""

# Configure firewall rule
Write-Step "Configuring Windows Firewall..."
$ruleName = "Datadog APM Test App"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existingRule) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Success "Firewall rule created for port $Port"
} else {
    Write-Info "Firewall rule already exists"
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║   Application Starting...                                 ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║   Access the application at:                              ║" -ForegroundColor Green
Write-Host "║   http://localhost:$Port                                   " -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║   Press Ctrl+C to stop the application                    ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# Start the application with ddtrace
if ($RunInBackground) {
    Write-Step "Starting application in background..."
    $process = Start-Process -FilePath $pythonExe -ArgumentList "-m", "ddtrace.commands.ddtrace_run", $appPath -WindowStyle Hidden -PassThru
    Write-Success "Application started in background (PID: $($process.Id))"
    Write-Info "To stop: Stop-Process -Id $($process.Id)"
} else {
    # Run in foreground with ddtrace instrumentation
    & $pythonExe -m ddtrace.commands.ddtrace_run $appPath
}
