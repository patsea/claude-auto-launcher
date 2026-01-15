# Claude Auto Launcher

**Enhanced startup system for Claude Code with intelligent service management**

Version: 2.7 (macOS Python Compatibility Edition)
Last Updated: January 4, 2026

---

## Overview

Claude Auto Launcher is an all-in-one development environment launcher that automatically starts and manages multiple services for your development workspace. It provides intelligent health checking, automatic recovery, and seamless Claude Code integration.

### Features

✅ **V26 Parallel Processing** - All port checks run simultaneously (4x faster)
✅ **Intelligent Health Checking** - Detects and reuses healthy running services
✅ **Smart Dependency Ordering** - Backend starts first, frontends in parallel
✅ **Enhanced PID Tracking** - JSON metadata with service names and timestamps
✅ **Fast Background Execution** - Claude Code starts in ~1-2s
✅ **Optimized Security Scans** - Parallel file processing for faster checks
✅ **Automatic Recovery** - Kills and restarts unhealthy processes
✅ **Multi-Service Management** - Manages 4 services simultaneously
✅ **Zero Configuration** - Works out of the box
✅ **Log Aggregation** - Centralized logging to /tmp/

---

## Quick Start

### Install

```bash
cd ~/Dropbox/claude-code/claude-auto-launcher
./install.sh
source ~/.bash_profile
```

### Use

```bash
# Start everything
claude-auto

# Check status
claude-auto-status

# Stop all services
claude-auto-stop

# Navigate to directory
ccode
```

---

## Services Managed

| Service | Port | Description |
|---------|------|-------------|
| **LLM Council Backend** | 8001 | FastAPI backend for multi-LLM deliberation |
| **LLM Council Frontend** | 5173 | React/Vite interface for LLM Council |
| **Workflow Generator** | 3001 | Node.js/Express workflow generation service |
| **Workflow Automation** | 3000 | Next.js workflow automation studio |

---

## What It Does

When you run `claude-auto`, the launcher:

1. **Changes directory** to `~/Dropbox/claude-code`
2. **Checks health** of all 4 services (HTTP connectivity test)
3. **Reuses healthy services** (no duplicate processes)
4. **Kills and restarts** unhealthy or crashed services
5. **Starts missing services** that aren't running
6. **Opens web interfaces** in your default browser
7. **Launches Claude Code** with pre-approved permissions
8. **Tracks PIDs** for clean shutdown

---

## Installation

### Prerequisites

- macOS (uses `open` command)
- Node.js 18+ for frontend services
- Python 3.10+ with `uv` for backend
- Available ports: 3000, 3001, 5173, 8001
- Modern web browser

### Install Steps

1. Navigate to the project directory:
   ```bash
   cd ~/Dropbox/claude-code/claude-auto-launcher
   ```

2. Run the installer:
   ```bash
   ./install.sh
   ```

3. Reload your shell:
   ```bash
   source ~/.bash_profile
   ```

4. Verify installation:
   ```bash
   which claude-auto
   # Should output: /Users/yourusername/.claude-auto/bin/claude-auto
   ```

### What Gets Installed

- **Binaries** → `~/.claude-auto/bin/`
  - `claude-auto` - Main launcher
  - `claude-auto-stop` - Service stopper
  - `claude-auto-status` - Status checker

- **Libraries** → `~/.claude-auto/lib/`
  - `helpers.sh` - Shared helper functions

- **Shell Configuration** → `~/.bash_profile`
  - Adds `~/.claude-auto/bin` to PATH
  - Creates `ccode` alias for quick navigation

---

## Usage

### Start Everything

```bash
claude-auto
```

**Example Output (services already running):**
```
╔══════════════════════════════════════════════════════════╗
║           Claude Code Enhanced Launcher                  ║
╚══════════════════════════════════════════════════════════╝

✓ Directory: /Users/pwilliamson/Dropbox/claude-code

Checking Backend API...
  ✓ Backend API already running and healthy on http://localhost:8001

Checking LLM Council Frontend...
  ✓ LLM Council Frontend already running and healthy on http://localhost:5173

Checking Workflow Generator...
  ✓ Workflow Generator already running and healthy on http://localhost:3001

Checking Workflow Automation...
  ✓ Workflow Automation already running and healthy on http://localhost:3000

✓ All services running!
```

### Check Status

```bash
claude-auto-status
```

**Example Output:**
```
Claude Auto Services Status:

  ✓ PID 12345 - Running
  ✓ PID 12346 - Running
  ✓ PID 12347 - Running
  ✓ PID 12348 - Running

Running: 4 | Stopped: 0
```

### Stop Services

```bash
claude-auto-stop
```

**Example Output:**
```
Stopping Claude Auto services...
  Stopping PID 12345...
  Stopping PID 12346...
  Stopping PID 12347...
  Stopping PID 12348...
✓ All services stopped
```

