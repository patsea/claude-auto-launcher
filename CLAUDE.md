# ⛔ NEVER EDIT FILES IN ~/.claude-auto/

Edit SOURCE files in THIS directory, then run `./install.sh`

| Source (edit here) | Installed (never edit) |
|--------------------|------------------------|
| bin/claude-auto | ~/.claude-auto/bin/claude-auto |
| lib/helpers.sh | ~/.claude-auto/lib/helpers.sh |
| lib/status-helpers.sh | ~/.claude-auto/lib/status-helpers.sh |

## Version: 3.8

### Changelog

**v3.8** (February 16, 2026)
- Fixed: claude-auto-nightly now reports heartbeats (resolved stale job alerts)
- Fixed: claude-auto-readme now reports heartbeats (resolved stale job alerts)
- Added: Heartbeat reporting to all launchd-managed jobs
- Changed: Both scripts now track execution time and report status to monitoring
- Reason: K8s local-cron-checker was alerting on stale heartbeats (36h old)

**v3.7** (February 16, 2026)
- Fixed: claude-auto launch now starts services (not just waits for them)
- Added: start_services_if_configured() to helpers.sh for reuse
- Fixed: pnpm PATH automatically added to claude-auto-launch
- Changed: helpers.sh v2.8 → v2.9
- Behavior: `claude-auto launch` now does start → wait → open browsers
- Verified: Services start correctly with pnpm in PATH

**v3.6** (February 16, 2026)
- Fixed: claude-auto launch now works (3 critical bugs resolved)
- Fixed: Config paths now include apps/ prefix (services can start)
- Added: load_project_config() bridge function (v3.x → v2.x format)
- Fixed: wait_for_all_services() supports unlimited services (was limited to 3)
- Fixed: launch_browser_tabs() supports unlimited URLs (was limited to 3)
- Fixed: claude-auto-launch now calls load_config before load_project_config
- Changed: helpers.sh v2.7 → v2.8
- Verified: End-to-end test with 3/4 services healthy, correct timeout behavior

**v3.5** (February 16, 2026)
- Fixed: claude-auto-audit now exits 0 when audit completes (v2.2)
- Changed: Exit code indicates audit execution status, not issue detection
- Removed: Dead code after exit (unreachable v2.1 health checks)
- Reason: Wrapper expects exit 0 on successful completion per design

**v3.4** (January 14, 2026)
- Fixed: Corrected permission format (removed incorrect parentheses)
- Changed: `"Bash(*)"` → `"Bash"` (and same for all tools)
- Changed: `"mcp__desktop-commander__*"` → `"mcp__desktop-commander"`
- Improved: Idempotency check now detects and fixes broken v3.3 format
- Reason: Claude Code requires tool names without wildcard syntax in JSON

**v3.3** (January 14, 2026)
- Permissions: Uses `.claude/settings.json` instead of `CLAUDE.md` for tool permissions
- More reliable: Claude Code reads `.claude/settings.json` directly
- Creates proper JSON permissions structure
- Idempotent: checks if already configured before writing
- Enables Bash(*), Read(*), Write(*), Edit(*), mcp__desktop-commander__* (incorrect format - fixed in v3.4)

**v3.2** (January 14, 2026)
- Auto-configure: Adds `allowedTools` section to CLAUDE.md on first run
- Enables Bash, Read, Write, Edit tools automatically
- Enables desktop-commander MCP tools
- Checks if already configured to avoid duplicates
- Logged to startup log for visibility

**v3.1** (January 14, 2026)
- Fixed: Background output race condition
- All background processes now redirect to `/tmp/claude-auto-startup.log`
- Prevents garbled text in Claude Code TUI
- Services, git status, and browser tabs launch in background without interfering with terminal

**v2.7** (January 4, 2026)
- Fixed: Port 3000 health check now accepts 307 redirects
- Auth-protected services (Workflow Automation) properly handled
- More accurate service status reporting

---

## Non-Negotiable Gate — ALOMA MCP NEVER

NEVER call any tool prefixed with `aloma_` or `aloma-admin_` in this session.
These tools connect directly to the production ALOMA database.
Use the ALOMA CLI only. If an aloma_ tool appears in the tool list: do not
call it, state the rule, stop.

