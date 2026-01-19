#!/bin/bash
# update-readme-auto.sh v2.0 - Enhanced README updater
# Updates: Recent activity + functionality descriptions from code analysis

TODAY=$(date +%Y-%m-%d)
LOG_FILE="$HOME/.claude-auto/logs/readme-update-$(date +%Y-%m-%d).log"
MARKER_START="<!-- AUTO-GENERATED: Recent Changes -->"
MARKER_END="<!-- END AUTO-GENERATED -->"
FUNC_MARKER_START="<!-- AUTO-GENERATED: Functionality -->"
FUNC_MARKER_END="<!-- END AUTO-GENERATED: Functionality -->"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

# Extract functionality from package.json, pyproject.toml, or main files
get_functionality_summary() {
    local project_dir="$1"
    local summary=""
    
    # Check package.json
    if [ -f "$project_dir/package.json" ]; then
        local desc=$(python3 -c "import json; d=json.load(open('$project_dir/package.json')); print(d.get('description',''))" 2>/dev/null)
        local scripts=$(python3 -c "import json; d=json.load(open('$project_dir/package.json')); print(', '.join(d.get('scripts',{}).keys())[:200])" 2>/dev/null)
        [ -n "$desc" ] && summary="$summary\n**Description**: $desc"
        [ -n "$scripts" ] && summary="$summary\n**Scripts**: \`$scripts\`"
    fi
    
    # Check pyproject.toml
    if [ -f "$project_dir/pyproject.toml" ]; then
        local desc=$(grep -A1 '^\[project\]' "$project_dir/pyproject.toml" 2>/dev/null | grep 'description' | sed 's/.*= *"//' | sed 's/".*//')
        [ -n "$desc" ] && summary="$summary\n**Description**: $desc"
    fi
    
    # Count key file types
    local ts_count=$(find "$project_dir" -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ')
    local py_count=$(find "$project_dir" -name "*.py" 2>/dev/null | grep -v __pycache__ | wc -l | tr -d ' ')
    local sh_count=$(find "$project_dir" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    
    local tech=""
    [ "$ts_count" -gt 0 ] && tech="TypeScript ($ts_count files)"
    [ "$py_count" -gt 0 ] && tech="$tech${tech:+, }Python ($py_count files)"
    [ "$sh_count" -gt 0 ] && tech="$tech${tech:+, }Bash ($sh_count files)"
    [ -n "$tech" ] && summary="$summary\n**Tech Stack**: $tech"
    
    # Key directories
    local key_dirs=$(ls -d "$project_dir"/*/ 2>/dev/null | grep -vE '(node_modules|\.next|dist|build|__pycache__|\.git)' | xargs -I{} basename {} | head -5 | tr '\n' ', ' | sed 's/,$//')
    [ -n "$key_dirs" ] && summary="$summary\n**Key Directories**: $key_dirs"
    
    echo -e "$summary"
}

# Get recent git activity
get_daily_changes() {
    local project_dir="$1"
    cd "$project_dir" || return 1
    
    local changed_files=$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only 2>/dev/null || echo "")
    local today_commits=$(git log --since="$TODAY 00:00:00" --oneline 2>/dev/null || echo "")
    local week_commits=$(git log --since="7 days ago" --oneline 2>/dev/null | wc -l | tr -d ' ')
    
    local file_count=$(echo "$changed_files" | grep -v "^$" | wc -l | tr -d ' ')
    local commit_count=$(echo "$today_commits" | grep -v "^$" | wc -l | tr -d ' ')
    
    echo "### Recent Activity"
    echo ""
    echo "**Last Updated**: $TODAY"
    echo "**Commits This Week**: $week_commits"
    
    if [ "$commit_count" -gt 0 ]; then
        echo ""
        echo "**Today's Commits** ($commit_count):"
        echo "$today_commits" | head -5 | while read line; do
            echo "- \`${line:0:7}\` ${line:8}"
        done
    fi
    
    if [ "$file_count" -gt 0 ]; then
        echo ""
        echo "**Recent Changes** ($file_count files):"
        echo "$changed_files" | head -10 | while read f; do
            [ -n "$f" ] && echo "- \`$f\`"
        done
        [ "$file_count" -gt 10 ] && echo "- ... and $((file_count - 10)) more"
    fi
}

# Update README with both sections
update_readme() {
    local project_dir="$1"
    local readme="$project_dir/README.md"
    
    [ ! -f "$readme" ] && return 1
    
    # Get content
    local changes_content=$(get_daily_changes "$project_dir")
    local func_content=$(get_functionality_summary "$project_dir")
    
    [ -z "$changes_content" ] && return 0
    
    local temp_readme=$(mktemp)
    local updated=0
    
    # Update activity section
    if grep -q "$MARKER_START" "$readme"; then
        local in_block=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *"$MARKER_START"* ]]; then
                echo "$MARKER_START"
                echo "$changes_content"
                echo "$MARKER_END"
                in_block=1
            elif [[ "$line" == *"$MARKER_END"* ]]; then
                in_block=0
            elif [[ $in_block -eq 0 ]]; then
                echo "$line"
            fi
        done < "$readme" > "$temp_readme"
        updated=1
    fi
    
    # Update functionality section if marker exists
    if grep -q "$FUNC_MARKER_START" "$readme" && [ -n "$func_content" ]; then
        local in_func_block=0
        local input_file="$readme"
        [ $updated -eq 1 ] && input_file="$temp_readme"
        local temp2=$(mktemp)
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == *"$FUNC_MARKER_START"* ]]; then
                echo "$FUNC_MARKER_START"
                echo -e "$func_content"
                echo "$FUNC_MARKER_END"
                in_func_block=1
            elif [[ "$line" == *"$FUNC_MARKER_END"* ]]; then
                in_func_block=0
            elif [[ $in_func_block -eq 0 ]]; then
                echo "$line"
            fi
        done < "$input_file" > "$temp2"
        
        mv "$temp2" "$temp_readme"
        updated=1
    fi
    
    if [ $updated -eq 1 ]; then
        mv "$temp_readme" "$readme"
        log "Updated: $(basename "$project_dir")"
        return 0
    fi
    
    rm -f "$temp_readme"
    return 1
}

# Main execution
log "=== README Auto-Update v2.0 Started ==="

CLAUDE_CODE_DIR="${CLAUDE_AUTO_WORKDIR:-$HOME/Dropbox/ALOMA/claude-code}"
UPDATED=0

for project_dir in "$CLAUDE_CODE_DIR"/*/; do
    [ ! -d "$project_dir/.git" ] && continue
    [ ! -f "$project_dir/README.md" ] && continue
    
    project=$(basename "$project_dir")
    [[ "$project" == "aloma-backup" || "$project" == "instruction-archive" || "$project" == "_archive" ]] && continue
    
    if update_readme "$project_dir"; then
        ((UPDATED++))
    fi
done

log "=== Complete: $UPDATED READMEs updated ==="
