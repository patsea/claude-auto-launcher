# claude-auto v3.0

<!-- AUTO-GENERATED: Recent Changes -->
### Recent Activity

**Last Updated**: 2026-01-30
**Commits This Week**: 7

**Today's Commits** (1):
- `8ef05bf` chore: auto-commit: 1 files 2026-01-30

**Recent Changes** (1 files):
- `README.md`
<!-- END AUTO-GENERATED -->


**Config-driven launcher for Claude Code with automated git management, service orchestration, and nightly maintenance.**

Version: 3.0
Last Updated: January 12, 2026

---

## Overview

Claude Auto Launcher is an all-in-one development environment launcher that automatically starts and manages multiple services for your development workspace. It provides intelligent health checking, automatic recovery, nightly maintenance, and seamless Claude Code integration.

### Features

✅ **Config-Driven Architecture** - Customize via `~/.claude-auto.conf`, no code changes needed
✅ **Separated Concerns** - Startup tasks vs. nightly maintenance
✅ **Nightly Auto-Commit** - Daily backup of uncommitted work via launchd
✅ **Slack Notifications** - Get nightly maintenance reports
✅ **Repo Discovery** - Automatically find new git repos and suggest additions
✅ **Intelligent Health Checking** - Detects and reuses healthy running services
✅ **Fast Background Execution** - Claude Code starts in ~1-2s
✅ **Automatic Recovery** - Kills and restarts unhealthy processes
✅ **Multi-Service Management** - Manages multiple services simultaneously
✅ **Security Scans** - Nightly checks for secrets in staged files

---

## Quick Start

### 1. Create Your Config

```bash
cp lib/claude-auto.conf.example ~/.claude-auto.conf
# Edit with your settings
```

### 2. Configure (minimum required)

```bash
# ~/.claude-auto.conf
CLAUDE_AUTO_WORKDIR="$HOME/path/to/your/projects"
CLAUDE_AUTO_REPOS="repo1 repo2 repo3"
CLAUDE_AUTO_GIT_EMAIL="you@example.com"
```

### 3. Add to PATH

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/path/to/claude-auto-launcher/bin"
```

### 4. Run

```bash
claude-auto
```

---

## Configuration Reference

### Required Settings

| Setting | Description |
|---------|-------------|
| `CLAUDE_AUTO_WORKDIR` | Root directory for projects |
| `CLAUDE_AUTO_REPOS` | Space-separated repo names |
| `CLAUDE_AUTO_GIT_EMAIL` | Email for git commits |

### Optional Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `CLAUDE_AUTO_BEST_PRACTICES` | - | Path to best practices file for Claude |
| `CLAUDE_AUTO_SERVICES` | `()` | Array of services to start |
| `CLAUDE_AUTO_BROWSER_URLS` | `()` | URLs to open after services start |
| `CLAUDE_AUTO_SLACK_WEBHOOK` | - | Slack webhook for nightly reports |
| `CLAUDE_AUTO_COMMIT_ENABLED` | false | Enable nightly auto-commit |
| `CLAUDE_AUTO_DISCOVERY_PATHS` | - | Paths to scan for new repos |

### Service Configuration

Services are defined as an array with format `"name:port:start_command:health_path"`:

```bash
CLAUDE_AUTO_SERVICES=(
    "backend-api:8001:cd my-api && npm run dev:/health"
    "frontend:3000:cd my-web && npm start:/"
    "docs:3001:cd my-docs && npm run dev:/"
)
```

---

## Commands

| Command | Description |
|---------|-------------|
| `claude-auto` | Launch Claude Code + start services |
| `claude-auto-nightly` | Run maintenance (usually via launchd) |
| `claude-auto-stop` | Stop all managed services |
| `claude-auto-status` | Check status of all services |

---

## What Happens at Startup

When you run `claude-auto`:

1. **Loads config** from `~/.claude-auto.conf`
2. **Changes directory** to `CLAUDE_AUTO_WORKDIR`
3. **Checks health** of configured services (HTTP connectivity test)
4. **Starts missing/unhealthy services** in background
5. **Opens browser tabs** for configured URLs
6. **Launches Claude Code** immediately
7. **Shows git status** for repos with uncommitted changes

---

## Nightly Maintenance

Runs at 2 AM via launchd (macOS) or cron (Linux):

- 🔗 Convert HTTPS remotes → SSH
- 🔒 Security scan for secrets in staged files
- 📦 Auto-commit & push (if enabled)
- 🔍 Discover new repos and suggest additions
- 🗑️ Clean up old log files (>7 days)
- 📨 Send Slack summary

### Install Nightly Job (macOS)

```bash
launchctl load ~/Library/LaunchAgents/com.claude-auto.nightly.plist
```

### Install Nightly Job (Linux)

```bash
crontab -e
# Add: 0 2 * * * /path/to/bin/claude-auto-nightly
```

### Test Manually

```bash
claude-auto-nightly
cat /tmp/claude-auto-nightly-$(date +%Y-%m-%d).log
```

---

## Logs and Debugging

### Nightly Logs

```bash
# View today's nightly log
cat /tmp/claude-auto-nightly-$(date +%Y-%m-%d).log

# View launchd output
cat /tmp/claude-auto-nightly-launchd.log
```

### Service Logs

All services log to `/tmp/`:

```bash
# Watch backend logs
tail -f /tmp/llm-council-backend.log

