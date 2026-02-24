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

## 6) Definition of Done automation
A task transitions to `done` only when:
- PR exists for the task branch
- `review` check is passed
- `ci`/`test` check is passed

Adjust check-name matching in `scripts/check-swarm.sh` for your org naming.

## 7) Limits
- default retry budget is 3
- set `MAX_RETRIES_DEFAULT` env var to override

## 8) Notes
- Script is intentionally deterministic and low-token.
- For non-tmux workers, replace liveness check section with your process manager.
