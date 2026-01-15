#!/bin/bash
# Helper functions for Claude Auto Launcher
# Version: 2.4
# Last Updated: January 2, 2026

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
# Enhanced: Only checks files that would actually be committed
# Returns 0 if clean, 1 if issues found
check_sensitive_data() {
    local dir=${1:-.}
    local issues_found=0
    local temp_file=$(mktemp)
    local scan_file=$(mktemp)

    echo "  Scanning for sensitive data..."

    # Determine what files to scan based on git status
    if [ -d "$dir/.git" ] || git rev-parse --git-dir > /dev/null 2>&1; then
        # We're in a git repo - only scan tracked/staged files
        local original_dir=$(pwd)
        cd "$dir" 2>/dev/null || true

        # Get list of files that would be committed (staged + tracked modified)
        git diff --cached --name-only 2>/dev/null >> "$scan_file"
        git diff --name-only 2>/dev/null >> "$scan_file"
        git ls-files --others --exclude-standard 2>/dev/null >> "$scan_file"

        # Return to original directory
        cd "$original_dir" 2>/dev/null || true

        # Remove duplicates
        sort -u "$scan_file" -o "$scan_file"

        # If no files to scan, we're clean
        if [ ! -s "$scan_file" ]; then
            echo "  ✓ No modified/staged files to scan"
            rm -f "$temp_file" "$scan_file"
            return 0
        fi

        echo "  Scanning $(wc -l < "$scan_file" | tr -d ' ') modified/staged files..."
    else
        # Not a git repo - scan all files (original behavior)
        find "$dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
             -o -name "*.py" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \
             -o -name "*.sh" -o -name "*.md" -o -name "*.env" \) \
             -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null > "$scan_file"
    fi

    # Exclusion patterns for paths (documentation, examples, tests)
    local path_exclusions="node_modules\|\.env\.example\|/examples/\|/docs/\|/test/\|/tests/\|__tests__\|\.test\.\|\.spec\.\|/fixtures/"

    # Exclusion patterns for known-safe content
    local content_exclusions="task-[a-z0-9]\|aloma task\|aloma step\|example.*key\|your.*key.*here\|<.*>\|YOUR_\|EXAMPLE_\|placeholder"

    # Scan each file for sensitive patterns
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        # Skip if file matches path exclusions
        echo "$file" | grep -q "$path_exclusions" && continue

        # Check for .env files (should never be committed)
        if echo "$file" | grep -qE "^\.env$|^\.env\.[^e]|\.env\.local$|\.env\.production$|\.env\.development$"; then
            echo "$file:1:⚠️ .env file should not be committed" >> "$temp_file"
            continue
        fi

        # Skip binary files and large files
        file_size=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
        [ "$file_size" -gt 1000000 ] && continue  # Skip files > 1MB

        # Scan file content for secrets
        # API keys with known prefixes
        grep -n -E "(sk-[a-zA-Z0-9]{20,}|sk_live_[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]{20,})" "$file" 2>/dev/null | \
            grep -vi "$content_exclusions" | while read -r line; do
                echo "$file:$line" >> "$temp_file"
            done

        # AWS credentials
        grep -n -E "AKIA[0-9A-Z]{16}" "$file" 2>/dev/null | \
            grep -vi "$content_exclusions" | while read -r line; do
                echo "$file:$line" >> "$temp_file"
            done

        # Private keys
        grep -n -E "-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----" "$file" 2>/dev/null | while read -r line; do
            echo "$file:$line" >> "$temp_file"
        done

        # Database URLs with credentials (not localhost)
        grep -n -E "(postgres|mysql|mongodb|redis)://[^:]+:[^@]+@[^l]" "$file" 2>/dev/null | \
            grep -v "localhost" | grep -vi "$content_exclusions" | while read -r line; do
                echo "$file:$line" >> "$temp_file"
            done

        # Webhook secrets
        grep -n -E "whsec_[a-zA-Z0-9]{20,}" "$file" 2>/dev/null | while read -r line; do
            echo "$file:$line" >> "$temp_file"
        done

    done < "$scan_file"

    # Remove duplicates and empty lines
    sort -u "$temp_file" -o "$temp_file" 2>/dev/null
    sed -i '' '/^$/d' "$temp_file" 2>/dev/null || sed -i '/^$/d' "$temp_file" 2>/dev/null

    # Check results
    if [ -s "$temp_file" ]; then
        echo "  ⚠️  SENSITIVE DATA DETECTED in staged/modified files:"
        echo ""
        cat "$temp_file" | head -20
        local count=$(wc -l < "$temp_file" | tr -d ' ')
        if [ "$count" -gt 20 ]; then
            echo "  ... and $((count - 20)) more issues"
        fi
        echo ""
        echo "  ACTION REQUIRED: Remove secrets before committing"
        echo ""
        echo "  If these are false positives (documentation examples), you can:"
        echo "    1. Move examples to /examples/ or /docs/ directories (auto-excluded)"
        echo "    2. Use placeholder values like '<YOUR_API_KEY>' or 'YOUR_SECRET_HERE'"
        echo "    3. Bypass with: git push --no-verify (use sparingly)"
        issues_found=1
    else
        echo "  ✓ No sensitive data in staged/modified files"
    fi

    rm -f "$temp_file" "$scan_file"
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
        # Escape regex metacharacters in pattern for literal matching
        local escaped_pattern=$(printf '%s\n' "$pattern" | sed 's/[.[\*^$]/\\&/g')
        if ! grep -qE "^${escaped_pattern}$|^${escaped_pattern}\s" "$gitignore" 2>/dev/null; then
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

    # Check for ALOMA references in public repos
    if ! check_patsea_aloma_references "$dir"; then
        failed=1
    fi

    if [ $failed -eq 1 ]; then
        echo ""
        echo "  ⚠️  Pre-flight checks found issues (services will still start)"
        echo ""
    fi

    return $failed
}

