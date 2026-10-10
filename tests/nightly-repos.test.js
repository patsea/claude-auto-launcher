'use strict';

/**
 * claude-auto-nightly: CLAUDE_AUTO_REPOS entries may be absolute (10 Oct 2026, when the git working
 * copies moved to ~/Dropbox/repos/<group>/) or relative to CLAUDE_AUTO_WORKDIR, and both are committed.
 *
 * The REAL auto_commit and repo_dir are sourced from bin/claude-auto-nightly and run against fixture
 * repos with a local bare remote. Nothing outside a temp dir is touched; no Slack, no heartbeat.
 *
 * Run:   node --test tests/nightly-repos.test.js
 * Mutation check: NIGHTLY_SCRIPT=/path/to/mutated-copy node --test tests/nightly-repos.test.js
 */

const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { execFileSync, spawnSync } = require('node:child_process');

const NIGHTLY = process.env.NIGHTLY_SCRIPT || path.join(__dirname, '..', 'bin', 'claude-auto-nightly');
const git = (cwd, ...a) => execFileSync('git', a, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });

let T;
function fixtureRepo(dir) {
  const remote = `${dir}.remote.git`;
  fs.mkdirSync(path.dirname(dir), { recursive: true });
  git(path.dirname(dir), 'init', '-q', '--bare', remote);
  git(path.dirname(dir), 'clone', '-q', remote, dir);
  git(dir, 'config', 'user.email', 't@example.invalid');
  git(dir, 'config', 'user.name', 't');
  fs.mkdirSync(path.join(T, 'nohooks'), { recursive: true });
  git(dir, 'config', 'core.hooksPath', path.join(T, 'nohooks'));   // no template/global hooks in the fixture
  fs.writeFileSync(path.join(dir, 'a.txt'), 'one\n');
  git(dir, 'add', 'a.txt');
  git(dir, 'commit', '-q', '-m', 'init');
  git(dir, 'push', '-q', 'origin', 'HEAD');
  fs.writeFileSync(path.join(dir, 'b.txt'), 'new work\n');   // the change the nightly must commit
  return remote;
}

function runAutoCommit(repos, workdir) {
  const script = `source "${NIGHTLY}"; CLAUDE_AUTO_WORKDIR="${workdir}"; CLAUDE_AUTO_REPOS="${repos}"; `
    + 'CLAUDE_AUTO_COMMIT_ENABLED=true; auto_commit';
  return spawnSync('/bin/bash', ['-c', script], {
    encoding: 'utf8',
    env: { ...process.env, CLAUDE_AUTO_NIGHTLY_LOG: path.join(T, 'nightly.log'), HOME: T },
  });
}

const pushed = (remote) => git(path.dirname(remote), '--git-dir', remote, 'log', '--format=%s').trim().split('\n');

describe('CLAUDE_AUTO_REPOS: absolute and relative entries', () => {
  beforeEach(() => { T = fs.mkdtempSync(path.join(os.tmpdir(), 'nightly-repos-')); });
  afterEach(() => { fs.rmSync(T, { recursive: true, force: true }); });

  it('commits and pushes a repo named by ABSOLUTE path', () => {
    const abs = path.join(T, 'repos', 'personal', 'absrepo');
    const remote = fixtureRepo(abs);
    fs.mkdirSync(path.join(T, 'work'));
    const r = runAutoCommit(abs, path.join(T, 'work'));
    assert.equal(r.status, 0, r.stderr);
    assert.match(pushed(remote)[0], /auto-commit/, `absolute entry was not committed: ${r.stdout}`);
  });

  it('still commits a repo named RELATIVE to CLAUDE_AUTO_WORKDIR', () => {
    const work = path.join(T, 'work');
    const remote = fixtureRepo(path.join(work, 'apps', 'relrepo'));
    const r = runAutoCommit('apps/relrepo', work);
    assert.equal(r.status, 0, r.stderr);
    assert.match(pushed(remote)[0], /auto-commit/, `relative entry was not committed: ${r.stdout}`);
  });

  it('repo_dir resolves ~/ entries against HOME', () => {
    const r = spawnSync('/bin/bash', ['-c', `source "${NIGHTLY}"; CLAUDE_AUTO_WORKDIR=/w; repo_dir "~/x/y"; echo; repo_dir /a/b; echo; repo_dir c/d`],
      { encoding: 'utf8', env: { ...process.env, HOME: '/h' } });
    assert.deepEqual(r.stdout.trim().split('\n'), ['/h/x/y', '/a/b', '/w/c/d']);
  });
});
