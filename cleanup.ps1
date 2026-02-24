# ============================================
# Datadog APM Test Application Cleanup Script
# ============================================
#
# This script will:
# 1. Stop the running application
# 2. Remove Windows Firewall rule
# 3. Optionally uninstall Python packages
# 4. Optionally uninstall Python
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\cleanup.ps1
#
# ============================================

param(
    [switch]$RemovePackages,
    [switch]$UninstallPython,
    [switch]$Force
)

$ErrorActionPreference = "SilentlyContinue"

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

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Gray
}

# ============================================
# Confirmation
# ============================================
Write-Header "Datadog APM Test Application Cleanup"

if (-not $Force) {
    Write-Host "This script will perform the following cleanup tasks:" -ForegroundColor Yellow
    Write-Host "  1. Stop running Flask application processes" -ForegroundColor Gray
    Write-Host "  2. Remove Windows Firewall rule" -ForegroundColor Gray
    if ($RemovePackages) {
        Write-Host "  3. Uninstall Python packages (Flask, ddtrace)" -ForegroundColor Gray
    }
    if ($UninstallPython) {
        Write-Host "  4. Uninstall Python" -ForegroundColor Gray
    }
    Write-Host ""
    $confirm = Read-Host "Do you want to continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Cleanup cancelled." -ForegroundColor Gray
        exit 0
    }
}

# ============================================
# Step 1: Stop Application
# ============================================
Write-Step "Stopping Flask application processes..."

# Find and stop Python processes running app.py
$pythonProcesses = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*app.py*" -or $_.CommandLine -like "*flask*"
}

if ($pythonProcesses) {
    foreach ($proc in $pythonProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force
            Write-Info "Stopped process: $($proc.Id)"
        } catch {
            Write-Info "Could not stop process: $($proc.Id)"
        }
    }
    Write-Success "Application processes stopped"
} else {
    Write-Info "No running application processes found"
}

# Also check for processes listening on port 5000
$netstatOutput = netstat -ano | Select-String ":5000"
if ($netstatOutput) {
    Write-Info "Checking for processes on port 5000..."
    foreach ($line in $netstatOutput) {
        if ($line -match '\s+(\d+)\s*$') {
            $pid = $matches[1]
            if ($pid -ne "0") {
                try {
                    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                    Write-Info "Stopped process on port 5000: PID $pid"
                } catch {
                    Write-Info "Could not stop PID $pid (may require admin rights)"
                }
            }
        }
    }
}

# ============================================
# Step 2: Remove Firewall Rule
# ============================================
Write-Step "Removing Windows Firewall rule..."

$ruleName = "Datadog APM Test App"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existingRule) {
    try {
        Remove-NetFirewallRule -DisplayName $ruleName
        Write-Success "Firewall rule removed: $ruleName"
    } catch {
        Write-Info "Could not remove firewall rule (may require admin rights)"
    }
} else {
    Write-Info "Firewall rule not found (already removed or never created)"
}

# ============================================
# Step 3: Remove Python Packages (Optional)
# ============================================
if ($RemovePackages) {
    Write-Step "Uninstalling Python packages..."
    
    $pythonExe = $null
    $pythonPaths = @(
        "C:\Python311\python.exe",
        "C:\Python310\python.exe",
        "C:\Python39\python.exe"
    )
    
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
            Write-Info "Python not found, skipping package removal"
        }
    }
    
    if ($pythonExe) {
        & $pythonExe -m pip uninstall Flask ddtrace -y 2>$null
        Write-Success "Python packages uninstalled"
    }
}

# ============================================
# Step 4: Uninstall Python (Optional)
# ============================================
if ($UninstallPython) {
    Write-Step "Uninstalling Python..."
    
    # Find Python uninstaller
    $uninstallers = Get-ChildItem -Path "C:\Python*" -Filter "uninstall.exe" -Recurse -ErrorAction SilentlyContinue
    
    if ($uninstallers) {
        foreach ($uninstaller in $uninstallers) {
            Write-Info "Running uninstaller: $($uninstaller.FullName)"
            Start-Process -FilePath $uninstaller.FullName -ArgumentList "/quiet" -Wait
        }
        Write-Success "Python uninstalled"
    } else {
        # Try via Windows Add/Remove Programs
        $pythonApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Python*" }
        if ($pythonApps) {
            foreach ($app in $pythonApps) {
                Write-Info "Uninstalling: $($app.Name)"
                $app.Uninstall() | Out-Null
            }
            Write-Success "Python uninstalled"
        } else {
            Write-Info "Python uninstaller not found. Please uninstall manually via Settings > Apps"
        }
    }
}

# ============================================
# Complete
# ============================================
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "  Cleanup Complete!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

if (-not $RemovePackages) {
    Write-Host "  To also remove Python packages, run:" -ForegroundColor Gray
    Write-Host "  .\cleanup.ps1 -RemovePackages" -ForegroundColor Cyan
}
if (-not $UninstallPython) {
    Write-Host ""
    Write-Host "  To also uninstall Python, run:" -ForegroundColor Gray
    Write-Host "  .\cleanup.ps1 -UninstallPython" -ForegroundColor Cyan
}
Write-Host ""
