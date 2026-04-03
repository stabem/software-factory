import { api } from '../app.js';

export async function renderDecisions(container) {
  const [log, session] = await Promise.all([api('log'), api('session')]);

  // Merge decisions from log (action=decision) and session.decisions_log
  const decisions = [];

  if (log) {
    for (const entry of log) {
      if (entry.action === 'decision') {
        decisions.push({
          ts: entry.ts,
          phase: entry.phase,
          decision: entry.decision || entry.detail,
          rationale: entry.detail,
          refs: entry.refs,
        });
      }
    }
  }

  if (session?.decisions_log) {
    for (const d of session.decisions_log) {
      // Avoid duplicates by timestamp
      if (!decisions.find(e => e.ts === d.ts)) {
        decisions.push(d);
      }
    }
  }

  decisions.sort((a, b) => (b.ts || '').localeCompare(a.ts || '')); // newest first

  if (decisions.length === 0) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9733;</div>
        <div class="empty-title">No Decisions Recorded</div>
        <div>Decisions appear here as the orchestrator makes non-trivial choices.</div>
      </div>`;
    return;
  }

  // Collect unique phases for filter
  const phases = [...new Set(decisions.map(d => d.phase).filter(Boolean))];

  container.innerHTML = `
    <h2 class="section-title">Decisions Audit Trail</h2>

    <div class="filter-row">
      <button class="filter-btn active" data-filter="all">All (${decisions.length})</button>
      ${phases.map(p => `<button class="filter-btn" data-filter="${p}">${p.replace(/_/g, ' ')}</button>`).join('')}
    </div>

    <div class="card" id="decisions-list">
      ${decisions.map(renderDecision).join('')}
    </div>
  `;

  // Filter logic
  container.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      container.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const filter = btn.dataset.filter;
      const filtered = filter === 'all' ? decisions : decisions.filter(d => d.phase === filter);
      document.getElementById('decisions-list').innerHTML = filtered.map(renderDecision).join('');
    });
  });
}

function renderDecision(d) {
  const ts = d.ts ? new Date(d.ts).toLocaleString() : '';
  return `
    <div class="timeline-item">
      <div class="timeline-dot timeline-dot-ok"></div>
      <div class="timeline-content">
        <div class="timeline-phase">${d.phase || 'general'}</div>
        <div class="timeline-detail" style="font-weight:600">${d.decision || ''}</div>
        ${d.rationale && d.rationale !== d.decision ? `<div class="timeline-detail">${d.rationale}</div>` : ''}
        <div class="timeline-meta">
          <span>${ts}</span>
          ${d.refs?.issue ? `<span>Issue #${d.refs.issue}</span>` : ''}
          ${d.refs?.pr ? `<span>PR #${d.refs.pr}</span>` : ''}
        </div>
      </div>
    </div>
  `;
}
