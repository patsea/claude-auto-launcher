'use strict';

/**
 * lib/cleanup-instruction-files.sh, run nightly at 02:00 by claude-auto-nightly (Patrick 21 Oct 2026, round 5).
 *
 * It reached into the ALOMA Dropbox tree further than its purpose ("instruction file cleanup"):
 *   - it rotated infra/ logs and deleted them at 31 days; on 29 Sep it emptied infra/logs, the only record of the
 *     28 Aug retries;
 *   - its backup-name rule matched `*.step*`, so real files were deleted after 7 days: ALOMA step code
 *     (`slack-notification.step.mjs`) and the tracked launchd plist `io.aloma.step-git-backup.plist`;
 *   - it purged archived instruction files at 90 days;
 *   - it logged only counts, to /tmp, so what it deleted could not be answered.
 * Fixed: none of those, and every deleted path is logged by name to ~/.claude-auto/logs/cleanup-deletions.log.
 * Real backup files (*.bak and the rest) are still removed.
 *
 * The REAL script runs with HOME and the claude-code dir pointed at a temp fixture tree; files get old mtimes.
 *
 * Run:   node --test tests/cleanup-instruction-files.test.js
 * Other copy (old or installed): CLEANUP_SCRIPT=/path/to/copy node --test tests/cleanup-instruction-files.test.js
 */

const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { spawnSync } = require('node:child_process');

const SCRIPT = process.env.CLEANUP_SCRIPT || path.join(__dirname, '..', 'lib', 'cleanup-instruction-files.sh');
const DAY = 86400;

let H, CC, out;

function put(rel, ageDays, root = CC) {
  const p = path.join(root, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, `fixture ${rel}\n`);
  const t = Date.now() / 1000 - ageDays * DAY;
  fs.utimesSync(p, t, t);
  return p;
}

const FIX = {
  stepCode: 'knowledge/findings/aloma-core/billing-x/slack-notification.step.mjs',
  stepPlist: 'infra/launchd/io.aloma.step-git-backup.plist',
  bak: 'infra/scripts/foo.sh.bak',
  infraLogGz: 'infra/logs/cron-retry.log.gz',
  infraLog: 'infra/logs/cron-wrapper-notify-failures.log',
  archived: '_archive/instructions/20260601-FIX-OLD-THING-20260501.md',
};

describe('nightly cleanup leaves the ALOMA tree alone except real backup files', () => {
  before(() => {
    H = fs.mkdtempSync(path.join(os.tmpdir(), 'cleanup-test-'));
    CC = path.join(H, 'Dropbox/ALOMA/claude-code');
    fs.mkdirSync(path.join(CC, 'instructions'), { recursive: true });
    put(FIX.stepCode, 10);
    put(FIX.stepPlist, 10);
    put(FIX.bak, 10);
    put(FIX.infraLogGz, 40);
    put(FIX.infraLog, 10);
    put(FIX.archived, 100);
    put('.claude-auto/logs/audit-2026-08-01.log.gz', 40, H);   // the launcher's own logs: still rotated
    const r = spawnSync('/bin/bash', [SCRIPT, CC], { encoding: 'utf8', timeout: 60000,
      env: { PATH: process.env.PATH, HOME: H, CLEANUP_TMP_DIR: H } });
    out = r;
  });
  after(() => fs.rmSync(H, { recursive: true, force: true }));

  const exists = (rel) => fs.existsSync(path.join(CC, rel));
  const deletionsLog = () => {
    const p = path.join(H, '.claude-auto/logs/cleanup-deletions.log');
    return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : '';
  };

  it('exits 0', () => assert.equal(out.status, 0, out.stderr));
  it('still deletes a real backup file', () => assert.equal(exists(FIX.bak), false));
  it('keeps ALOMA step code (*.step.mjs)', () => assert.ok(exists(FIX.stepCode)));
  it('keeps io.aloma.step-*.plist', () => assert.ok(exists(FIX.stepPlist)));
  it('does not delete an old infra/ log', () => assert.ok(exists(FIX.infraLogGz)));
  it('does not rotate an infra/ log', () => {
    assert.ok(exists(FIX.infraLog));
    assert.equal(exists(FIX.infraLog + '.gz'), false);
  });
  it('does not purge an old archived instruction', () => assert.ok(exists(FIX.archived)));
  it('logs every deleted path by name to ~/.claude-auto/logs', () => {
    const log = deletionsLog();
    assert.match(log, new RegExp(path.join(CC, FIX.bak).replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    assert.match(log, /audit-2026-08-01\.log\.gz/);
    assert.equal(fs.existsSync(path.join(H, '.claude-auto/logs/audit-2026-08-01.log.gz')), false);
  });
});
