import { api } from '../app.js';

export async function renderSession(container) {
  const session = await api('session');

  if (!session) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9673;</div>
        <div class="empty-title">No Active Session</div>
        <div>Start a workflow run to see session data here.<br>The orchestrator creates <code>.factory/session.json</code> during execution.</div>
      </div>`;
    return;
  }

  const phases = ['intake', 'strategic_plan', 'issue_creation', 'tactical_plan', 'implementation', 'code_review', 'merge', 'completion'];
  const completed = session.phases_completed || [];
  const current = session.current_phase || '';
  const pct = Math.round((completed.length / phases.length) * 100);
  const t = session.tasks || {};
  const m = session.metrics || {};

  container.innerHTML = `
    <h2 class="section-title">Session: ${session.feature || 'Unknown Feature'}</h2>

    <div class="card">
      <div class="card-subtitle">TRIGGER: ${session.trigger_source || 'user'} &middot; SESSION: <span class="mono">${session.session_id || '—'}</span></div>
      <div style="margin: 16px 0 8px">
        <div style="display:flex;justify-content:space-between;font-size:13px;margin-bottom:6px">
          <span>Phase: <strong>${current.replace(/_/g, ' ')}</strong></span>
          <span>${completed.length}/${phases.length}</span>
        </div>
        <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
      </div>
      <div style="display:flex;gap:6px;flex-wrap:wrap;margin-top:12px">
        ${phases.map(p => {
          const done = completed.includes(p);
          const active = p === current;
          const cls = done ? 'badge-success' : active ? 'badge-p2' : 'badge-neutral';
          return `<span class="badge ${cls}">${p.replace(/_/g, ' ')}</span>`;
        }).join('')}
      </div>
    </div>

    <div class="grid grid-4" style="margin-top:16px">
      <div class="card metric">
        <div class="metric-value">${t.total || 0}</div>
        <div class="metric-label">Tasks Total</div>
      </div>
      <div class="card metric">
        <div class="metric-value" style="color:var(--success)">${t.completed || 0}</div>
        <div class="metric-label">Completed</div>
      </div>
      <div class="card metric">
        <div class="metric-value" style="color:var(--critical)">${t.failed || 0}</div>
        <div class="metric-label">Failed</div>
      </div>
      <div class="card metric">
        <div class="metric-value" style="color:var(--important)">${t.blocked || 0}</div>
        <div class="metric-label">Blocked</div>
      </div>
    </div>

    <div class="grid grid-3" style="margin-top:16px">
      <div class="card metric">
        <div class="metric-value">${m.retries || 0}</div>
        <div class="metric-label">Retries</div>
      </div>
      <div class="card metric">
        <div class="metric-value">${m.review_cycles || 0}</div>
        <div class="metric-label">Review Cycles</div>
      </div>
      <div class="card metric">
        <div class="metric-value">${m.lessons_generated || 0}</div>
        <div class="metric-label">Lessons Generated</div>
      </div>
    </div>

    <div class="grid grid-2" style="margin-top:16px">
      <div class="card metric">
        <div class="metric-value">${formatDuration(m.total_duration_ms)}</div>
        <div class="metric-label">Total Duration</div>
      </div>
      <div class="card metric">
        <div class="metric-value">${m.scope_violations || 0}</div>
        <div class="metric-label">Scope Violations</div>
      </div>
    </div>
  `;
}

function formatDuration(ms) {
  if (!ms) return '—';
  if (ms < 60000) return `${Math.round(ms / 1000)}s`;
  return `${Math.round(ms / 60000)}m`;
}