# Watch all logs
tail -f /tmp/*.log
```

### Check launchd Status

```bash
launchctl list | grep claude-auto
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
   cd ~/Dropbox/ALOMA/claude-code/llm-council
   pnpm install
   ```

2. **Python environment:**
   ```bash
   cd ~/Dropbox/ALOMA/claude-code/llm-council
   uv sync
   ```

3. **Missing environment variables:**
   ```bash
   ls -la .env
   ls -la apps/web/.env.local
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

### Webpages Don't Open

**Manually open:**
```bash
open http://localhost:5173
open http://localhost:3000
```

**Check if services are responding:**
```bash
curl http://localhost:5173
curl http://localhost:8001
```

### Services Keep Running After Exit

**Clean stop:**
```bash
claude-auto-stop
```

**Manual cleanup:**
```bash
pkill -f "uvicorn|vite|node"
rm ~/.claude-auto-services.pid
```

### Nightly Job Not Running

```bash
# Check if loaded
launchctl list | grep claude-auto

# Reload
launchctl unload ~/Library/LaunchAgents/com.claude-auto.nightly.plist
launchctl load ~/Library/LaunchAgents/com.claude-auto.nightly.plist

# Test manually
claude-auto-nightly
```

### Test Slack Webhook

```bash
curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"Test from claude-auto"}' \
    "$CLAUDE_AUTO_SLACK_WEBHOOK"
```

---

## Project Structure

```
claude-auto-launcher/
├── bin/
│   ├── claude-auto           # Main launcher (startup only)
│   ├── claude-auto-nightly   # Nightly maintenance
│   ├── claude-auto-stop      # Service stopper
│   └── claude-auto-status    # Status checker
├── lib/
│   ├── config.sh             # Configuration loader
│   ├── helpers.sh            # Shared helper functions
│   └── claude-auto.conf.example  # Config template
├── backups/                  # Previous version backups
├── install.sh                # Installation script
└── README.md                 # This file
```

---

## Advanced Usage

### Run Without Auto-Starting Services

```bash
cd ~/Dropbox/ALOMA/claude-code
claude
```

### Start Individual Services

```bash
# LLM Council only
cd ~/Dropbox/ALOMA/claude-code/llm-council
./start.sh

# Workflow Automation only
cd ~/Dropbox/ALOMA/claude-code/workflow-automation
pnpm dev
```

### Custom Claude Code Launch

```bash
# With different model
claude --model opus
```

### Override Config Location

```bash
CLAUDE_AUTO_CONFIG=/path/to/custom.conf claude-auto
```

---

## Uninstalling

```bash
# 1. Stop all services
claude-auto-stop

# 2. Unload nightly job
launchctl unload ~/Library/LaunchAgents/com.claude-auto.nightly.plist
rm ~/Library/LaunchAgents/com.claude-auto.nightly.plist

# 3. Remove config
rm ~/.claude-auto.conf

# 4. Remove from PATH (edit ~/.zshrc or ~/.bashrc)

# 5. Clean up logs (optional)
rm /tmp/claude-auto-*.log
rm ~/.claude-auto-services.pid
```

---

## Migration from v2.7

v3.0 introduces config-driven architecture and separates startup from nightly tasks:

| v2.7 Behavior | v3.0 Behavior |
|---------------|---------------|
| Hardcoded paths in scripts | Config file at `~/.claude-auto.conf` |
| Auto-commit on startup | Auto-commit at 2 AM via launchd |
| HTTPS→SSH on startup | HTTPS→SSH at 2 AM via launchd |
| Security scan on startup | Security scan at 2 AM via launchd |
| No Slack notifications | Nightly Slack summary |
| No repo discovery | Nightly discovery with suggestions |

**Your v2.7 implementation is backed up in `backups/v2-YYYYMMDD/`**

---

## Version History

### v3.0 (January 12, 2026) - Config-Driven Architecture
- ✅ **Config-Driven**: All settings in `~/.claude-auto.conf`
- ✅ **Separated Concerns**: Startup vs. nightly maintenance
- ✅ **Nightly Launchd Job**: Auto-commit, security scan, HTTPS→SSH at 2 AM
- ✅ **Slack Notifications**: Daily maintenance reports
- ✅ **Repo Discovery**: Find new repos and suggest additions
- ✅ **Shareable**: Others can use with their own config
- 📖 **Documentation**: Added Pitfall 61 to Universal Best Practices

### v2.7 (January 4, 2026) - macOS Python Compatibility & Health Check Fix
- ✅ **Python Command Compatibility** - Changed `python` to `python3` for macOS
- ✅ **Virtual Environment Optimization** - Use `.venv/bin/python3` directly
- ✅ **Health Check Enhancement** - Accept 3xx redirects as healthy

### v2.6 (January 3, 2026) - V26 FAST BACKGROUND
- ✅ **Parallel Port Checking** - All ports checked simultaneously (4x faster)
- ✅ **Parallel Service Startup** - Frontend services start concurrently
- ✅ **Enhanced PID Tracking** - JSON format with metadata

### v2.5 (January 2, 2026) - Fast Start Edition
- ✅ Background checks and service startup
- ✅ Immediate Claude Code launch

### v2.4 (January 2, 2026) - Comprehensive Edition
- ✅ Pre-flight security checks
- ✅ Cache clearing for Next.js

### v2.0 (January 1, 2026)
- ✅ Added intelligent health checking
- ✅ Skip starting healthy services
- ✅ Auto-restart unhealthy services

### v1.0 (December 29, 2025)
- ✅ Initial release

---

## Support

**Quick Reference:**
```bash
claude-auto           # Start everything
claude-auto-status    # Check status
claude-auto-stop      # Stop all services
claude-auto-nightly   # Run maintenance manually
```

**Get Help:**
- Check logs: `/tmp/claude-auto-*.log`
- View processes: `ps aux | grep -E "uvicorn|vite|node"`
- Check ports: `lsof -i :5173 -i :8001 -i :3000 -i :3001`

---

## License

MIT

---

**Ready to use!** Run `claude-auto` to start your development environment.
