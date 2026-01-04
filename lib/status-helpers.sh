#!/bin/bash
# Service Status Helper Functions
# Version: 1.0
# Last Updated: January 4, 2026
# Shared between claude-auto and claude-auto-status
# Compatible with bash 3.2 (macOS default)

# Get service name from port number
# Usage: get_service_name <port>
# Returns: Service name string
get_service_name() {
    local port=$1
    case $port in
        8001) echo "Backend API" ;;
        5173) echo "LLM Council" ;;
        3001) echo "Workflow Generator" ;;
        3000) echo "Workflow Automation" ;;
        *) echo "Unknown Service" ;;
    esac
}

# Check service health status
# Usage: check_service_status <port>
# Returns: "healthy" | "degraded" | "stopped"
check_service_status() {
    local port=$1

    # Check if port is listening
    if ! lsof -i :"$port" -sTCP:LISTEN > /dev/null 2>&1; then
        echo "stopped"
        return
    fi

    # Port is listening - check HTTP health
    if curl -sfL -o /dev/null --max-time 2 "http://localhost:$port" 2>/dev/null; then
        echo "healthy"
    else
        echo "degraded"
    fi
}

# Format service status line for display
# Usage: format_status_line <port> <status>
# Status: "healthy" | "degraded" | "stopped"
# Outputs: Formatted status line with icon and description
format_status_line() {
    local port=$1
    local status=$2
    local service_name=$(get_service_name "$port")

    case "$status" in
        healthy)
            echo "  ✓ $service_name (port $port) - Healthy"
            ;;
        degraded)
            echo "  ⚠️  $service_name (port $port) - Running but unhealthy"
            ;;
        stopped)
            echo "  ✗ $service_name (port $port) - Stopped"
            ;;
        *)
            echo "  ? $service_name (port $port) - Unknown status: $status"
            ;;
    esac
}
