#!/bin/bash
# Helper functions for Claude Auto Launcher
# Version: 2.2
# Last Updated: January 1, 2026

# Check if a service is healthy on a specific port
check_service_health() {
    local port=$1
    local service_name=$2

    # Check if port is listening
    if ! lsof -i :"$port" -sTCP:LISTEN > /dev/null 2>&1; then
        return 1  # Port not listening
    fi

    # Try to connect to the service
    if curl -sf -o /dev/null --max-time 2 "http://localhost:$port" 2>/dev/null; then
        echo "  ✓ $service_name already running and healthy on http://localhost:$port"
        return 0  # Service is healthy
    else
        # Port is open but service not responding - might be starting up or unhealthy
        return 1
    fi
}

# Kill processes on a specific port
kill_port() {
    local port=$1
    local pids=$(lsof -ti :"$port" 2>/dev/null)

    if [ -n "$pids" ]; then
        echo "  Killing existing processes on port $port..."
        echo "$pids" | xargs kill -9 2>/dev/null
        sleep 1
    fi
}

# Repair Next.js cache corruption
# Clears .next and .turbo directories to resolve webpack chunk errors
repair_nextjs_cache() {
    local project_dir=$1
    local project_name=${2:-"Next.js project"}
    local cleared=false

    if [ -d "$project_dir/.next" ]; then
        rm -rf "$project_dir/.next"
        cleared=true
    fi

    if [ -d "$project_dir/.turbo" ]; then
        rm -rf "$project_dir/.turbo"
        cleared=true
    fi

    # Also check for monorepo root .turbo
    local root_dir=$(dirname "$project_dir")
    if [ -d "$root_dir/.turbo" ]; then
        rm -rf "$root_dir/.turbo"
        cleared=true
    fi

    if [ "$cleared" = true ]; then
        echo "  ✓ Cleared build cache for $project_name"
        return 0
    else
        return 1
    fi
}

# Check for sensitive data that should not be committed to Git
# Returns 0 if clean, 1 if issues found
check_sensitive_data() {
    local dir=${1:-.}
    local issues_found=0
    local temp_file=$(mktemp)

    echo "  Scanning for sensitive data..."

    # Exclusion patterns for paths (documentation, examples, tests)
    local path_exclusions="node_modules\|\.env\.example\|/examples/\|/docs/\|/test/\|/tests/\|__tests__\|\.test\.\|\.spec\.\|/fixtures/"

    # Exclusion patterns for known-safe content
    local content_exclusions="task-[a-z0-9]\|aloma task\|aloma step\|example.*key\|your.*key.*here\|<.*>\|YOUR_\|EXAMPLE_\|placeholder"

    # High-confidence secret patterns (API keys with known prefixes)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" --include="*.json" --include="*.yaml" --include="*.yml" \
         --include="*.sh" --include="*.md" \
         -E "(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]{20,})" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" | grep -vi "$content_exclusions" >> "$temp_file"

    # AWS credentials (very specific pattern)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" --include="*.json" --include="*.yaml" --include="*.yml" \
         -E "AKIA[0-9A-Z]{16}" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" | grep -vi "$content_exclusions" >> "$temp_file"

    # Private keys (file content, not paths)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" --include="*.pem" --include="*.key" \
         -E "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" >> "$temp_file"

    # Database URLs with actual credentials (not localhost, not placeholders)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" --include="*.json" --include="*.yaml" --include="*.yml" \
         -E "(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@[^l]" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" | grep -v "localhost" | grep -vi "$content_exclusions" >> "$temp_file"

    # Hardcoded bearer tokens (actual tokens, not placeholders)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" \
         -E "Bearer [a-zA-Z0-9_-]{40,}" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" | grep -vi "$content_exclusions" >> "$temp_file"

    # Webhook secrets with actual values
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" --include="*.json" \
         -E "whsec_[a-zA-Z0-9]{20,}" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" >> "$temp_file"

    # Generic API key assignments with actual values (not placeholders)
    grep -rn --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
         --include="*.py" \
         -E "(api[_-]?key|apikey|secret[_-]?key)\s*[:=]\s*['\"][a-zA-Z0-9_-]{20,}['\"]" \
         "$dir" 2>/dev/null | grep -v "$path_exclusions" | grep -vi "$content_exclusions" >> "$temp_file"

    # Check for .env files that might be staged (not .example)
    find "$dir" -maxdepth 5 \( -name ".env" -o -name ".env.local" -o -name ".env.production" -o -name ".env.development" \) \
         -not -name "*.example" 2>/dev/null | grep -v "$path_exclusions" >> "$temp_file"

    # Remove duplicates and empty lines
    sort -u "$temp_file" -o "$temp_file"
    sed -i '' '/^$/d' "$temp_file" 2>/dev/null || sed -i '/^$/d' "$temp_file" 2>/dev/null

    # Check results
    if [ -s "$temp_file" ]; then
        echo "  ⚠️  SENSITIVE DATA DETECTED:"
        echo ""
        cat "$temp_file" | head -20
        local count=$(wc -l < "$temp_file" | tr -d ' ')
        if [ "$count" -gt 20 ]; then
            echo "  ... and $((count - 20)) more issues"
        fi
        echo ""
        echo "  ACTION REQUIRED: Move secrets to .env files and ensure .gitignore is configured"
        echo ""
        echo "  If these are false positives (documentation examples), you can:"
        echo "    1. Move examples to /examples/ or /docs/ directories (auto-excluded)"
        echo "    2. Use placeholder values like '<YOUR_API_KEY>' or 'YOUR_SECRET_HERE'"
        echo "    3. Bypass with: git push --no-verify (use sparingly)"
        issues_found=1
    else
        echo "  ✓ No sensitive data patterns detected"
    fi

    rm -f "$temp_file"
    return $issues_found
}

# Verify .gitignore has required patterns for sensitive data protection
check_gitignore_patterns() {
    local dir=${1:-.}
    local gitignore="$dir/.gitignore"
    local missing_patterns=()

    # Required patterns for sensitive data protection
    local required_patterns=(
        ".env"
        ".env.local"
        ".env.production"
        ".env*.local"
        "*.pem"
        "*.key"
        ".secret*"
        "credentials.json"
        "secrets/"
    )

    if [ ! -f "$gitignore" ]; then
        echo "  ⚠️  No .gitignore found at $gitignore"
        return 1
    fi

    for pattern in "${required_patterns[@]}"; do
        if ! grep -q "^${pattern}$\|^${pattern}\s" "$gitignore" 2>/dev/null; then
            missing_patterns+=("$pattern")
        fi
    done

    if [ ${#missing_patterns[@]} -gt 0 ]; then
        echo "  ⚠️  Missing .gitignore patterns:"
        for pattern in "${missing_patterns[@]}"; do
            echo "      - $pattern"
        done
        return 1
    else
        echo "  ✓ .gitignore has required security patterns"
        return 0
    fi
}

# Run all pre-flight checks before starting services
preflight_checks() {
    local dir=${1:-.}
    local failed=0

    echo ""
    echo "Running pre-flight checks..."

    # Check for sensitive data
    if ! check_sensitive_data "$dir"; then
        failed=1
    fi

    # Check gitignore patterns
    if ! check_gitignore_patterns "$dir"; then
        failed=1
    fi

    if [ $failed -eq 1 ]; then
        echo ""
        echo "  ⚠️  Pre-flight checks found issues (services will still start)"
        echo ""
    fi

    return $failed
}
