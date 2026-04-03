import { api, getRepoUrl } from '../app.js';

export async function renderKanban(container) {
  const data = await api('tasks');

  if (!data || data.tasks.length === 0) {
    container.innerHTML = `
      <div class="empty">
        <div class="empty-icon">&#9638;</div>
        <div class="empty-title">No Tasks Yet</div>
        <div>Tasks appear here once the pipeline creates issues.</div>
      </div>`;
    return;
  }

  const cols = { pending: [], implementing: [], reviewing: [], merged: [] };
  for (const task of data.tasks) {
    const col = cols[task.status] || cols.pending;
    col.push(task);
  }

  const repoUrl = getRepoUrl();

  container.innerHTML = `
    <h2 class="section-title">Task Board</h2>
    <div class="kanban">
      ${renderColumn('Pending', cols.pending, repoUrl)}
      ${renderColumn('Implementing', cols.implementing, repoUrl)}
      ${renderColumn('Reviewing', cols.reviewing, repoUrl)}
      ${renderColumn('Merged', cols.merged, repoUrl)}
    </div>
  `;
}

function renderColumn(title, tasks, repoUrl) {
  return `
    <div class="kanban-col">
      <div class="kanban-col-title">${title} <span class="kanban-col-count">${tasks.length}</span></div>
      ${tasks.map(t => renderCard(t, repoUrl)).join('')}
    </div>
  `;
}

function renderCard(task, repoUrl) {
  const issueLink = repoUrl && task.issue ? `<a href="${repoUrl}/issues/${task.issue}" target="_blank">#${task.issue}</a>` : `#${task.issue || '?'}`;
  const prLink = repoUrl && task.pr ? `<a href="${repoUrl}/pull/${task.pr}" target="_blank">PR #${task.pr}</a>` : task.pr ? `PR #${task.pr}` : '';

  return `
    <div class="kanban-card">
      <div class="kanban-card-title">${issueLink} ${task.events?.[0]?.detail || ''}</div>
      <div class="kanban-card-meta">
        ${task.branch ? `<span class="mono">${task.branch}</span>` : ''}
        ${prLink}
      </div>
    </div>
  `;
}
