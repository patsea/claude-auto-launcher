# Claude Auto Launcher - Enhanced Startup System

**Last Updated**: January 1, 2026

The `claude-auto` command provides an all-in-one launcher with intelligent health checking that:
1. Sets the working directory to `~/Dropbox/aloma/claude-code`
2. **Checks if services are already running and healthy**
3. **Skips starting healthy services** (no duplicate processes)
4. **Kills and restarts unhealthy services** automatically
5. Starts LLM Council (backend + frontend) if needed
6. Starts Workflow Generator if needed
7. Starts Workflow Automation if needed
8. Opens webpages in your browser
9. Launches Claude Code with auto-approved permissions

---

## Quick Start

### Start Everything

```bash
claude-auto
```

This single command:
- ✅ Changes to claude-code directory
- ✅ **Checks health of all 4 services** (ports 8001, 5173, 3001, 3000)
- ✅ **Skips services that are already running and healthy**
- ✅ **Kills and restarts unhealthy or unresponsive services**
- ✅ Starts LLM Council backend (port 8001) if needed
- ✅ Starts LLM Council frontend (port 5173) if needed
- ✅ Starts Workflow Generator (port 3001) if needed
- ✅ Starts Workflow Automation (port 3000) if needed
- ✅ Opens all web interfaces in browser
- ✅ Starts Claude Code with permissions pre-approved
- ✅ Saves process IDs for later cleanup

### Check Service Status

```bash
claude-auto-status
```

Shows which services are running and which have stopped.

### Stop All Services

```bash
claude-auto-stop
```

Cleanly stops all background services started by `claude-auto`.

---

## Available Commands

### 1. `claude-auto`

**Full launcher with all features**

```bash
# Usage
claude-auto

# What it does:
# 1. cd ~/Dropbox/aloma/claude-code
# 2. Starts llm-council backend (Python/FastAPI)
# 3. Starts llm-council frontend (React/Vite)
# 4. Starts workflow-generator (Node.js/Express)
# 5. Starts workflow-automation (Next.js)
# 6. Opens http://localhost:5173 (LLM Council)
# 7. Opens http://localhost:3001 (Workflow Generator)
# 8. Opens http://localhost:3000 (Workflow Automation)
# 9. Runs: claude --dangerously-skip-permissions
```

**Output Example** (when services are already running):
```
╔══════════════════════════════════════════════════════════╗
║           Claude Code Enhanced Launcher                  ║
╚══════════════════════════════════════════════════════════╝

✓ Directory: /Users/pwilliamson/Dropbox/aloma/claude-code

Checking Backend API...
  ✓ Backend API already running and healthy on http://localhost:8001

Checking LLM Council Frontend...
  ✓ LLM Council Frontend already running and healthy on http://localhost:5173

Checking Workflow Generator...
  ✓ Workflow Generator already running and healthy on http://localhost:3001

Checking Workflow Automation...
  ✓ Workflow Automation already running and healthy on http://localhost:3000

Waiting for services to be ready...
Opening webpages...
```

**Output Example** (when services need to be started):
```
╔══════════════════════════════════════════════════════════╗
║           Claude Code Enhanced Launcher                  ║
╚══════════════════════════════════════════════════════════╝

✓ Directory: /Users/pwilliamson/Dropbox/aloma/claude-code

Checking Backend API...
  Starting Backend API...
  Backend:  http://localhost:8001 (PID: 12345)

Checking LLM Council Frontend...
  Starting LLM Council Frontend...
  Frontend: http://localhost:5173 (PID: 12346)

Checking Workflow Generator...
  Starting Workflow Generator...
  Server:   http://localhost:3001 (PID: 12347)

Checking Workflow Automation...
  Starting Workflow Automation...
  Server:   http://localhost:3000 (PID: 12348)

Waiting for services to be ready...
Opening webpages...
```

**Output Example** (when services are unhealthy and need restart):
```
Checking Backend API...
  Killing existing processes on port 8001...
  Starting Backend API...
  Backend:  http://localhost:8001 (PID: 12349)
```

