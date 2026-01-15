#!/bin/bash
# config.sh - Configuration loader for claude-auto v3.0

load_config() {
    local config_file="${CLAUDE_AUTO_CONFIG:-$HOME/.claude-auto.conf}"
    
    if [[ ! -f "$config_file" ]]; then
        echo "❌ Config not found: $config_file"
        echo "   Run: cp lib/claude-auto.conf.example ~/.claude-auto.conf"
        exit 1
    fi
    
    # shellcheck source=/dev/null
    source "$config_file"
    
    # Expand variables
    CLAUDE_AUTO_WORKDIR=$(eval echo "$CLAUDE_AUTO_WORKDIR")
    CLAUDE_AUTO_BEST_PRACTICES=$(eval echo "$CLAUDE_AUTO_BEST_PRACTICES")
    CLAUDE_AUTO_DISCOVERY_PATHS=$(eval echo "$CLAUDE_AUTO_DISCOVERY_PATHS")
    
    # Validate required settings
    if [[ -z "$CLAUDE_AUTO_WORKDIR" ]]; then
        echo "❌ CLAUDE_AUTO_WORKDIR not set in config"
        exit 1
    fi
    
    if [[ ! -d "$CLAUDE_AUTO_WORKDIR" ]]; then
        echo "❌ CLAUDE_AUTO_WORKDIR does not exist: $CLAUDE_AUTO_WORKDIR"
        exit 1
    fi
}