### Navigate to Directory

```bash
ccode
```

Equivalent to: `cd ~/Dropbox/claude-code`

---

## How Health Checking Works

### Health Check Process

For each service on ports 8001, 5173, 3001, 3000:

1. **Port Check**: Uses `lsof` to verify port is listening
2. **HTTP Check**: Attempts HTTP connection with 2-second timeout
3. **Decision Logic**:
   - ✅ **Healthy**: Port listening + HTTP responds → Skip, reuse process
   - ⚠️ **Unhealthy**: Port listening, no HTTP → Kill and restart
   - ❌ **Not Running**: Port not listening → Start fresh

### Benefits

- **No Duplicate Processes** - Won't start if already running
- **Automatic Recovery** - Detects and fixes crashed services
- **Faster Startup** - Skips initialization for healthy services
- **Clean Management** - Accurate PID tracking

---

## Configuration

### Environment Variables

You can customize the claude-code directory location:

```bash
export CLAUDE_CODE_DIR="$HOME/path/to/your/directory"
```

Default: `$HOME/Dropbox/claude-code`

### Customizing Ports

Edit the service start scripts if you need different ports:

**Backend (port 8001)**:
```bash
# Edit: llm-council/backend/main.py
# Change: uvicorn.run(app, host="0.0.0.0", port=8001)
```

**Frontend (port 5173)**:
```bash
# Edit: llm-council/frontend/vite.config.js
# Add: server: { port: 5173 }
```

**Workflow Automation (port 3000)**:
```bash
# Edit: workflow-automation/apps/web/package.json
# Change dev script to: "dev": "next dev -p 3000"
```

---

## Logs and Debugging

### Log Files

All services log to `/tmp/`:

```bash
# Watch backend logs
tail -f /tmp/llm-council-backend.log

# Watch frontend logs
tail -f /tmp/llm-council-frontend.log

# Watch workflow generator logs
tail -f /tmp/workflow-generator.log

# Watch workflow automation logs
tail -f /tmp/workflow-automation.log

# Watch all logs
tail -f /tmp/llm-council-*.log /tmp/workflow-*.log
```

### PID File

Service PIDs are tracked in: `~/.claude-auto-services.json` (v2.6+)

```bash
# View running PIDs (JSON format with metadata)
cat ~/.claude-auto-services.json

# Example contents:
# {
#   "backend": {
#     "pid": "12345",
#     "port": "8001",
#     "name": "Backend API",
#     "started": "2026-01-03T21:55:00Z"
#   },
#   "frontend": {
#     "pid": "12346",
#     "port": "5173",
#     "name": "LLM Council Frontend",
#     "started": "2026-01-03T21:55:01Z"
#   }
# }

# Pretty print with jq
jq '.' ~/.claude-auto-services.json
```

**Note:** If `jq` is not installed, a simple fallback format is used in `~/.claude-auto-services.json.simple`

### Manual Process Management

If `claude-auto-stop` doesn't work:

```bash
# Find all related processes
ps aux | grep -E "llm-council|workflow|uvicorn|vite|next"

# Kill specific PID
kill 12345

# Force kill
kill -9 12345

# Nuclear option (kills all related processes)
pkill -9 -f "uvicorn|vite|node"
rm ~/.claude-auto-services.pid
```

### Port Conflicts

Check what's using a port:

```bash
lsof -i :5173  # LLM Council frontend
lsof -i :8001  # Backend API
lsof -i :3000  # Workflow Automation
lsof -i :3001  # Workflow Generator

# Kill process on port
kill $(lsof -t -i :5173)
```

---

## Troubleshooting

### Services Won't Start

**Check logs first:**
```bash
tail -f /tmp/llm-council-backend.log
```

**Common issues:**

1. **Missing dependencies:**
   ```bash
   cd ~/Dropbox/claude-code/llm-council/frontend
   npm install

   cd ~/Dropbox/claude-code/workflow-automation
   pnpm install
   ```

2. **Python environment:**
   ```bash
   cd ~/Dropbox/claude-code/llm-council
   uv sync
   ```

3. **Missing environment variables:**
   ```bash
   ls -la ~/Dropbox/claude-code/llm-council/.env
   ls -la ~/Dropbox/claude-code/workflow-automation/apps/web/.env.local
   ```

### Webpages Don't Open

**Manually open:**
```bash
open http://localhost:5173
open http://localhost:3000
open http://localhost:3001
```

**Check if services are responding:**
```bash
curl http://localhost:5173
curl http://localhost:3000
curl http://localhost:8001
```

### Services Keep Running After Exit

**Clean stop:**
```bash
claude-auto-stop
```

**Manual cleanup:**
```bash
pkill -f "llm-council"
pkill -f "workflow"
pkill -f "uvicorn"
pkill -f "vite"
rm ~/.claude-auto-services.pid
```

