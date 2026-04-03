import { api } from '../app.js';

export async function renderReviews(container) {
  const log = await api('log');
  if (!log) { container.innerHTML = empty(); return; }

  // Extract review-related entries
  const reviewEntries = log.filter(e => e.phase === 'code_review');
  if (reviewEntries.length === 0) { container.innerHTML = empty(); return; }

  // Try to find findings in log entries (they may be embedded in detail or stored separately)
  const findings = [];
  for (const entry of reviewEntries) {
    if (entry.action === 'finding' || entry.action === 'review_finding') {
      findings.push(entry);
    }
  }

  const critical = findings.filter(f => f.severity === 'critical' || f.detail?.includes('CRITICAL'));
  const important = findings.filter(f => f.severity === 'important' || f.detail?.includes('IMPORTANT'));
  const advisory = findings.filter(f => f.severity === 'advisory' || f.detail?.includes('ADVISORY'));

  const reviewCycles = reviewEntries.filter(e => e.action === 'invoke_claude').length;

  container.innerHTML = `
    <h2 class="section-title">Code Review</h2>

    <div class="grid grid-3" style="margin-bottom:20px">
      <div class="card metric">
        <div class="metric-value" style="color:var(--critical)">${critical.length}</div>
        <div class="metric-label">Critical</div>
      </div>
      <div class="card metric">
        <div class="metric-value" style="color:var(--important)">${important.length}</div>
        <div class="metric-label">Important</div>
      </div>
      <div class="card metric">
        <div class="metric-value" style="color:var(--advisory)">${advisory.length}</div>
        <div class="metric-label">Advisory</div>
      </div>
    </div>

    <div class="card" style="margin-bottom:16px">
      <div class="card-title">Review Activity</div>
      <div class="card-subtitle">${reviewCycles} review cycle(s) &middot; ${findings.length} total findings</div>
    </div>

    ${findings.length > 0 ? `
      <div class="card">
        <div class="card-title">Findings</div>
        ${findings.map(f => `
          <div class="finding finding-${f.severity || 'advisory'}">
            <div style="display:flex;gap:8px;align-items:center;margin-bottom:4px">
              <span class="badge badge-${f.severity || 'advisory'}">${f.severity || 'advisory'}</span>
              ${f.category ? `<span class="badge badge-neutral">${f.category}</span>` : ''}
              ${f.file ? `<span class="mono" style="font-size:12px">${f.file}${f.line ? ':' + f.line : ''}</span>` : ''}
            </div>
            <div style="font-size:14px">${f.description || f.detail || ''}</div>
            ${f.recommendation ? `<div style="font-size:13px;color:var(--text-muted);margin-top:4px">Fix: ${f.recommendation}</div>` : ''}
            ${f.root_cause ? `<div style="font-size:12px;color:var(--primary);margin-top:4px">Root cause: ${f.root_cause}</div>` : ''}
          </div>
        `).join('')}
      </div>
    ` : ''}

    ${reviewEntries.length > 0 && findings.length === 0 ? `
      <div class="card">
        <div class="card-title">Review Events</div>
        ${reviewEntries.map(e => `
          <div class="timeline-item">
            <div class="timeline-dot timeline-dot-${e.status || 'ok'}"></div>
            <div class="timeline-content">
              <div class="timeline-detail">${e.detail || e.action}</div>
              <div class="timeline-meta">
                <span>${e.ts ? new Date(e.ts).toLocaleTimeString() : ''}</span>
                ${e.duration_ms ? `<span>${(e.duration_ms / 1000).toFixed(1)}s</span>` : ''}
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    ` : ''}
  `;
}

function empty() {
  return `
    <div class="empty">
      <div class="empty-icon">&#9888;</div>
      <div class="empty-title">No Reviews Yet</div>
      <div>Review findings will appear here after the code review phase runs.</div>
    </div>`;
}
