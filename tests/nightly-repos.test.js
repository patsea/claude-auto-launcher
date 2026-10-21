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

// The "no company references" guard before an automatic commit and push (Pitfall 778 sweep, 21 Oct 2026).
// It was `git diff --cached | grep -qi <word>` under `set -uo pipefail`: once the staged diff outgrew the
// pipe, git took SIGPIPE, the `if` read false and the guard let the commit through. The word is built at
// run time so this file never carries it.
describe('the company-reference guard reads the whole staged diff and fails closed', () => {
  const WORD = ['al', 'oma'].join('');
  beforeEach(() => { T = fs.mkdtempSync(path.join(os.tmpdir(), 'nightly-guard-')); });
  afterEach(() => { fs.rmSync(T, { recursive: true, force: true }); });

  it('a staged diff over 64 KB with a reference near the top is NOT committed', () => {
    const dir = path.join(T, 'repos', 'personal', 'bigrepo');
    const remote = fixtureRepo(dir);
    const filler = 'ordinary line of personal notes with nothing to hide in it at all\n'.repeat(20000);
    fs.writeFileSync(path.join(dir, 'b.txt'), `${WORD} mentioned here\n${filler}`);   // ~1.3 MB
    const r = runAutoCommit(dir, T);
    assert.deepEqual(pushed(remote), ['init'], `must not commit or push:\n${r.stdout}${r.stderr}`);
    assert.match(fs.readFileSync(path.join(T, 'nightly.log'), 'utf8'), /reference detected/);
    assert.equal(git(dir, 'diff', '--cached', '--name-only').trim(), '', 'staging is reset');
  });

  it('a staged diff that cannot be read is NOT committed (fails closed)', () => {
    const dir = path.join(T, 'repos', 'personal', 'unreadable');
    const remote = fixtureRepo(dir);
    const bin = path.join(T, 'bin'); fs.mkdirSync(bin);
    const realGit = execFileSync('/usr/bin/which', ['git'], { encoding: 'utf8' }).trim();
    fs.writeFileSync(path.join(bin, 'git'),
      `#!/bin/bash\n[ "$1" = diff ] && [ "$2" = --cached ] && exit 128\nexec "${realGit}" "$@"\n`, { mode: 0o755 });
    const script = `source "${NIGHTLY}"; CLAUDE_AUTO_WORKDIR="${T}"; CLAUDE_AUTO_REPOS="${dir}"; CLAUDE_AUTO_COMMIT_ENABLED=true; auto_commit`;
    const r = spawnSync('/bin/bash', ['-c', script], { encoding: 'utf8',
      env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, CLAUDE_AUTO_NIGHTLY_LOG: path.join(T, 'nightly.log'), HOME: T } });
    assert.deepEqual(pushed(remote), ['init'], `must not commit or push:\n${r.stdout}${r.stderr}`);
    assert.match(fs.readFileSync(path.join(T, 'nightly.log'), 'utf8'), /could not read the staged diff/);
  });

  it('a small clean change is still committed and pushed', () => {
    const dir = path.join(T, 'repos', 'personal', 'clean');
    const remote = fixtureRepo(dir);
    runAutoCommit(dir, T);
    assert.equal(pushed(remote).length, 2);
  });
});
