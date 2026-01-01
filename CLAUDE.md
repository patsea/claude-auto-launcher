# Claude Code Instructions - Claude Auto Launcher

**Project**: Claude Auto Launcher
**Type**: Development Tools / Shell Scripts
**Working Directory**: `/Users/pwilliamson/Dropbox/aloma/claude-code/claude-auto-launcher/`

---

## Project Overview

Claude Auto Launcher is a collection of shell scripts that provides an enhanced development environment launcher for the ALOMA claude-code workspace. It manages multiple services (LLM Council, Workflow Generator, Workflow Automation) with intelligent health checking and automatic recovery.

---

## Project Structure

```
claude-auto-launcher/
├── bin/
│   ├── claude-auto           # Main launcher (bash script)
│   ├── claude-auto-stop      # Service stopper (bash script)
│   └── claude-auto-status    # Status checker (bash script)
├── lib/
│   └── helpers.sh            # Shared helper functions
├── docs/
│   └── USAGE.md              # Detailed usage documentation
├── install.sh                # Installation script
├── README.md                 # Project documentation
└── CLAUDE.md                 # This file
```

---

## Technology Stack

- **Language**: Bash/Shell Scripts
- **Dependencies**:
  - `lsof` (port checking)
  - `curl` (health checks)
  - `open` (macOS browser launching)
  - Standard Unix utilities (ps, kill, grep, etc.)

---

## Working on This Project

### Before Making Changes

1. **Read the scripts** - All logic is in bash scripts:
   ```bash
   Read: bin/claude-auto
   Read: lib/helpers.sh
   ```

2. **Verify changes work**:
   ```bash
   # Test the modified script
   ./bin/claude-auto --help

   # Or reinstall and test
   ./install.sh
   source ~/.bash_profile
   claude-auto
   ```

3. **Check syntax**:
   ```bash
   # Use shellcheck if available
   shellcheck bin/claude-auto

   # Or just run the script to check for errors
   bash -n bin/claude-auto
   ```

### File Operation Rules

- **Shell scripts are executable** - Always maintain +x permissions
- **Use Read tool** before editing scripts
- **Test changes** before committing
- **Update documentation** if behavior changes

### Common Tasks

#### Adding a New Service

1. Edit `bin/claude-auto`
2. Add health check for new port
3. Add service startup logic
4. Update README.md with new service info
5. Update docs/USAGE.md

#### Modifying Health Check Logic

1. Edit `lib/helpers.sh`
2. Modify `check_service_health()` function
3. Test with running services
4. Test with stopped services
5. Test with unhealthy services

#### Changing Ports or URLs

1. Edit `bin/claude-auto`
2. Update port numbers in health checks
3. Update README.md documentation
4. Update docs/USAGE.md

---

## Testing Guidelines

### Manual Testing Checklist

- [ ] Fresh install works (`./install.sh`)
- [ ] `claude-auto` starts all services
- [ ] `claude-auto` skips healthy services (run twice)
- [ ] `claude-auto-status` shows correct status
- [ ] `claude-auto-stop` stops all services
- [ ] Health checks detect unhealthy services
- [ ] Port conflicts are handled gracefully
- [ ] Logs are written to `/tmp/`
- [ ] PID file is created/updated correctly

### Test Scenarios

1. **Clean start** - No services running:
   ```bash
   claude-auto-stop
   claude-auto
   ```

2. **Already running** - All services healthy:
   ```bash
   claude-auto  # First time
   claude-auto  # Second time - should skip all
   ```

3. **Partial failure** - Some services crashed:
   ```bash
   # Kill one service manually
   kill $(lsof -t -i :5173)
   claude-auto  # Should restart only crashed service
   ```

4. **Port conflict** - Another process using port:
   ```bash
   # Start something on port 5173
   python -m http.server 5173 &
   claude-auto  # Should kill and replace
   ```

---

## Best Practices

### When Editing Shell Scripts

1. **Always use Read tool first**:
   ```
   Read: bin/claude-auto
   ```

2. **Test syntax before committing**:
   ```bash
   bash -n bin/claude-auto
   ```

3. **Preserve execute permissions**:
   ```bash
   ls -la bin/  # Check permissions after editing
   chmod +x bin/claude-auto  # If needed
   ```

4. **Update version history** in README.md if significant changes

### When Updating Documentation

1. **Keep README.md in sync** with code changes
2. **Update docs/USAGE.md** for detailed changes
3. **Update version history** section
4. **Test all documented commands** to ensure accuracy

---

## Troubleshooting Development Issues

### Scripts Won't Execute

```bash
# Check permissions
ls -la bin/

# Fix if needed
chmod +x bin/*
```

### Changes Not Taking Effect

```bash
# Reinstall
./install.sh

# Reload shell
source ~/.bash_profile

# Verify installation
which claude-auto
```

### Testing Health Checks

```bash
# Source helpers directly
source lib/helpers.sh

# Test function
check_service_health 5173 "Test Service"
echo $?  # Should be 0 if healthy, 1 if not
```

---

## Integration with Claude Code Workspace

This project is part of the larger claude-code workspace. When working here:

1. **Don't modify project services** - This launcher manages them, doesn't implement them
2. **Coordinate port changes** - If other projects change ports, update scripts
3. **Follow workspace conventions** - See `../CLAUDE.md` for workspace-wide guidelines

---

## Version Information

- **Current Version**: 2.0
- **Last Updated**: January 1, 2026
- **Changelog**: See README.md "Version History" section

---

## Quick Reference

### Essential Commands

```bash
# Install/Reinstall
./install.sh && source ~/.bash_profile

# Test main launcher
./bin/claude-auto

# Test stop
./bin/claude-auto-stop

# Test status
./bin/claude-auto-status

# Check syntax
bash -n bin/claude-auto
```

### File Locations After Install

- Scripts: `~/.claude-auto/bin/`
- Libraries: `~/.claude-auto/lib/`
- Configuration: `~/.bash_profile` (PATH and alias)
- Logs: `/tmp/llm-council-*.log`, `/tmp/workflow-*.log`
- PID file: `~/.claude-auto-services.pid`

---

**When in doubt, test manually before committing changes!**
