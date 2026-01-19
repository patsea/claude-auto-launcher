#!/bin/bash
# cleanup-instruction-files.sh v2.2 - Comprehensive instruction file cleanup
# Changes from v1.0 to v2.2: Filename patterns, backup cleanup, recursive scan

CLAUDE_CODE_DIR="${1:-$HOME/Dropbox/ALOMA/claude-code}"
TRASH_DIR="$CLAUDE_CODE_DIR/.instruction-trash"
LOG="/tmp/instruction-cleanup-$(date +%Y-%m-%d).log"

mkdir -p "$TRASH_DIR"
echo "[$(date '+%H:%M:%S')] Cleanup v2.0 starting - scanning $CLAUDE_CODE_DIR" >> "$LOG"

MOVED=0
DELETED_BAK=0

# --- INSTRUCTION FILE CLEANUP (archive to trash) ---
while IFS= read -r -d '' file; do
    name=$(basename "$file")
    dir=$(dirname "$file")
    
    # Skip protected files
    [[ "$name" =~ ^(README|CHANGELOG|CLAUDE|MASTER_README)\.md$ ]] && continue
    [[ "$name" == *BEST_PRACTICES* || "$name" == *_PROJECT.md ]] && continue
    [[ "$dir" == */docs/* || "$dir" == *documentation* || "$dir" == *gitbook* ]] && continue
    [[ "$dir" == */instruction-archive/* || "$dir" == */.instruction-trash/* ]] && continue
    
    is_instruction=0
    
    # HIGH CONFIDENCE: Filename patterns
    if [[ "$name" =~ ^(FIX|UPGRADE|TEST|ADD|PITFALL)-.*\.md$ ]]; then
        is_instruction=1
    elif [[ "$name" =~ ^UPDATE-BEST-PRACTICES.*\.md$ ]]; then
        is_instruction=1
    elif [[ "$name" =~ ^UPDATE_BEST_PRACTICES.*\.md$ ]]; then
        is_instruction=1
    elif [[ "$name" == *INSTRUCTION*.md || "$name" == *PHASE*.md ]]; then
        is_instruction=1
    fi
    
    # MEDIUM CONFIDENCE: Content markers (only if filename didn't match)
    if [[ $is_instruction -eq 0 ]]; then
        if grep -qE '(\*\*Execute from\*\*:|## ⛔ RULES|## STEP [0-9]+:|### STEP [0-9]+:|Do NOT create files not listed)' "$file" 2>/dev/null; then
            is_instruction=1
        fi
    fi
    
    if [[ $is_instruction -eq 1 ]]; then
        mv "$file" "$TRASH_DIR/$(date +%Y%m%d)-$name" 2>/dev/null && ((MOVED++))
        echo "  [INSTRUCTION] $file" >> "$LOG"
    fi
done < <(find "$CLAUDE_CODE_DIR" -name "*.md" -type f -mtime +1 \
    ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/.next/*" \
    ! -path "*/dist/*" ! -path "*/build/*" ! -path "*/.instruction-trash/*" \
    ! -path "*/instruction-archive/*" -print0 2>/dev/null)

# --- BACKUP FILE CLEANUP (delete directly) ---
while IFS= read -r -d '' file; do
    name=$(basename "$file")
    # Only delete backup files older than 7 days
    rm "$file" 2>/dev/null && ((DELETED_BAK++))
    echo "  [BACKUP] Deleted: $file" >> "$LOG"
done < <(find "$CLAUDE_CODE_DIR" -type f -mtime +7 \( \
    -name "*.bak" -o -name "*.bak2" -o -name "*.step*" -o \
    -name "*.v[0-9]*.bak" -o -name "*.old" \
    \) ! -path "*/.git/*" ! -path "*/node_modules/*" -print0 2>/dev/null)

echo "[$(date '+%H:%M:%S')] Trashed: $MOVED instruction file(s), Deleted: $DELETED_BAK backup file(s)" >> "$LOG"

# Purge instruction trash older than 7 days
PURGED=$(find "$TRASH_DIR" -type f -mtime +7 -delete -print 2>/dev/null | wc -l | tr -d ' ')
[[ $PURGED -gt 0 ]] && echo "[$(date '+%H:%M:%S')] Purged: $PURGED file(s) from trash" >> "$LOG"

echo "$MOVED" > /tmp/instruction-cleanup-count.txt
# --- LOG ROTATION (compress >7d, delete >30d) ---
echo "[$(date '+%H:%M:%S')] Log rotation starting" >> "$LOG"

# Compress logs older than 7 days
COMPRESSED=0
while IFS= read -r -d '' logfile; do
    gzip -9 "$logfile" 2>/dev/null && ((COMPRESSED++))
done < <(find "$HOME/.claude-auto/logs" "$HOME/Dropbox/ALOMA/claude-code" -name "*.log" -type f -mtime +7 ! -name "*.gz" -print0 2>/dev/null)

# Delete compressed logs older than 30 days
DELETED_LOGS=$(find "$HOME/.claude-auto/logs" "$HOME/Dropbox/ALOMA/claude-code" -name "*.log.gz" -type f -mtime +30 -delete -print 2>/dev/null | wc -l | tr -d ' ')

echo "[$(date '+%H:%M:%S')] Logs: $COMPRESSED compressed, $DELETED_LOGS deleted" >> "$LOG"
