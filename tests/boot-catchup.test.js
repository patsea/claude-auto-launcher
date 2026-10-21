'use strict';

/**
 * claude-auto-boot-catchup (option A, Patrick 21 Oct 2026).
 *
 * Its model-tasks, backup and weekly-research calls pointed at paths that no longer exist. Under
 * `set -euo pipefail` the foreground model-tasks call exited 127 and ended the run (5 times, last 24 Jun),
 * skipping cleanup and the "done" marker; weekly-research was retired on 10 Oct. The DevOps reaper catches
 * model-tasks and backup up. What remains is audit and cleanup, each run on its own with its exit code
 * logged, and the marker is always written.
 *
 * The REAL script runs with HOME pointed at a temp tree: audit and cleanup are stubs there, the heartbeat
 * file is a fixture, and BOOT_CATCHUP_NOW pins the clock to late today so every slot has passed.
 *
 * Run:   node --test tests/boot-catchup.test.js
 * Mutation check: BOOT_CATCHUP_SCRIPT=/path/to/mutated-copy node --test tests/boot-catchup.test.js
 */

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { spawnSync } = require('node:child_process');

const SCRIPT = process.env.BOOT_CATCHUP_SCRIPT || path.join(__dirname, '..', 'bin', 'claude-auto-boot-catchup');

let H;
const lateToday = () => { const d = new Date(); d.setHours(23, 50, 0, 0); return Math.floor(d.getTime() / 1000); };

function stub(name, body) {
  const p = path.join(H, '.claude-auto', 'bin', name);
  fs.writeFileSync(p, `#!/bin/bash\necho "${name} ran" >> "${H}/ran.txt"\n${body}\n`, { mode: 0o755 });
}

function run(heartbeats = {}) {
  fs.writeFileSync(path.join(H, 'Dropbox/ALOMA/claude-code/infra/state/claude-auto-heartbeats.json'), JSON.stringify(heartbeats));
  const r = spawnSync('/bin/bash', [SCRIPT], { encoding: 'utf8', timeout: 60000,
    env: { PATH: process.env.PATH, HOME: H, BOOT_CATCHUP_NOW: String(lateToday()) } });
  const ran = fs.existsSync(path.join(H, 'ran.txt')) ? fs.readFileSync(path.join(H, 'ran.txt'), 'utf8').trim().split('\n') : [];
  const log = fs.readFileSync(path.join(H, '.claude-auto/logs/boot-catchup.log'), 'utf8');
  const marker = fs.existsSync(path.join(H, '.claude-auto/.last-boot-catchup'));
  return { r, ran, log, marker };
}

describe('boot-catchup: audit and cleanup only, each isolated, marker always written', () => {
  beforeEach(() => {
    H = fs.mkdtempSync(path.join(os.tmpdir(), 'boot-catchup-'));
    fs.mkdirSync(path.join(H, '.claude-auto', 'bin'), { recursive: true });
    fs.mkdirSync(path.join(H, 'Dropbox/ALOMA/claude-code/infra/state'), { recursive: true });
  });
  afterEach(() => fs.rmSync(H, { recursive: true, force: true }));

  it('a missing audit target does not stop cleanup or the marker, and its exit code is logged', () => {
    stub('claude-auto-cleanup', 'exit 0');          // no claude-auto-audit at all: the missing target
    const { r, ran, log, marker } = run();
    assert.equal(r.status, 0, r.stderr);
    assert.deepEqual(ran, ['claude-auto-cleanup ran']);
    assert.match(log, /audit: FAILED \(exit 127\)/);
    assert.match(log, /cleanup: ok \(exit 0\)/);
    assert.ok(marker, 'the done marker is written');
  });

  it('a failing cleanup is logged with its exit code; audit still ran and the marker is written', () => {
    stub('claude-auto-audit', 'echo audit-output');
    stub('claude-auto-cleanup', 'exit 3');
    const { r, ran, log, marker } = run();
    assert.equal(r.status, 0);
    assert.deepEqual(ran, ['claude-auto-audit ran', 'claude-auto-cleanup ran']);
    assert.match(log, /audit: ok \(exit 0\)/);
    assert.match(log, /cleanup: FAILED \(exit 3\)/);
    assert.ok(marker);
  });

  it('never runs or names model-tasks, backup or weekly-research (the reaper owns two; one is retired)', () => {
    stub('claude-auto-audit', 'exit 0');
    stub('claude-auto-cleanup', 'exit 0');
    const { log } = run();
    assert.doesNotMatch(log, /model task|model-tasks|backup|weekly|research/i);
    assert.match(log, /Detected 2 missed job\(s\): audit cleanup\n/);
  });

  it('nothing missed: no job runs, the marker is written', () => {
    stub('claude-auto-audit', 'exit 0');
    stub('claude-auto-cleanup', 'exit 0');
    const today = new Date(); const y = today.getFullYear(), m = String(today.getMonth() + 1).padStart(2, '0'), d = String(today.getDate()).padStart(2, '0');
    fs.mkdirSync(path.join(H, '.claude-auto/logs'), { recursive: true });
    fs.writeFileSync(path.join(H, `.claude-auto/logs/audit-${y}-${m}-${d}.log`), 'ran at 08:00\n');
    const { ran, log, marker } = run({ 'aloma-backup': { epoch: lateToday() - 60 } });
    assert.deepEqual(ran, []);
    assert.match(log, /No missed/);
    assert.ok(marker);
  });
});