✓ All services running!

  LLM Council:            http://localhost:5173
  Workflow Generator:     http://localhost:3001
  Workflow Automation:    http://localhost:3000
  Backend API:            http://localhost:8001

  Logs:
    Backend:              tail -f /tmp/llm-council-backend.log
    Frontend:             tail -f /tmp/llm-council-frontend.log
    Workflow Generator:   tail -f /tmp/workflow-generator.log
    Workflow Automation:  tail -f /tmp/workflow-automation.log

  Stop services: claude-auto-stop

Starting Claude Code...
════════════════════════════════════════════════════════════
```

### 2. `claude-auto-stop`

**Stop all background services**

```bash
# Usage
claude-auto-stop

# What it does:
# - Kills all processes started by claude-auto
# - Cleans up PID file
# - Services can be restarted with claude-auto
```

**Output Example**:
```
Stopping Claude Auto services...
  Stopping PID 12345...
  Stopping PID 12346...
  Stopping PID 12347...
  Stopping PID 12348...
✓ All services stopped
```

### 3. `claude-auto-status`

**Check which services are running**

```bash
# Usage
claude-auto-status

# What it does:
# - Reads PID file
# - Checks if each process is still running
# - Reports status
```

**Output Example**:
```
Claude Auto Services Status:

  ✓ PID 12345 - Running
  ✓ PID 12346 - Running
  ✓ PID 12347 - Running
  ✓ PID 12348 - Running

Running: 4 | Stopped: 0
```

### 4. `ccode`

**Quick navigation to claude-code directory**

```bash
# Usage
ccode

# Equivalent to:
cd ~/Dropbox/aloma/claude-code
```

---

## Service URLs

Once `claude-auto` is running, access these URLs:

| Service | URL | Description |
|---------|-----|-------------|
| **LLM Council** | http://localhost:5173 | Multi-LLM deliberation interface |
| **Backend API** | http://localhost:8001 | FastAPI backend for LLM Council |
| **Workflow Automation** | http://localhost:3000 | ALOMA/n8n workflow automation studio |

---

## Log Files

Services log to `/tmp/` for easy debugging:

```bash
# Watch LLM Council backend logs
tail -f /tmp/llm-council-backend.log

# Watch LLM Council frontend logs (Vite)
tail -f /tmp/llm-council-frontend.log

# Watch Workflow Automation logs
tail -f /tmp/workflow-automation.log
```

**View all logs simultaneously**:
```bash
tail -f /tmp/llm-council-*.log /tmp/workflow-automation.log
```

---

## Process Management

### PID File

Services are tracked in: `~/.claude-auto-services.pid`

```bash
# View running PIDs
cat ~/.claude-auto-services.pid

# Example contents:
# 12345
# 12346
# 12347
# 12348
```

### Manual Process Management

If `claude-auto-stop` doesn't work, you can manually kill processes:

```bash
# Find processes
ps aux | grep -E "llm-council|workflow-automation|uvicorn|vite|next"

# Kill specific process
kill PID

# Force kill if needed
kill -9 PID
```

### Port Conflicts

If ports are already in use:

```bash
# Check what's using port 5173 (LLM Council frontend)
lsof -i :5173

# Check what's using port 8001 (Backend API)
lsof -i :8001

# Check what's using port 3000 (Workflow Automation)
lsof -i :3000

# Kill process using a port
kill $(lsof -t -i :5173)
kill $(lsof -t -i :3000)
```

---

## Troubleshooting

### Services Don't Start

**Check logs**:
```bash
tail -f /tmp/llm-council-backend.log
tail -f /tmp/llm-council-frontend.log
tail -f /tmp/workflow-automation.log
```

**Common issues**:

1. **Missing dependencies**:
   ```bash
   cd ~/Dropbox/aloma/claude-code/llm-council/frontend
   npm install

   cd ~/Dropbox/aloma/claude-code/workflow-automation
   pnpm install
   ```

2. **Python environment not set up**:
   ```bash
   cd ~/Dropbox/aloma/claude-code/llm-council
   uv sync
   ```

3. **Environment variables missing**:
   ```bash
   # Check .env files exist
   ls -la ~/Dropbox/aloma/claude-code/llm-council/.env
   ls -la ~/Dropbox/aloma/claude-code/workflow-automation/apps/web/.env.local
   ```

### Webpages Don't Open

**Manually open URLs**:
```bash
open http://localhost:5173
open http://localhost:3000
```

**Check if services are listening**:
```bash
curl http://localhost:5173
curl http://localhost:3000
curl http://localhost:8001
```

### Services Keep Running After Exit

**Clean stop**:
```bash
claude-auto-stop
```

**Manual cleanup**:
```bash
# Kill all related processes
pkill -f "llm-council"
pkill -f "workflow-automation"
pkill -f "uvicorn"
pkill -f "vite"
pkill -f "next"

