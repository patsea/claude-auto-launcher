# ⛔ NEVER EDIT FILES IN ~/.claude-auto/

Edit SOURCE files in THIS directory, then run `./install.sh`

| Source (edit here) | Installed (never edit) |
|--------------------|------------------------|
| bin/claude-auto | ~/.claude-auto/bin/claude-auto |
| lib/helpers.sh | ~/.claude-auto/lib/helpers.sh |
| lib/status-helpers.sh | ~/.claude-auto/lib/status-helpers.sh |

## Version: 3.4

### Changelog

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
