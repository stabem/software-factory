# Software Factory Dashboard

Local web interface for monitoring LLM-Guided Software Architecture workflow runs.

## Usage

From any project that uses the Software Factory framework:

```bash
npx software-factory-dashboard
```

Or with options:

```bash
npx software-factory-dashboard --port 8080 --dir /path/to/project --no-open
```

This opens a browser at `http://localhost:3141` with a real-time dashboard showing:

- **Session** — Current workflow progress, phase status, task counts, metrics
- **Board** — Kanban view of tasks (pending → implementing → reviewing → merged)
- **Timeline** — Chronological event log with phase durations and decisions
- **Reviews** — Code review findings grouped by severity (critical/important/advisory)
- **Decisions** — Audit trail of every non-trivial orchestrator decision with rationale
- **Scorecards** — Historical spec-to-ship scores with trend visualization
- **Lessons** — Searchable knowledge base of extracted lessons with preventive rules

## How It Works

The dashboard reads JSON files from the `.factory/` directory:

| File | Content |
|------|---------|
| `.factory/session.json` | Current session state and metrics |
| `.factory/workflow.log` | JSONL audit trail of every action |
| `.factory/scorecards/*.json` | Scorecard per completed workflow run |
| `.factory/lessons/*.json` | Extracted lessons from review findings |
| `.factory/REPORT.md` | Completion report (markdown) |

The server watches these files with `chokidar` and pushes updates to the browser via Server-Sent Events. Views auto-refresh when data changes.

## Requirements

- Node.js 18+
- A project with `.factory/` directory (created by the workflow orchestrator)

## No Configuration Needed

- No database — reads JSON files directly from disk
- No authentication — runs locally only
- No build step — vanilla HTML/CSS/JS frontend
- GitHub links auto-detected from `git remote get-url origin`
