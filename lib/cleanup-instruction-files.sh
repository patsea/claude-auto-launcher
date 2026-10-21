#!/bin/bash
GIT_CHANGES_PENDING=0
# cleanup-instruction-files.sh v4.0 - Instruction file cleanup
# v4.0 (Oct 21, 2026, Patrick round 5): stays out of the ALOMA tree except real backup files, and names what it deletes.
#   Removed: the infra/ log rotation (it emptied infra/logs on 29 Sep, the only record of the 28 Aug retries);
#   `*.step*` from the backup-name rule (it matched ALOMA step code `*.step.mjs` and the tracked
#   io.aloma.step-git-backup.plist); the 90-day purge of _archive/instructions (git holds those files, and
#   nothing in the Dropbox tree is deleted by it any more). Every deleted path is now logged by name to
#   ~/.claude-auto/logs/cleanup-deletions.log; the old /tmp log held counts only.
#   Test: tests/cleanup-instruction-files.test.js.
# v3.0 (Jan 30, 2026): Only scan instructions/ directory, use _archive/instructions/
# v2.3 (Jan 28, 2026): Clarified docs/ directory exclusion with explicit comment
# v2.2: Filename patterns, backup cleanup, recursive scan

CLAUDE_CODE_DIR="${1:-$HOME/Dropbox/ALOMA/claude-code}"
INSTRUCTIONS_DIR="$CLAUDE_CODE_DIR/instructions"
ARCHIVE_DIR="$CLAUDE_CODE_DIR/_archive/instructions"
# CLEANUP_TMP_DIR overrides for tests only; claude-auto-nightly reads $TMP_DIR/instruction-cleanup-count.txt.
TMP_DIR="${CLEANUP_TMP_DIR:-/tmp}"
LOG="$TMP_DIR/instruction-cleanup-$(date +%Y-%m-%d).log"
DELETIONS_LOG="$HOME/.claude-auto/logs/cleanup-deletions.log"

mkdir -p "$ARCHIVE_DIR" "$(dirname "$DELETIONS_LOG")"
echo "[$(date '+%H:%M:%S')] Cleanup v4.0 starting - scanning $INSTRUCTIONS_DIR" >> "$LOG"

# One line per removed path, persistent (outside /tmp), so "what did the cleanup delete" has an answer.
record() {   # record <action> <path>
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $1 $2" >> "$DELETIONS_LOG"
}

ARCHIVED=0

# --- INSTRUCTION FILE CLEANUP (archive files older than 30 days: a MOVE, nothing is deleted) ---
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

# --- NO PURGE of _archive/instructions (removed v4.0): nothing in the archive is deleted. ---

# --- BACKUP FILE CLEANUP (delete backup copies older than 7 days) ---
# Backup suffixes only. NOT `*.step*`: it matched ALOMA step code (`*.step.mjs`) and io.aloma.step-*.plist.
DELETED_BAK=0
while IFS= read -r -d '' file; do
    if rm "$file" 2>/dev/null; then
        ((DELETED_BAK++))
        record "deleted-backup" "$file"
    fi
    echo "  [BACKUP] Deleted: $file" >> "$LOG"
done < <(find "$CLAUDE_CODE_DIR" -type f -mtime +7 \( \
    -name "*.bak" -o -name "*.bak2" -o -name "*.bak3" -o -name "*.bak4" -o \
    -name "*.v[0-9]*.bak" -o -name "*.old" -o \
    -name "*.backup-*" \
    \) ! -path "*/.git/*" ! -path "*/node_modules/*" ! -path "*/_archive/*" -print0 2>/dev/null)

[[ $DELETED_BAK -gt 0 ]] && echo "[$(date '+%H:%M:%S')] Deleted: $DELETED_BAK backup file(s)" >> "$LOG"

# --- EMPTY MONTH DIRECTORIES CLEANUP ---
# Remove empty month directories from instructions/
while IFS= read -r -d '' dir; do
    rmdir "$dir" 2>/dev/null && record "removed-empty-dir" "$dir"
done < <(find "$INSTRUCTIONS_DIR" -mindepth 1 -maxdepth 1 -type d -empty -print0 2>/dev/null)

# Output count for nightly report
echo "$ARCHIVED" > "$TMP_DIR/instruction-cleanup-count.txt"

# --- LOG ROTATION of the launcher's own logs only (compress >7d, delete >30d) ---
# Not $CLAUDE_CODE_DIR/infra (removed v4.0): logs there belong to DevOps and are kept by its own rotation.
echo "[$(date '+%H:%M:%S')] Log rotation starting" >> "$LOG"

COMPRESSED=0
while IFS= read -r -d '' logfile; do
    if gzip -9 "$logfile" 2>/dev/null; then
        ((COMPRESSED++))
        record "compressed" "$logfile"
    fi
done < <(find "$HOME/.claude-auto/logs" -name "*.log" -type f -mtime +7 ! -name "*.gz" ! -name "cleanup-deletions.log" -print0 2>/dev/null)

DELETED_LOGS=0
while IFS= read -r -d '' gz; do
    if rm "$gz" 2>/dev/null; then
        ((DELETED_LOGS++))
        record "deleted-old-log" "$gz"
    fi
done < <(find "$HOME/.claude-auto/logs" -name "*.log.gz" -type f -mtime +30 -print0 2>/dev/null)

echo "[$(date '+%H:%M:%S')] Logs: $COMPRESSED compressed, $DELETED_LOGS deleted" >> "$LOG"
# Reconcile git after archiving (prevent deleted-on-disk drift)
if [ "${GIT_CHANGES_PENDING:-0}" -eq 1 ]; then
  git -C "${CLAUDE_CODE_DIR}" commit -m "chore: archive >30d instruction files (nightly cleanup)" --no-verify 2>/dev/null || true
fi

echo "[$(date '+%H:%M:%S')] Cleanup complete" >> "$LOG"
exit 0
