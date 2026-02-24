# Datadog APM Test Application for Windows

A simple Python Flask application designed for testing Datadog APM features on Windows Server 2019.

## Features

- **Latency Testing**: Endpoints with configurable response delays (100ms to 5s+)
- **Error Testing**: Generate various HTTP errors (400, 404, 500) and exceptions
- **Nested Spans**: Test trace hierarchy with simple and complex nested operations
- **Database Simulation**: Simulated database operations with proper span tagging
- **Web Interface**: User-friendly HTML interface to trigger all test endpoints

## Prerequisites

- Windows Server 2019
- Administrator privileges
- Internet access (for installation)
- Datadog Agent installed with APM enabled (recommended)

## Quick Start

### Option 1: PowerShell Script (Recommended)

1. Open PowerShell as Administrator
2. Navigate to this directory
3. Run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\deploy.ps1
   ```

### Option 2: Manual Installation

1. Download and install Python 3.11+ from https://www.python.org/downloads/
2. Install dependencies:
   ```cmd
   pip install -r requirements.txt
   ```
3. Run the application:
   ```cmd
   set DD_SERVICE=apm-test-python
   set DD_ENV=windows-test
   python -m ddtrace.commands.ddtrace_run app.py
   ```

## Script Parameters

```powershell
.\deploy.ps1 [-PythonVersion "3.11.9"] [-Port 5000] [-ServiceName "apm-test-python"] 
             [-Environment "windows-test"] [-AppVersion "1.0.0"] 
             [-SkipPythonInstall] [-RunInBackground]
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-PythonVersion` | 3.11.9 | Python version to install |
| `-Port` | 5000 | Application port |
| `-ServiceName` | apm-test-python | Datadog service name |
| `-Environment` | windows-test | Datadog environment |
| `-AppVersion` | 1.0.0 | Application version |
| `-SkipPythonInstall` | false | Skip Python installation |
| `-RunInBackground` | false | Run app in background |

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
| `GET /nested/simple` | Simple nested spans |
| `GET /nested/complex` | Complex nested spans |
| `GET /nested/database` | Simulated DB operations |

## Datadog Agent Configuration

Ensure your Datadog Agent has APM enabled. In `datadog.yaml`:

```yaml
apm_config:
  enabled: true
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DD_SERVICE` | apm-test-python | Service name in Datadog |
| `DD_ENV` | - | Environment (e.g., production, staging) |
| `DD_VERSION` | - | Application version |
| `DD_AGENT_HOST` | localhost | Datadog Agent host |
| `DD_TRACE_AGENT_PORT` | 8126 | Datadog Agent trace port |
| `PORT` | 5000 | Application port |

## Viewing Traces in Datadog

1. Log in to Datadog
2. Navigate to APM > Traces
3. Filter by service: `apm-test-python`
4. Filter by environment: `windows-test`

## Troubleshooting

### Python not found after installation
Restart PowerShell to refresh environment variables.

### Port already in use
Change the port: `.\deploy.ps1 -Port 8080`

### Firewall blocking access
The script automatically creates a firewall rule. If issues persist:
```powershell
New-NetFirewallRule -DisplayName "APM Test App" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```

### Traces not appearing in Datadog
1. Verify Datadog Agent is running: `Get-Service DatadogAgent`
2. Check Agent status: `& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status`
3. Verify APM is enabled in Agent configuration
