#!/usr/bin/env node
const express = require('express');
const path = require('path');
const fs = require('fs');
const chokidar = require('chokidar');
const { execSync } = require('child_process');

// ── CLI args ──
const args = process.argv.slice(2);
const port = parseInt(args.find((_, i, a) => a[i - 1] === '--port') || '3141');
const dir = args.find((_, i, a) => a[i - 1] === '--dir') || process.cwd();
const noOpen = args.includes('--no-open');
const factoryDir = path.join(dir, '.factory');

// ── GitHub repo URL detection ──
let repoUrl = '';
try {
  const remote = execSync('git remote get-url origin', { cwd: dir, encoding: 'utf-8' }).trim();
  repoUrl = remote.replace(/\.git$/, '').replace(/^git@github\.com:/, 'https://github.com/');
} catch {}

// ── Express setup ──
const app = express();
app.use(express.static(path.join(__dirname, 'public')));

// ── Helpers ──
function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  } catch { return null; }
}

function readJsonl(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf-8')
      .split('\n')
      .filter(line => line.trim())
      .map(line => { try { return JSON.parse(line); } catch { return null; } })
      .filter(Boolean);
  } catch { return []; }
}

function readDir(dirPath, ext = '.json') {
  try {
    const results = [];
    for (const f of fs.readdirSync(dirPath).filter(f => f.endsWith(ext))) {
      const data = readJson(path.join(dirPath, f));
      if (data) results.push({ id: f.replace(ext, ''), ...data });
    }
    return results;
  } catch { return []; }
}

// ── API Routes ──
app.get('/api/meta', (req, res) => {
  const hasFactory = fs.existsSync(factoryDir);
  res.json({ repoUrl, projectDir: dir, hasFactory });
});

app.get('/api/session', (req, res) => {
  const data = readJson(path.join(factoryDir, 'session.json'));
  if (!data) return res.status(404).json({ error: 'No active session' });
  res.json(data);
});

app.get('/api/log', (req, res) => {
  let entries = readJsonl(path.join(factoryDir, 'workflow.log'));
  if (req.query.phase) entries = entries.filter(e => e.phase === req.query.phase);
  if (req.query.action) entries = entries.filter(e => e.action === req.query.action);
  res.json(entries);
});

app.get('/api/tasks', (req, res) => {
  const session = readJson(path.join(factoryDir, 'session.json'));
  const log = readJsonl(path.join(factoryDir, 'workflow.log'));

  // Derive per-task state from log events
  const taskStates = {};
  for (const entry of log) {
    const issue = entry.refs?.issue;
    if (!issue) continue;
    if (!taskStates[issue]) taskStates[issue] = { issue, status: 'pending', events: [] };
    taskStates[issue].events.push({ action: entry.action, phase: entry.phase, ts: entry.ts, detail: entry.detail });

    if (entry.phase === 'implementation' && (entry.action === 'phase_start' || entry.action === 'invoke_codex')) taskStates[issue].status = 'implementing';
    if (entry.phase === 'code_review') taskStates[issue].status = 'reviewing';
    if (entry.phase === 'merge' && entry.status === 'ok') taskStates[issue].status = 'merged';
    if (entry.refs?.pr) taskStates[issue].pr = entry.refs.pr;
    if (entry.refs?.branch) taskStates[issue].branch = entry.refs.branch;
  }

  res.json({ tasks: Object.values(taskStates), summary: session?.tasks || {} });
});

app.get('/api/scorecards', (req, res) => {
  res.json(readDir(path.join(factoryDir, 'scorecards')));
});

app.get('/api/scorecards/:id', (req, res) => {
  const data = readJson(path.join(factoryDir, 'scorecards', `${req.params.id}.json`));
  if (!data) return res.status(404).json({ error: 'Scorecard not found' });
  res.json(data);
});

app.get('/api/lessons', (req, res) => {
  res.json(readDir(path.join(factoryDir, 'lessons')));
});

app.get('/api/report', (req, res) => {
  try {
    res.type('text/plain').send(fs.readFileSync(path.join(factoryDir, 'REPORT.md'), 'utf-8'));
  } catch { res.status(404).json({ error: 'No report' }); }
});

// ── SSE ──
const sseClients = new Set();

app.get('/events', (req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
  res.write('data: {"event":"connected"}\n\n');
  sseClients.add(res);
  req.on('close', () => sseClients.delete(res));
});

function broadcast(data) {
  const msg = `data: ${JSON.stringify(data)}\n\n`;
  for (const client of sseClients) client.write(msg);
}

// ── File watcher ──
if (fs.existsSync(factoryDir)) {
  const watcher = chokidar.watch(factoryDir, { ignoreInitial: true, persistent: true });
  watcher.on('all', (event, filePath) => {
    broadcast({ event, file: path.relative(factoryDir, filePath) });
  });
}

// ── Start ──
app.listen(port, async () => {
  const url = `http://localhost:${port}`;
  console.log(`\n  Software Factory Dashboard`);
  console.log(`  ${url}\n`);
  console.log(`  Project: ${dir}`);
  console.log(`  .factory: ${fs.existsSync(factoryDir) ? 'found' : 'not found'}\n`);

  if (!noOpen) {
    try { const open = (await import('open')).default; open(url); } catch {}
  }
});