---

## Project Structure

```
claude-auto-launcher/
├── bin/
│   ├── claude-auto           # Main launcher script
│   ├── claude-auto-stop      # Service stopper
│   └── claude-auto-status    # Status checker
├── lib/
│   └── helpers.sh            # Shared helper functions
├── docs/
│   └── USAGE.md              # Detailed usage documentation
├── install.sh                # Installation script
└── README.md                 # This file
```

---

## Uninstalling

```bash
# 1. Stop all services
claude-auto-stop

# 2. Remove installation directory
rm -rf ~/.claude-auto

# 3. Edit bash profile
nano ~/.bash_profile
# Remove the "Claude Auto Launcher" section

# 4. Reload shell
source ~/.bash_profile

# 5. Clean up logs (optional)
rm /tmp/llm-council-*.log
rm /tmp/workflow-*.log
rm ~/.claude-auto-services.pid
```

---

## Advanced Usage

### Run Without Auto-Starting Services

```bash
ccode
claude --dangerously-skip-permissions
```

### Start Individual Services

**LLM Council only:**
```bash
cd ~/Dropbox/claude-code/llm-council
./start.sh
```

**Workflow Automation only:**
```bash
cd ~/Dropbox/claude-code/workflow-automation
pnpm dev
```

### Custom Claude Code Launch

```bash
# Without skipping permissions
cd ~/Dropbox/claude-code
claude

# With different model
claude --model opus
```

---

## Version History

### v2.7 (January 4, 2026) - macOS Python Compatibility & Health Check Fix
- ✅ **CRITICAL FIX: Python Command Compatibility** - Changed `python` to `python3` for macOS compatibility
- ✅ **Virtual Environment Optimization** - Use `.venv/bin/python3` directly (no activation needed)
- ✅ **Service Startup Reliability** - LLM Council backend now starts successfully on macOS
- ✅ **Health Check Enhancement** - Accept 3xx redirects as healthy for port 3000 (auth-protected apps)
- 🐛 **Fixed**: `python: command not found` error on macOS systems
- 🐛 **Fixed**: Virtual environment activation failures in background processes
- 🐛 **Fixed**: Workflow Automation (port 3000) incorrectly marked as unhealthy due to auth redirect
- 📖 **Documentation**: Added Pitfall 54 to Universal Best Practices

**Why This Matters:**
macOS doesn't include a `python` command by default (only `python3`). This caused the LLM Council backend to fail startup with "command not found" errors. Additionally, apps requiring authentication (like Workflow Automation) return 307 redirects which were incorrectly flagged as unhealthy. Both fixes ensure cross-platform compatibility and accurate health monitoring.

### v2.6 (January 3, 2026) - V26 FAST BACKGROUND
- ✅ **Parallel Port Checking** - All 4 ports checked simultaneously (4x faster)
- ✅ **Parallel Service Startup** - Frontend services start concurrently
- ✅ **Smart Dependency Ordering** - Backend starts first as dependency
- ✅ **Enhanced PID Tracking** - JSON format with metadata (service names, ports, timestamps)
- ✅ **Optimized Background Jobs** - Better job control and output management
- ✅ **Fast Background Execution** - Claude Code starts in 1-2s (was 20-30s in v2.4)
- ✅ **Parallel Security Scans** - Files scanned in parallel batches
- ✅ **Better Error Messages** - Recovery suggestions for failed services
- ✅ **Performance Metrics** - Startup time and service count displayed

### v2.5 (January 2, 2026) - Fast Start Edition
- ✅ Background checks and service startup
- ✅ Immediate Claude Code launch
- ✅ Delayed output to screen

### v2.4 (January 2, 2026) - Comprehensive Edition
- ✅ Pre-flight security checks
- ✅ Cache clearing for Next.js
- ✅ Enhanced verification

### v2.0 (January 1, 2026)
- ✅ Added intelligent health checking
- ✅ Skip starting healthy services
- ✅ Auto-restart unhealthy services
- ✅ Enhanced PID tracking
- ✅ All services use explicit localhost URLs

### v1.0 (December 29, 2025)
- ✅ Initial release
- ✅ Manages 4 services
- ✅ Automatic webpage opening
- ✅ Log file support
- ✅ PID tracking

---

## Support

**Get Help:**
- Check logs: `/tmp/*.log`
- View processes: `ps aux | grep -E "uvicorn|vite|node"`
- Check ports: `lsof -i :5173 -i :8001 -i :3000 -i :3001`
- Documentation: `docs/USAGE.md`

**Common Commands:**
```bash
claude-auto           # Start everything
claude-auto-status    # Check status
claude-auto-stop      # Stop all services
ccode                 # Navigate to directory
```

---

## License

Development environment launcher and service manager.

---

**Ready to use!** Run `claude-auto` to start your enhanced development environment.