# Remove PID file
rm ~/.claude-auto-services.pid
```

---

## Advanced Usage

### Run Without Auto-Starting Services

If you only want to navigate to the directory:

```bash
ccode
claude --dangerously-skip-permissions
```

### Start Individual Services

**LLM Council only**:
```bash
cd ~/Dropbox/aloma/claude-code/llm-council
./start.sh
```

**Workflow Automation only**:
```bash
cd ~/Dropbox/aloma/claude-code/workflow-automation
pnpm dev
```

### Custom Claude Code Launch

```bash
# Without skipping permissions
cd ~/Dropbox/aloma/claude-code
claude

# With different options
cd ~/Dropbox/aloma/claude-code
claude --model opus
```

---

## Integration with Claude Code

Once services are running, you can:

1. **Use LLM Council** for multi-model deliberation
   - Open http://localhost:5173
   - Ask questions to the council
   - Compare model responses
   - Export conversations

2. **Create Workflows** with AI assistance
   - Open http://localhost:3000
   - Describe workflow in plain English
   - Answer clarifying questions
   - Generate ALOMA steps or n8n workflows
   - Deploy directly to platforms

3. **Continue coding** with Claude Code
   - Services run in background
   - Web UIs accessible anytime
   - No manual startup needed

---

## Claude Code Best Practices

**IMPORTANT**: When working in the `~/Dropbox/aloma/claude-code` directory, Claude Code should **ALWAYS** reference the following document for coding guidance:

**📄 CLAUDE_CODE_UNIVERSAL_BEST_PRACTICES.md**

This document contains:
- ✅ Core principles for verification and testing
- ✅ File operation best practices (Read before Write)
- ✅ Task management workflows
- ✅ Error handling patterns
- ✅ Verification gates and testing protocols
- ✅ Common pitfalls to avoid
- ✅ Log analysis techniques

### Auto-Loading Best Practices

When `claude-auto` launches Claude Code, it should:

1. **Read the best practices document first**:
   ```
   Read: ~/Dropbox/aloma/claude-code/CLAUDE_CODE_UNIVERSAL_BEST_PRACTICES.md
   ```

2. **Follow the guidelines** for all coding operations:
   - Verify before acting (pwd, ls, etc.)
   - Read before writing/editing files
   - Use proper verification gates
   - Track tasks with TodoWrite
   - Run TypeScript checks and builds

3. **Reference project-specific instructions**:
   - Check for PHASE_*_INSTRUCTIONS.md files
   - Read CLAUDE.md in project subdirectories
   - Follow architecture documented in docs/

### Quick Reference

Before making any code changes:
```bash
# 1. Verify location
pwd

# 2. Check file exists
ls -la path/to/file.ts

# 3. Read existing content
Read tool: path/to/file.ts

# 4. Make changes with Edit tool (not Write)

# 5. Run verification
pnpm tsc --noEmit
pnpm build
```

**Path**: `/Users/pwilliamson/Dropbox/ALOMA/claude-code/CLAUDE_CODE_UNIVERSAL_BEST_PRACTICES.md`

---

## Configuration

### Customizing Ports

Edit the start scripts if you need different ports:

**LLM Council Backend** (change port 8001):
```bash
# Edit llm-council/backend/main.py
# Change: uvicorn.run(app, host="0.0.0.0", port=8001)
```

**LLM Council Frontend** (change port 5173):
```bash
# Edit llm-council/frontend/vite.config.js
# Add: server: { port: 5173 }
```

**Workflow Automation** (change port 3000):
```bash
# Next.js uses port 3000 by default
# To change: Edit workflow-automation/apps/web/next.config.js
# Or use: pnpm dev -- -p <port>
```

### Customizing Auto-Launch

Edit `~/.bash_profile` to modify the `claude-auto` function:

```bash
# Edit
nano ~/.bash_profile

# Reload after changes
source ~/.bash_profile
```

---

## Uninstalling

To remove the `claude-auto` commands:

```bash
# 1. Stop all services
claude-auto-stop