# Enhanced service health check with delayed verification
# Usage: check_service_health_enhanced <name> <port> <pid> [expected_content_pattern]
check_service_health_enhanced() {
    local name="$1"
    local port="$2"
    local pid="$3"
    local expected_pattern="${4:-}"
    local max_retries=3
    local retry_delay=5

    echo "  Verifying $name..."

    # Initial delay to let service fully start
    sleep 3

    for ((i=1; i<=max_retries; i++)); do
        # Check 1: Process still running
        if ! ps -p "$pid" > /dev/null 2>&1; then
            echo "  ✗ $name process crashed (PID $pid not found)"
            return 1
        fi

        # Check 2: Port still listening
        if ! lsof -i ":$port" -sTCP:LISTEN > /dev/null 2>&1; then
            echo "  ✗ $name not listening on port $port"
            if [ $i -lt $max_retries ]; then
                echo "    Retrying in ${retry_delay}s... ($i/$max_retries)"
                sleep $retry_delay
                continue
            fi
            return 1
        fi

        # Check 3: HTTP response
        local http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null)
        if [[ "$http_code" != "200" && "$http_code" != "307" && "$http_code" != "302" ]]; then
            echo "  ⚠️  $name returned HTTP $http_code"
        fi

        # Check 4: Expected content (if pattern provided)
        if [ -n "$expected_pattern" ]; then
            local response=$(curl -s "http://localhost:$port" 2>/dev/null)
            if ! echo "$response" | grep -qiE "$expected_pattern"; then
                echo "  ⚠️  $name missing expected content"
                if [ $i -lt $max_retries ]; then
                    echo "    Retrying in ${retry_delay}s... ($i/$max_retries)"
                    sleep $retry_delay
                    continue
                fi
            fi
        fi

        # Check 5: No error indicators in response
        local response=$(curl -s "http://localhost:$port" 2>/dev/null)
        if echo "$response" | grep -qiE "missing required|error|exception|failed to"; then
            echo "  ⚠️  $name response contains error indicators"
        fi

        echo "  ✓ $name healthy on port $port"
        return 0
    done

    return 1
}

# Check for required environment variables before starting
# Usage: check_required_env <project_dir> <project_type>
check_required_env() {
    local dir="$1"
    local type="$2"
    local missing=0

    case "$type" in
        "nextauth"|"next-auth")
            if [ -f "$dir/.env" ]; then
                grep -q "NEXTAUTH_SECRET" "$dir/.env" || {
                    echo "  ⚠️  Missing NEXTAUTH_SECRET in $dir/.env"
                    missing=1
                }
                grep -q "NEXTAUTH_URL" "$dir/.env" || {
                    echo "  ⚠️  Missing NEXTAUTH_URL in $dir/.env"
                    missing=1
                }
            else
                echo "  ⚠️  No .env file in $dir"
                missing=1
            fi
            ;;
        "fastapi"|"python")
            # Add FastAPI-specific checks here
            ;;
    esac

    return $missing
}

# Verify service didn't crash after startup
# Usage: verify_service_stable <name> <pid> <port> <delay_seconds>
verify_service_stable() {
    local name="$1"
    local pid="$2"
    local port="$3"
    local delay="${4:-5}"

    echo "  Waiting ${delay}s to verify $name stability..."
    sleep "$delay"

    if ps -p "$pid" > /dev/null 2>&1 && lsof -i ":$port" -sTCP:LISTEN > /dev/null 2>&1; then
        echo "  ✓ $name stable after ${delay}s"
        return 0
    else
        echo "  ✗ $name crashed within ${delay}s of startup"
        return 1
    fi
}

# Check for ALOMA references in patsea (public) repos
# These repos should not contain company/project branding
check_patsea_aloma_references() {
    local dir="${1:-.}"
    local issues_found=0

    # Only check if this is a patsea repo
    local remote_url=$(cd "$dir" && git remote get-url origin 2>/dev/null || echo "")

    if [[ "$remote_url" != *"patsea"* ]]; then
        # Not a patsea repo, skip check
        return 0
    fi

    echo "  Checking for ALOMA references in public repo..."

    # Search for ALOMA/aloma references (case insensitive)
    # Exclude the legitimate command patterns "aloma task" and "aloma step"
    # Exclude this helpers.sh file itself (contains the check function with ALOMA in comments)
    local aloma_refs=$(grep -rni "aloma" "$dir" \
        --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js" \
        --include="*.sh" --include="*.md" --include="*.json" --include="*.yaml" \
        --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=venv \
        --exclude-dir=__pycache__ --exclude-dir=.next --exclude-dir=dist \
        2>/dev/null | grep -v "Binary file" | grep -v "aloma task\|aloma step" | grep -v "lib/helpers.sh\|check_patsea_aloma")

    if [ -n "$aloma_refs" ]; then
        echo "  ⚠️  ALOMA REFERENCES DETECTED in public repo:"
        echo ""
        echo "$aloma_refs" | head -20
        echo ""
        echo "  Public repos (patsea/*) should not contain ALOMA branding."
        echo "  Please remove or replace these references before pushing."
        echo ""
        issues_found=1
    else
        echo "  ✓ No ALOMA references in public repo"
    fi

    return $issues_found
}
