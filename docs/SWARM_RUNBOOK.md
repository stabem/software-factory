# Swarm Registry + Monitor Runbook

This runbook implements the methodology additions in AGENTS.md/README:
- registry-driven orchestration
- deterministic monitoring loop
- PR/check-based definition of done

## 1) Files
- Registry template: `templates/swarm.tasks.example.json`
- Monitor script: `scripts/check-swarm.sh`

## 2) Setup
```bash
mkdir -p .swarm
cp templates/swarm.tasks.example.json .swarm/tasks.json
chmod +x scripts/check-swarm.sh
```

## 3) Run manually
```bash
./scripts/check-swarm.sh .swarm/tasks.json
```

Outputs:
- `SWARM_OK` when no intervention is needed
- `INFO/WARN/CRITICAL` lines when action is needed

## 4) Cron (every 10 minutes)
```bash
*/10 * * * * cd /path/to/repo && ./scripts/check-swarm.sh .swarm/tasks.json >> logs/swarm-monitor.log 2>&1
```

## 5) Alert strategy
Pipe output to your notifier (Telegram/Slack) and only forward:
- `CRITICAL` always
- `WARN` when repeated >N times

## 5.5) Claude Review Gate for PRs
Before merge, add an explicit reviewer loop around the PR:
1. open/update PR
2. run **Claude Code review** on the real GitHub diff
3. fix blocking findings in the same PR
4. rerun Claude review until no blocking findings remain
5. satisfy the remaining CI/approval policy
6. merge

Notes:
- If your runtime cannot keep a persistent thread, use one-shot Claude review and keep the same loop manually.
- If GitHub blocks self-approval by the PR author, record Claude's verdict in a PR comment and rely on the repo's remaining approval policy/admin gate.

## 6) Definition of Done automation
A task transitions to `done` only when all required gates pass:
- PR exists for the task branch (if `requirePr=true`)
- required checks are green (`review`, `ci` by default)
- PR is merged (if `requireMerged=true`)
- deploy validation is recorded (if `requireDeployValidation=true`)

Default behavior is controlled in `.swarm/tasks.json` under `defaults`.
You can override any gate per task (`requirePr`, `requireMerged`, `requireDeployValidation`).

Adjust check-name matching in `scripts/check-swarm.sh` for your org naming.

## 7) Limits
- default retry budget is 3
- set `MAX_RETRIES_DEFAULT` env var to override

## 8) Definition of Ready (DoR) field usage
Use the optional `ready` object in each task to capture pre-execution readiness:
- `problem`
- `scope`
- `validation`
- `rollback`
- `nfr`

If any readiness key is `false`, monitor emits a `WARN` signal so orchestrators can block execution until ready.

## 9) Notes
- Script is intentionally deterministic and low-token.
- For non-tmux workers, replace liveness check section with your process manager.
