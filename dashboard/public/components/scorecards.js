import { api } from '../app.js';

export async function renderScorecards(container) {
  const scorecards = await api('scorecards');

  if (!scorecards || scorecards.length === 0) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9830;</div>
        <div class="empty-title">No Scorecards Yet</div>
        <div>Scorecards are generated when a workflow run completes (Phase 8).</div>
      </div>`;
    return;
  }

  scorecards.sort((a, b) => (b.completed_at || '').localeCompare(a.completed_at || ''));

  container.innerHTML = `
    <h2 class="section-title">Scorecard History</h2>

    ${scorecards.length > 1 ? renderTrend(scorecards) : ''}

    ${scorecards.map(renderScorecard).join('')}
  `;
}

function scoreClass(score) {
  if (score >= 90) return 'score-excellent';
  if (score >= 75) return 'score-good';
  if (score >= 60) return 'score-acceptable';
  return 'score-poor';
}

function scoreLabel(score) {
  if (score >= 90) return 'Excellent';
  if (score >= 75) return 'Good';
  if (score >= 60) return 'Acceptable';
  if (score >= 40) return 'Needs Improvement';
  return 'Poor';
}

function renderScorecard(sc) {
  const s = sc.score ?? '—';
  const q = sc.quality || {};
  const t = sc.timing || {};
  const tasks = sc.tasks || {};

  return `
    <div class="card" style="margin-bottom:16px">
      <div style="display:flex;justify-content:space-between;align-items:flex-start">
        <div>
          <div class="card-title">${sc.feature_title || 'Untitled'}</div>
          <div class="card-subtitle">
            ${sc.change_class ? `<span class="badge badge-neutral">${sc.change_class}</span>` : ''}
            ${sc.completed_at ? new Date(sc.completed_at).toLocaleDateString() : ''}
            &middot; Session: <span class="mono">${sc.session_id?.slice(0, 8) || '—'}</span>
          </div>
        </div>
        <div style="text-align:right">
          <div class="score ${scoreClass(s)}">${s}</div>
          <div style="font-size:12px;color:var(--text-muted)">${scoreLabel(s)}</div>
        </div>
      </div>

      <div class="grid grid-4" style="margin-top:16px">
        <div class="metric">
          <div class="metric-value" style="font-size:20px">${tasks.completed || 0}/${tasks.total || 0}</div>
          <div class="metric-label">Tasks</div>
        </div>
        <div class="metric">
          <div class="metric-value" style="font-size:20px">${q.review_cycles_avg?.toFixed(1) || '—'}</div>
          <div class="metric-label">Review Cycles Avg</div>
        </div>
        <div class="metric">
          <div class="metric-value" style="font-size:20px">${q.retries_total || 0}</div>
          <div class="metric-label">Retries</div>
        </div>
        <div class="metric">
          <div class="metric-value" style="font-size:20px">${formatDuration(t.total_duration_ms)}</div>
          <div class="metric-label">Duration</div>
        </div>
      </div>

      ${q.security_findings ? `
        <div style="margin-top:12px;display:flex;gap:12px;font-size:13px">
          <span>Security: </span>
          <span class="badge badge-critical">${q.security_findings.critical || 0} critical</span>
          <span class="badge badge-important">${q.security_findings.important || 0} important</span>
          <span class="badge badge-advisory">${q.security_findings.advisory || 0} advisory</span>
        </div>
      ` : ''}
    </div>
  `;
}

function renderTrend(scorecards) {
  const scores = scorecards.slice().reverse().map(s => s.score ?? 0);
  if (scores.length < 2) return '';

  const w = 400, h = 120, pad = 20;
  const max = 100, min = 0;
  const stepX = (w - pad * 2) / (scores.length - 1);
  const points = scores.map((s, i) => {
    const x = pad + i * stepX;
    const y = pad + (1 - (s - min) / (max - min)) * (h - pad * 2);
    return `${x},${y}`;
  });

  return `
    <div class="card" style="margin-bottom:16px">
      <div class="card-title">Score Trend</div>
      <svg width="${w}" height="${h}" style="width:100%;max-width:${w}px">
        <line x1="${pad}" y1="${h - pad}" x2="${w - pad}" y2="${h - pad}" stroke="var(--border)" />
        <polyline points="${points.join(' ')}" fill="none" stroke="var(--primary)" stroke-width="2" />
        ${scores.map((s, i) => {
          const x = pad + i * stepX;
          const y = pad + (1 - (s - min) / (max - min)) * (h - pad * 2);
          return `<circle cx="${x}" cy="${y}" r="4" fill="var(--primary)" />
                  <text x="${x}" y="${y - 8}" text-anchor="middle" font-size="11" fill="var(--text-muted)">${s}</text>`;
        }).join('')}
      </svg>
    </div>
  `;
}

function formatDuration(ms) {
  if (!ms) return '—';
  if (ms < 60000) return `${Math.round(ms / 1000)}s`;
  return `${Math.round(ms / 60000)}m`;
}
