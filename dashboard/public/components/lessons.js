import { api } from '../app.js';

export async function renderLessons(container) {
  const lessons = await api('lessons');

  if (!lessons || lessons.length === 0) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9752;</div>
        <div class="empty-title">No Lessons Yet</div>
        <div>Lessons are extracted from code review findings and accumulated over time.</div>
      </div>`;
    return;
  }

  lessons.sort((a, b) => (b.times_seen || 0) - (a.times_seen || 0));

  const scopes = [...new Set(lessons.map(l => l.scope).filter(Boolean))];
  const confidences = [...new Set(lessons.map(l => l.confidence).filter(Boolean))];

  container.innerHTML = `
    <h2 class="section-title">Lessons Knowledge Base</h2>

    <input type="text" class="search-bar" id="lesson-search" placeholder="Search lessons by pattern, root cause, or rule...">

    <div class="filter-row">
      <button class="filter-btn active" data-scope="all">All (${lessons.length})</button>
      ${scopes.map(s => `<button class="filter-btn" data-scope="${s}">${s}</button>`).join('')}
    </div>

    <div id="lessons-list">
      ${lessons.map(renderLesson).join('')}
    </div>
  `;

  // Search
  const searchInput = document.getElementById('lesson-search');
  const listEl = document.getElementById('lessons-list');

  function applyFilters() {
    const query = searchInput.value.toLowerCase();
    const activeScope = container.querySelector('.filter-btn.active')?.dataset.scope || 'all';

    let filtered = lessons;
    if (activeScope !== 'all') filtered = filtered.filter(l => l.scope === activeScope);
    if (query) filtered = filtered.filter(l =>
      (l.pattern || '').toLowerCase().includes(query) ||
      (l.root_cause || '').toLowerCase().includes(query) ||
      (l.preventive_rule || '').toLowerCase().includes(query)
    );

    listEl.innerHTML = filtered.length ? filtered.map(renderLesson).join('') :
      '<div style="padding:20px;color:var(--text-muted);text-align:center">No lessons match your filters.</div>';
  }

  searchInput.addEventListener('input', applyFilters);
  container.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      container.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      applyFilters();
    });
  });
}

function renderLesson(lesson) {
  const confClass = { high: 'badge-critical', medium: 'badge-important', low: 'badge-neutral' }[lesson.confidence] || 'badge-neutral';
  const scopeClass = { universal: 'badge-p2', 'same-stack': 'badge-important', 'this-project': 'badge-neutral' }[lesson.scope] || 'badge-neutral';

  return `
    <div class="card" style="margin-bottom:12px">
      <div style="display:flex;justify-content:space-between;align-items:flex-start">
        <div class="card-title" style="margin-bottom:4px">${lesson.pattern || 'Unknown pattern'}</div>
        <div style="display:flex;gap:6px;align-items:center">
          <span style="font-size:20px;font-weight:700">${lesson.times_seen || 1}x</span>
        </div>
      </div>

      <div style="display:flex;gap:6px;margin-bottom:8px;flex-wrap:wrap">
        <span class="badge ${confClass}">${lesson.confidence || 'unknown'}</span>
        <span class="badge ${scopeClass}">${lesson.scope || 'unknown'}</span>
        ${lesson.source_phase ? `<span class="badge badge-neutral">${lesson.source_phase}</span>` : ''}
        ${lesson.superseded_by ? '<span class="badge badge-neutral">superseded</span>' : ''}
      </div>

      ${lesson.root_cause ? `<div style="font-size:13px;margin-bottom:4px"><strong>Root cause:</strong> ${lesson.root_cause}</div>` : ''}
      <div style="font-size:13px;color:var(--success);font-weight:600">Rule: ${lesson.preventive_rule || '—'}</div>

      <div style="font-size:11px;color:var(--text-muted);margin-top:8px">
        ${lesson.id || ''} &middot; Last seen: ${lesson.last_seen ? new Date(lesson.last_seen).toLocaleDateString() : '—'}
        ${lesson.source_ref?.issue ? ` &middot; Issue #${lesson.source_ref.issue}` : ''}
        ${lesson.source_ref?.pr ? ` &middot; PR #${lesson.source_ref.pr}` : ''}
      </div>
    </div>
  `;
}
