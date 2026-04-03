import { api } from '../app.js';

export async function renderTimeline(container) {
  const log = await api('log');

  if (!log || log.length === 0) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9656;</div>
        <div class="empty-title">No Events Yet</div>
        <div>Events appear here as the pipeline executes phases.</div>
      </div>`;
    return;
  }

  const entries = log.slice().reverse(); // newest first

  container.innerHTML = `
    <h2 class="section-title">Phase Timeline</h2>
    <div class="card">
      ${entries.map(renderEntry).join('')}
    </div>
  `;
}

function renderEntry(entry) {
  const status = entry.status || 'ok';
  const dotClass = `timeline-dot-${status}`;
  const ts = entry.ts ? new Date(entry.ts).toLocaleTimeString() : '';
  const duration = entry.duration_ms ? formatDuration(entry.duration_ms) : '';

  return `
    <div class="timeline-item">
      <div class="timeline-dot ${dotClass}"></div>
      <div class="timeline-content">
        <div class="timeline-phase">${entry.phase || ''} &middot; ${entry.action || ''}</div>
        <div class="timeline-detail">${entry.detail || ''}</div>
        ${entry.decision ? `<div class="timeline-detail" style="color:var(--primary);font-style:italic">Decision: ${entry.decision}</div>` : ''}
        ${entry.error ? `<div class="timeline-detail" style="color:var(--critical)">Error: ${entry.error}</div>` : ''}
        <div class="timeline-meta">
          <span>${ts}</span>
          ${duration ? `<span>${duration}</span>` : ''}
          ${entry.tool ? `<span class="badge badge-neutral">${entry.tool}</span>` : ''}
          ${entry.refs?.issue ? `<span>Issue #${entry.refs.issue}</span>` : ''}
          ${entry.refs?.pr ? `<span>PR #${entry.refs.pr}</span>` : ''}
        </div>
      </div>
    </div>
  `;
}

function formatDuration(ms) {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  return `${(ms / 60000).toFixed(1)}m`;
}
