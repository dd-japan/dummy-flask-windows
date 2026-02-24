# ============================================
# Datadog APM Test Application Runner
# ============================================
#
# Prerequisites:
#   - Python 3 installed (run install_python.ps1 first)
#   - Datadog Agent installed with APM enabled (for tracing)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\run_app.ps1
#
# ============================================

param(
    [int]$Port = 5000,
    [string]$ServiceName = "apm-test-python",
    [string]$Environment = "windows-test",
    [string]$AppVersion = "1.0.0",
    [switch]$RunInBackground
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
# Find Python
# ============================================
Write-Header "Datadog APM Test Application"

Write-Step "Locating Python..."

$pythonPaths = @(
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
        Write-ErrorMsg "Python not found. Please run install_python.ps1 first."
        exit 1
    }
}

Write-Success "Python found: $pythonExe"
& $pythonExe --version

# ============================================
# Install Dependencies
# ============================================
Write-Step "Installing/updating dependencies..."

$requirementsPath = Join-Path $ScriptDir "requirements.txt"

& $pythonExe -m pip install --upgrade pip --quiet 2>$null

if (Test-Path $requirementsPath) {
    & $pythonExe -m pip install -r $requirementsPath --quiet
    Write-Success "Dependencies installed from requirements.txt"
} else {
    & $pythonExe -m pip install Flask --quiet
    Write-Success "Flask installed"
}

# ============================================
# Configure Environment Variables
# ============================================
Write-Step "Configuring Datadog APM environment..."

$env:DD_SERVICE = $ServiceName
$env:DD_ENV = $Environment
$env:DD_VERSION = $AppVersion
$env:DD_LOGS_INJECTION = "true"
$env:DD_TRACE_SAMPLE_RATE = "1"
$env:PORT = $Port

Write-Host "    DD_SERVICE = $env:DD_SERVICE" -ForegroundColor Gray
Write-Host "    DD_ENV     = $env:DD_ENV" -ForegroundColor Gray
Write-Host "    DD_VERSION = $env:DD_VERSION" -ForegroundColor Gray
Write-Host "    PORT       = $env:PORT" -ForegroundColor Gray

# ============================================
# Check Datadog Agent
# ============================================
Write-Step "Checking Datadog Agent status..."

$agentService = Get-Service -Name "DatadogAgent" -ErrorAction SilentlyContinue
if ($agentService) {
    if ($agentService.Status -eq "Running") {
        Write-Success "Datadog Agent is running"
    } else {
        Write-Host "    Datadog Agent is installed but not running" -ForegroundColor Yellow
        Write-Host "    Start with: Start-Service DatadogAgent" -ForegroundColor Gray
    }
} else {
    Write-Host "    Datadog Agent is not installed" -ForegroundColor Yellow
    Write-Host "    For APM, install the Datadog Agent with APM enabled" -ForegroundColor Gray
}

# ============================================
# Configure Firewall
# ============================================
Write-Step "Configuring Windows Firewall..."

$ruleName = "Datadog APM Test App"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existingRule) {
    try {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
        Write-Success "Firewall rule created for port $Port"
    } catch {
        Write-Host "    Could not create firewall rule (may need admin rights)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Firewall rule already exists" -ForegroundColor Gray
}

# ============================================
# Start Application
# ============================================
$appPath = Join-Path $ScriptDir "app.py"

if (-not (Test-Path $appPath)) {
    Write-ErrorMsg "Application file not found: $appPath"
    exit 1
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  Starting Application" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  URL: http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

if ($RunInBackground) {
    $process = Start-Process -FilePath $pythonExe -ArgumentList $appPath -WindowStyle Hidden -PassThru
    Write-Success "Application started in background (PID: $($process.Id))"
    Write-Host "    To stop: Stop-Process -Id $($process.Id)" -ForegroundColor Gray
} else {
    & $pythonExe $appPath
}
