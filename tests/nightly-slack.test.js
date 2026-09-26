'use strict';

/**
 * claude-auto-nightly: the Slack summary is delivered only when Slack says so.
 *
 * The REAL send_slack_summary and finish_run are sourced from bin/claude-auto-nightly and pointed
 * at a LOCAL stub server, never Slack. `security` is stubbed on PATH, so the webhook comes from a
 * fake Keychain item and nothing real is read. The stub answers with the bodies Slack really
 * sends: `ok` on delivery, `no_service` (HTTP 200 or 404) for a revoked webhook, and so on.
 *
 * Run:   node --test tests/nightly-slack.test.js
 * Mutation check: NIGHTLY_SCRIPT=/path/to/mutated-copy node --test tests/nightly-slack.test.js
 */

const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('node:path');
const fs = require('node:fs');
const os = require('node:os');
const { spawn } = require('node:child_process');

const NIGHTLY = process.env.NIGHTLY_SCRIPT || path.join(__dirname, '..', 'bin', 'claude-auto-nightly');

let server, port;
let nextReply = { status: 200, body: 'ok' };
let requests = [];

before(async () => {
  server = http.createServer((req, res) => {
    let data = '';
    req.on('data', (c) => { data += c; });
    req.on('end', () => {
      requests.push({ url: req.url, body: data });
      res.writeHead(nextReply.status, { 'Content-Type': 'text/plain' });
      res.end(nextReply.body);
    });
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  port = server.address().port;
});
after(() => server.close());

let d, env;
beforeEach(() => {
  d = fs.mkdtempSync(path.join(os.tmpdir(), 'nightly-test-'));
  const bin = path.join(d, 'bin'); fs.mkdirSync(bin);
  // Fake Keychain: exactly one item, service oura-slack-webhook + account aloma (the shared
  // #daily-job-updates webhook), present only when STUB_WEBHOOK is set. Any other lookup fails.
  fs.writeFileSync(path.join(bin, 'security'), [
    '#!/bin/bash',
    'svc=""; acct=""; while [ $# -gt 0 ]; do case "$1" in -s) svc="$2"; shift;; -a) acct="$2"; shift;; esac; shift; done',
    'if [ "$svc" = "oura-slack-webhook" ] && [ "$acct" = "aloma" ] && [ -n "$STUB_WEBHOOK" ]; then printf \'%s\\n\' "$STUB_WEBHOOK"; exit 0; fi',
    'exit 44', ''].join('\n'));
  fs.chmodSync(path.join(bin, 'security'), 0o755);
  // Heartbeat stub: records "job status".
  const hb = path.join(d, 'heartbeat.sh');
  fs.writeFileSync(hb, `#!/bin/bash\necho "$1 $2" > "${d}/heartbeat.out"\n`);
  fs.chmodSync(hb, 0o755);
  env = { ...process.env, PATH: `${bin}:${process.env.PATH}`,
    STUB_WEBHOOK: `http://127.0.0.1:${port}/stub/nightly-webhook`,
    CLAUDE_AUTO_NIGHTLY_LOG: path.join(d, 'nightly.log'), CLAUDE_AUTO_HEARTBEAT_SCRIPT: hb };
  for (const k of ['CLAUDE_AUTO_SLACK_WEBHOOK', 'CLAUDE_AUTO_SLACK_ENABLED', 'CLAUDE_AUTO_TEST_MARKER',
    'CLAUDE_AUTO_SLACK_KEYCHAIN_SERVICE', 'CLAUDE_AUTO_SLACK_KEYCHAIN_ACCOUNT']) delete env[k];
});

function nightly(reply, envExtra = {}) {
  nextReply = reply; requests = [];
  return new Promise((resolve) => {
    const p = spawn('bash', ['-c', `source "${NIGHTLY}"; set +e; SUMMARY="• one\\n"; send_slack_summary; finish_run; echo "RC=$?"`],
      { env: { ...env, ...envExtra } });
    let out = '';
    p.stdout.on('data', (x) => { out += x; });
    p.stderr.on('data', (x) => { out += x; });
    p.on('close', () => {
      const m = out.match(/RC=(\d+)\s*$/);
      const hbFile = path.join(d, 'heartbeat.out');
      resolve({ out, rc: m ? Number(m[1]) : -1,
        heartbeat: fs.existsSync(hbFile) ? fs.readFileSync(hbFile, 'utf8').trim() : null });
    });
  });
}

function assertNotDelivered(r) {
  assert.match(r.out, /Slack summary NOT delivered/, r.out);
  assert.doesNotMatch(r.out, /delivered \(HTTP 200/);
  assert.doesNotMatch(r.out, /\bsent\b/i);
  assert.equal(r.rc, 2, 'a summary that was not delivered is a failed run');
  assert.equal(r.heartbeat, 'claude-auto-nightly failure');
}

describe('send_slack_summary judges Slack\'s reply body, not curl\'s exit code', () => {
  it('HTTP 200 `ok` is delivered: rc 0, heartbeat success, webhook from the Keychain', async () => {
    const r = await nightly({ status: 200, body: 'ok' });
    assert.match(r.out, /Slack summary delivered \(HTTP 200, body: ok\)/);
    assert.equal(r.rc, 0);
    assert.equal(r.heartbeat, 'claude-auto-nightly success');
    assert.equal(requests.length, 1);
    assert.equal(requests[0].url, '/stub/nightly-webhook');
    assert.equal(JSON.parse(requests[0].body).blocks[0].text.text, '🌙 Claude-Auto Nightly Report');
  });

  for (const [name, reply, expect] of [
    ['HTTP 200 `no_service` (revoked webhook, the old "sent" case)', { status: 200, body: 'no_service' }, /no_service/],
    ['HTTP 404 `no_service`', { status: 404, body: 'no_service' }, /HTTP 404/],
    ['HTTP 200 with an EMPTY body', { status: 200, body: '' }, /EMPTY/],
    ['HTTP 200 with a non-ok body', { status: 200, body: '<html>edge</html>' }, /<html>/],
    ['HTTP 400 invalid_payload', { status: 400, body: 'invalid_payload' }, /invalid_payload/],
    ['HTTP 503', { status: 503, body: 'service unavailable' }, /HTTP 503/],
    ['body `ok` on a non-200 status (not Slack\'s answer)', { status: 502, body: 'ok' }, /HTTP 502/],
  ]) {
    it(`${name} is NOT delivered: rc 2, heartbeat failure`, async () => {
      const r = await nightly(reply);
      assertNotDelivered(r);
      assert.match(r.out, expect);
    });
  }

  it('a curl error is NOT delivered, and the webhook is never printed', async () => {
    const r = await nightly({ status: 200, body: 'ok' }, { STUB_WEBHOOK: 'http://127.0.0.1:1/stub/do-not-print-me' });
    assertNotDelivered(r);
    assert.match(r.out, /curl exit \d+/);
    assert.doesNotMatch(r.out, /do-not-print-me/);
  });

  it('Keychain item absent: NOT delivered, nothing posted, rc 2, heartbeat failure', async () => {
    const r = await nightly({ status: 200, body: 'ok' }, { STUB_WEBHOOK: '' });
    assertNotDelivered(r);
    assert.match(r.out, /webhook unreadable \(Keychain service oura-slack-webhook, account aloma\)/);
    assert.equal(requests.length, 0);
  });

  it('forced failure: the lookup pointed at a nonexistent service is NOT delivered and posts nothing', async () => {
    const r = await nightly({ status: 200, body: 'ok' }, { CLAUDE_AUTO_SLACK_KEYCHAIN_SERVICE: 'no-such-service-selftest' });
    assertNotDelivered(r);
    assert.match(r.out, /webhook unreadable \(Keychain service no-such-service-selftest, account aloma\)/);
    assert.equal(requests.length, 0);
  });

  it('a plaintext CLAUDE_AUTO_SLACK_WEBHOOK from the config is IGNORED, never used', async () => {
    const r = await nightly({ status: 200, body: 'ok' },
      { STUB_WEBHOOK: '', CLAUDE_AUTO_SLACK_WEBHOOK: `http://127.0.0.1:${port}/plaintext-config-webhook` });
    assert.match(r.out, /CLAUDE_AUTO_SLACK_WEBHOOK in the config file is ignored/);
    assert.equal(requests.length, 0, 'the plaintext webhook must not be posted to');
    assertNotDelivered(r);
    assert.doesNotMatch(r.out, /plaintext-config-webhook/);
  });

  it('CLAUDE_AUTO_SLACK_ENABLED=false: nothing posted, rc 0, heartbeat success', async () => {
    const r = await nightly({ status: 200, body: 'ok' }, { CLAUDE_AUTO_SLACK_ENABLED: 'false' });
    assert.equal(requests.length, 0);
    assert.equal(r.rc, 0);
    assert.equal(r.heartbeat, 'claude-auto-nightly success');
  });

  it('CLAUDE_AUTO_TEST_MARKER prefixes the header of a delivery test', async () => {
    await nightly({ status: 200, body: 'ok' }, { CLAUDE_AUTO_TEST_MARKER: 'SELF-TEST-MARKER' });
    assert.equal(JSON.parse(requests[0].body).blocks[0].text.text, 'SELF-TEST-MARKER 🌙 Claude-Auto Nightly Report');
  });
});
