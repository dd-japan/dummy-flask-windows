# Datadog APM Test Application for Windows

A simple Python Flask application designed for testing Datadog APM features on Windows Server 2019.

## Features

- **Latency Testing**: Endpoints with configurable response delays (100ms to 5s+)
- **Error Testing**: Generate various HTTP errors (400, 404, 500) and exceptions
- **Nested Operations**: Test with simple and complex nested operations
- **Database Simulation**: Simulated database operations
- **Web Interface**: User-friendly HTML interface to trigger all test endpoints

## Prerequisites

- Windows Server 2019
- Administrator privileges
- Internet access (for installation)
- Datadog Agent installed with APM enabled (for tracing)

## Quick Start

### Step 1: Install Python

**PowerShell (Recommended):**
```powershell
powershell -ExecutionPolicy Bypass -File .\install_python.ps1
```

**Or Batch:**
```cmd
install_python.bat
```

### Step 2: Run the Application

**PowerShell:**
```powershell
powershell -ExecutionPolicy Bypass -File .\run_app.ps1
```

**Or Batch:**
```cmd
run_app.bat
```

## Files

| File | Description |
|------|-------------|
| `install_python.ps1` | PowerShell script to install Python 3.11 |
| `install_python.bat` | Batch script to install Python 3.11 |
| `run_app.ps1` | PowerShell script to run the application |
| `run_app.bat` | Batch script to run the application |
| `app.py` | Flask application |
| `requirements.txt` | Python dependencies |

## Script Parameters (PowerShell)

**install_python.ps1:**
```powershell
.\install_python.ps1 [-PythonVersion "3.11.9"]
```

**run_app.ps1:**
```powershell
.\run_app.ps1 [-Port 5000] [-ServiceName "apm-test-python"] 
              [-Environment "windows-test"] [-AppVersion "1.0.0"] 
              [-RunInBackground]
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Web interface |
| `GET /health` | Health check |
| `GET /latency/fast` | 100ms delay |
| `GET /latency/medium` | 500ms delay |
| `GET /latency/slow` | 2s delay |
| `GET /latency/very-slow` | 5s delay |
| `GET /latency/custom?delay=<ms>` | Custom delay |
| `GET /error/500` | Internal Server Error |
| `GET /error/404` | Not Found Error |
| `GET /error/400` | Bad Request Error |
| `GET /error/exception` | Unhandled Exception |
| `GET /error/random` | 50% chance of error |
| `GET /nested/simple` | Simple nested operations |
| `GET /nested/complex` | Complex nested operations |
| `GET /nested/database` | Simulated DB operations |

## Datadog APM Integration

This application is designed to work with Datadog's **Single Step Instrumentation (SSI)**. The Datadog Agent automatically instruments Python applications without requiring code changes.

### Setup Datadog Agent with APM

1. Install Datadog Agent on Windows
2. Enable APM in `datadog.yaml`:
   ```yaml
   apm_config:
     enabled: true
   ```
3. Enable Single Step Instrumentation:
   ```yaml
   apm_config:
     instrumentation:
       enabled: true
   ```
4. Restart the Datadog Agent

### Environment Variables

The application sets these environment variables for Datadog:

| Variable | Default | Description |
|----------|---------|-------------|
| `DD_SERVICE` | apm-test-python | Service name in Datadog |
| `DD_ENV` | windows-test | Environment name |
| `DD_VERSION` | 1.0.0 | Application version |
| `DD_LOGS_INJECTION` | true | Inject trace IDs into logs |

## Viewing Traces in Datadog

1. Log in to Datadog
2. Navigate to APM > Traces
3. Filter by service: `apm-test-python`
4. Filter by environment: `windows-test`

## Troubleshooting

### Python not found after installation
Open a new command prompt/PowerShell window to refresh environment variables.

### Port already in use
Change the port:
```powershell
.\run_app.ps1 -Port 8080
```

### Firewall blocking access
Run as Administrator, or manually create the rule:
```powershell
New-NetFirewallRule -DisplayName "APM Test App" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```

### Traces not appearing in Datadog
1. Verify Datadog Agent is running: `Get-Service DatadogAgent`
2. Check Agent status: `& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status`
3. Verify APM and SSI are enabled in Agent configuration
