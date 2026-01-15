#!/bin/bash
# cleanup-instruction-files.sh v1.0 - Remove executed instruction files
CLAUDE_CODE_DIR="${CLAUDE_AUTO_WORKDIR:-$HOME/Dropbox/ALOMA/claude-code}"
TRASH_DIR="$CLAUDE_CODE_DIR/.instruction-trash"
LOG="/tmp/instruction-cleanup-$(date +%Y-%m-%d).log"

mkdir -p "$TRASH_DIR"
echo "[$(date '+%H:%M:%S')] Cleanup starting" >> "$LOG"

MOVED=0
while IFS= read -r -d '' file; do
  name=$(basename "$file")
  # Skip protected files
  [[ "$name" =~ ^(README|CHANGELOG)\.md$ ]] && continue
  [[ "$name" == *BEST_PRACTICES* || "$name" == *_PROJECT.md ]] && continue
  [[ "$file" == */docs/* || "$file" == *documentation* || "$file" == *gitbook* ]] && continue
  
  # Check if instruction file (has step markers)
  if grep -qE "(Execute from:|## STEP [0-9]+:|## ⛔ RULES)" "$file" 2>/dev/null; then
    mv "$file" "$TRASH_DIR/$(date +%Y%m%d)-$name" 2>/dev/null && ((MOVED++))
  fi
done < <(find "$CLAUDE_CODE_DIR" -name "*.md" -type f -mtime +1 -print0 2>/dev/null)

echo "[$(date '+%H:%M:%S')] Trashed: $MOVED file(s)" >> "$LOG"
find "$TRASH_DIR" -type f -mtime +7 -delete 2>/dev/null  # Purge old trash
echo "$MOVED" > /tmp/instruction-cleanup-count.txt
