import { renderSession } from './components/session.js';
import { renderKanban } from './components/kanban.js';
import { renderTimeline } from './components/timeline.js';
import { renderReviews } from './components/reviews.js';
import { renderDecisions } from './components/decisions.js';
import { renderScorecards } from './components/scorecards.js';
import { renderLessons } from './components/lessons.js';

const main = document.getElementById('main');
const statusPill = document.getElementById('status-pill');

const routes = {
  session: renderSession,
  board: renderKanban,
  timeline: renderTimeline,
  reviews: renderReviews,
  decisions: renderDecisions,
  scorecards: renderScorecards,
  lessons: renderLessons,
};

let meta = {};

// ── API helper ──
export async function api(endpoint) {
  const res = await fetch(`/api/${endpoint}`);
  if (!res.ok) return null;
  return res.json();
}

export function getRepoUrl() { return meta.repoUrl || ''; }

// ── Router ──
function navigate() {
  const hash = location.hash.replace('#/', '') || 'session';
  const renderFn = routes[hash];
  if (!renderFn) return;

  document.querySelectorAll('.nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.view === hash);
  });

  main.innerHTML = '<div class="empty"><div class="empty-icon">&#8987;</div><div>Loading...</div></div>';
  renderFn(main);
}

// ── Status pill ──
async function updateStatus() {
  const session = await api('session');
  if (!session) {
    statusPill.textContent = 'No session';
    statusPill.className = 'pill pill-grey';
    return;
  }
  const phase = session.current_phase || 'unknown';
  statusPill.textContent = phase.replace(/_/g, ' ');
  statusPill.className = 'pill pill-green';
}

// ── SSE ──
function connectSSE() {
  const es = new EventSource('/events');
  es.onmessage = (e) => {
    const data = JSON.parse(e.data);
    if (data.event === 'connected') return;
    updateStatus();
    navigate(); // re-render current view
  };
  es.onerror = () => setTimeout(connectSSE, 5000);
}

// ── Init ──
async function init() {
  meta = await api('meta') || {};
  window.addEventListener('hashchange', navigate);
  if (!location.hash) location.hash = '#/session';
  navigate();
  updateStatus();
  connectSSE();
}

init();