# 2. Edit bash profile
nano ~/.bash_profile

# 3. Remove the claude-auto functions

# 4. Reload
source ~/.bash_profile

# 5. Clean up logs (optional)
rm /tmp/llm-council-*.log
rm /tmp/workflow-automation.log
rm ~/.claude-auto-services.pid
```

---

## Tips & Best Practices

1. **Always use `claude-auto-stop`** when done to clean up processes

2. **Check status** if webpages aren't loading:
   ```bash
   claude-auto-status
   ```

3. **View logs** if something breaks:
   ```bash
   tail -f /tmp/llm-council-backend.log
   ```

4. **Kill zombies** if services hang:
   ```bash
   claude-auto-stop
   pkill -9 -f "uvicorn|vite|node"
   ```

5. **Test services independently** first:
   ```bash
   cd llm-council && ./start.sh
   cd workflow-automation && pnpm dev
   ```

---

## System Requirements

- **macOS** (uses `open` command)
- **Node.js 18+** for frontend services
- **Python 3.10+** with `uv` for backend
- **Port availability**: 3000, 5173, 8001
- **Browser**: Any modern browser

---

## How Health Checking Works

The `claude-auto` launcher now includes intelligent health checking:

### Health Check Process

For each service (ports 8001, 5173, 3001, 3000):

1. **Check if port is listening**: Uses `lsof` to verify the port is open
2. **Verify HTTP response**: Attempts to connect via `curl` with 2-second timeout
3. **Decision logic**:
   - **Healthy**: Port listening + HTTP responds → Skip starting, reuse existing process
   - **Unhealthy**: Port listening but no HTTP response → Kill and restart
   - **Not running**: Port not listening → Start fresh

### Benefits

- **No duplicate processes**: Won't start services that are already running
- **Automatic recovery**: Detects and restarts unhealthy/crashed services
- **Faster startup**: Skips initialization for healthy services
- **Clean process management**: Always maintains accurate PID tracking

### Exact Localhost URLs

All services use explicit `http://localhost:PORT` URLs:
- Backend API: `http://localhost:8001`
- LLM Council Frontend: `http://localhost:5173`
- Workflow Generator: `http://localhost:3001`
- Workflow Automation: `http://localhost:3000`

---

## Version History

### January 1, 2026 (v2.0)
- ✅ **Added intelligent health checking** for all services
- ✅ **Skip starting services** that are already running and healthy
- ✅ **Auto-restart unhealthy services** with port cleanup
- ✅ **Enhanced PID tracking** - always accurate, includes existing processes
- ✅ Added `check_service_health()` helper function
- ✅ Added `kill_port()` helper function for clean port cleanup
- ✅ All services use exact `http://localhost:PORT` URLs

### January 1, 2026 (v1.0)
- ✅ Added Workflow Automation (Next.js) to auto-launcher
- ✅ Now starts 4 services: LLM Council (backend + frontend), Workflow Generator, Workflow Automation
- ✅ Updated all documentation to reflect new service
- ✅ Added port 3000 for Workflow Automation
- ✅ Updated log file references

### December 30, 2025
- ✅ Added "Claude Code Best Practices" section
- ✅ Integrated CLAUDE_CODE_UNIVERSAL_BEST_PRACTICES.md reference
- ✅ Added auto-loading instructions for best practices
- ✅ Added quick reference guide for code changes

### December 29, 2025
- ✅ Created enhanced `claude-auto` launcher
- ✅ Added `claude-auto-stop` for cleanup
- ✅ Added `claude-auto-status` for monitoring
- ✅ Integrated LLM Council services
- ✅ Integrated Workflow Generator
- ✅ Added automatic webpage opening
- ✅ Added log file support
- ✅ Added PID tracking

---

## Support

**Common Commands**:
```bash
claude-auto           # Start everything
claude-auto-status    # Check status
claude-auto-stop      # Stop all services
ccode                 # Go to directory
```

**Get Help**:
- Check logs: `/tmp/*.log`
- View processes: `ps aux | grep -E "uvicorn|vite|node"`
- Check ports: `lsof -i :5173 -i :8001 -i :3000`

---

**Ready to use!** Just run `claude-auto` to start your enhanced Claude Code environment.
