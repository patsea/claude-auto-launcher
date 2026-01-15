# Fix Auto-Commit Scanner False Positive

**Execute from**: `~/Dropbox/ALOMA/claude-code/claude-auto-launcher`

Before executing, read best practices from: ~/Dropbox/ALOMA/claude-code/CLAUDE_CODE_UNIVERSAL_BEST_PRACTICES.md

## ⛔ RULES
- Execute EVERY step in order
- Do NOT create files not listed here
- Do NOT improvise

---

## STEP 1: Find the security check in auto_commit function

```bash
grep -n "secrets=.*git diff" bin/claude-auto-nightly
```

---

## STEP 2: Fix scanner to exclude grep patterns (self-detection)

```bash
sed -i.bak 's|grep -iE "(api\[_-\]\?key|grep -v "grep -.\*E" \| grep -iE "(api[_-]?key|' bin/claude-auto-nightly
```

If sed fails, apply manually - change line ~89 from:
```bash
secrets=$(git diff --diff-filter=ACMR -U0 2>/dev/null | \
    grep -iE "(api[_-]?key|password|secret|token).*=" | \
```
To:
```bash
secrets=$(git diff --diff-filter=ACMR -U0 2>/dev/null | \
    grep -v "grep -.*E" | \
    grep -iE "(api[_-]?key|password|secret|token).*=" | \
```

---

## STEP 3: Verify syntax

```bash
bash -n bin/claude-auto-nightly && echo "✅ Syntax valid" || echo "❌ Fix needed"
```

---

## STEP 4: Reinstall

```bash
./install.sh
echo "✅ Installed"
```

---

## STEP 5: Test scanner

```bash
cd ~/Dropbox/ALOMA/claude-code/claude-auto-launcher
~/.claude-auto/bin/claude-auto-nightly --dry-run 2>&1 | grep -E "commit|skip" | head -10
```

Expected: claude-auto-launcher should commit, not skip.
