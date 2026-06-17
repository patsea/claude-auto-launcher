#!/bin/bash
GIT_CHANGES_PENDING=0
# cleanup-instruction-files.sh v3.0 - Instruction file cleanup
# v3.0 (Jan 30, 2026): Only scan instructions/ directory, use _archive/instructions/
# v2.3 (Jan 28, 2026): Clarified docs/ directory exclusion with explicit comment
# v2.2: Filename patterns, backup cleanup, recursive scan

CLAUDE_CODE_DIR="${1:-$HOME/Dropbox/ALOMA/claude-code}"
INSTRUCTIONS_DIR="$CLAUDE_CODE_DIR/instructions"
ARCHIVE_DIR="$CLAUDE_CODE_DIR/_archive/instructions"
LOG="/tmp/instruction-cleanup-$(date +%Y-%m-%d).log"

mkdir -p "$ARCHIVE_DIR"
echo "[$(date '+%H:%M:%S')] Cleanup v3.0 starting - scanning $INSTRUCTIONS_DIR" >> "$LOG"

ARCHIVED=0
DELETED_OLD=0

# --- INSTRUCTION FILE CLEANUP (archive files older than 30 days) ---
# Only scan the instructions/ directory
if [[ -d "$INSTRUCTIONS_DIR" ]]; then
    while IFS= read -r -d '' file; do
        name=$(basename "$file")

        # Archive to _archive/instructions/ with date prefix if not already prefixed
        if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            # Already has date prefix, keep it
            mv "$file" "$ARCHIVE_DIR/$name"
            git -C "$CLAUDE_CODE_DIR" rm --cached "$file" 2>/dev/null || true
            GIT_CHANGES_PENDING=1 2>/dev/null && ((ARCHIVED++))
        else
            # Add date prefix
            mv "$file" "$ARCHIVE_DIR/$(date +%Y%m%d)-$name"
            git -C "$CLAUDE_CODE_DIR" rm --cached "$file" 2>/dev/null || true
            GIT_CHANGES_PENDING=1 2>/dev/null && ((ARCHIVED++))
        fi
        echo "  [ARCHIVED] $file" >> "$LOG"
    done < <(find "$INSTRUCTIONS_DIR" -name "*.md" -type f -mtime +30 -print0 2>/dev/null)
fi

echo "[$(date '+%H:%M:%S')] Archived: $ARCHIVED instruction file(s) older than 30 days" >> "$LOG"

# --- PURGE OLD ARCHIVED INSTRUCTIONS (older than 90 days) ---
PURGED=$(find "$ARCHIVE_DIR" -type f -mtime +90 -delete -print 2>/dev/null | wc -l | tr -d ' ')
[[ $PURGED -gt 0 ]] && echo "[$(date '+%H:%M:%S')] Purged: $PURGED file(s) older than 90 days from archive" >> "$LOG"

# --- BACKUP FILE CLEANUP (delete .bak files older than 7 days) ---
DELETED_BAK=0
while IFS= read -r -d '' file; do
    rm "$file" 2>/dev/null && ((DELETED_BAK++))
    echo "  [BACKUP] Deleted: $file" >> "$LOG"
done < <(find "$CLAUDE_CODE_DIR" -type f -mtime +7 \( \
    -name "*.bak" -o -name "*.bak2" -o -name "*.bak3" -o -name "*.bak4" -o \
    -name "*.step*" -o -name "*.v[0-9]*.bak" -o -name "*.old" -o \
    -name "*.backup-*" \
    \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/_archive/*" -print0 2>/dev/null)

[[ $DELETED_BAK -gt 0 ]] && echo "[$(date '+%H:%M:%S')] Deleted: $DELETED_BAK backup file(s)" >> "$LOG"

# --- EMPTY MONTH DIRECTORIES CLEANUP ---
# Remove empty month directories from instructions/
find "$INSTRUCTIONS_DIR" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null

# Output count for nightly report
echo "$ARCHIVED" > /tmp/instruction-cleanup-count.txt

# --- LOG ROTATION (compress >7d, delete >30d) ---
echo "[$(date '+%H:%M:%S')] Log rotation starting" >> "$LOG"

# Compress logs older than 7 days
COMPRESSED=0
while IFS= read -r -d '' logfile; do
    gzip -9 "$logfile" 2>/dev/null && ((COMPRESSED++))
done < <(find "$HOME/.claude-auto/logs" "$CLAUDE_CODE_DIR/infra" -name "*.log" -type f -mtime +7 ! -name "*.gz" -print0 2>/dev/null)

# Delete compressed logs older than 30 days
DELETED_LOGS=$(find "$HOME/.claude-auto/logs" "$CLAUDE_CODE_DIR/infra" -name "*.log.gz" -type f -mtime +30 -delete -print 2>/dev/null | wc -l | tr -d ' ')

echo "[$(date '+%H:%M:%S')] Logs: $COMPRESSED compressed, $DELETED_LOGS deleted" >> "$LOG"
# Reconcile git after archiving (prevent deleted-on-disk drift)
if [ "${GIT_CHANGES_PENDING:-0}" -eq 1 ]; then
  git -C "${CLAUDE_CODE_DIR}" commit -m "chore: archive >30d instruction files (nightly cleanup)" --no-verify 2>/dev/null || true
fi

echo "[$(date '+%H:%M:%S')] Cleanup complete" >> "$LOG"
