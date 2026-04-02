# Discord Runtime Watchdog Prompt Template

This template is safe to store in a **public repo**.
It contains no secrets and assumes credentials come from env / ignored local files / deployment secrets.

## Inputs to customize per runtime
- `REPO_DIR`: source-of-truth repo checkout
- `RUNTIME_DIR`: live runtime directory
- `TEXT_SERVICE`: service responsible for text posting
- `VOICE_SERVICE`: service responsible for voice presence / TTS
- `ENV_FILE`: required runtime env file
- `GUILD_ID`: Discord guild/server id
- `TEXT_CHANNEL_ID`: required text channel id
- `VOICE_CHANNEL_ID`: required voice channel id
- `BOT_USER_ID`: Discord bot/application user id
- `STATE_FILE`: local dedupe/state file path

---

Work in repo: `REPO_DIR`
Runtime dir: `RUNTIME_DIR`

This is a critical Discord runtime watchdog.
The operation is blocked if the bot cannot BOTH:
1. post in the required text channel (`TEXT_CHANNEL_ID`)
2. remain connected in the required voice channel (`VOICE_CHANNEL_ID`) inside guild `GUILD_ID`

Follow Software Factory discipline when a recurring/config/code issue is found.

## Health contract
The run is HEALTHY only if all are true:
- `TEXT_SERVICE` is active
- `VOICE_SERVICE` is active
- the runtime process uses `ENV_FILE`
- the runtime process env contains the required Discord token variable
- Discord REST check for `TEXT_CHANNEL_ID` returns `200`
- Discord voice-state check for `BOT_USER_ID` returns `channel_id=VOICE_CHANNEL_ID`
- recent logs do not show fresh auth/runtime failures such as `TokenInvalid`, `401 Unauthorized`, `Unknown Channel`, `Missing Access`, or repeated reconnect crashes

## How to check
Use local tools/commands only; never print secrets.
You may read `ENV_FILE` or process env, but redact tokens in any user-visible output.

Preferred checks:
- `systemctl is-active TEXT_SERVICE VOICE_SERVICE`
- `systemctl show TEXT_SERVICE -p MainPID -p EnvironmentFiles`
- inspect `/proc/$PID/environ` to confirm the Discord token variable exists
- use the bot token with Discord API:
  - `GET /channels/{TEXT_CHANNEL_ID}` for text health
  - `GET /guilds/{GUILD_ID}/voice-states/{BOT_USER_ID}` for actual voice presence
- inspect recent `journalctl -u TEXT_SERVICE` and `journalctl -u VOICE_SERVICE`
- verify runtime drift between `REPO_DIR` and `RUNTIME_DIR` for critical files if behavior disagrees with repo state

## Self-heal procedure
If unhealthy, act immediately in this order:
1. non-destructively resync runtime files from `REPO_DIR` to `RUNTIME_DIR`
2. restart `TEXT_SERVICE` and `VOICE_SERVICE`
3. re-run all health checks
4. if voice is still absent, explicitly verify the runtime voice entrypoint matches the repo; fix drift and restart `VOICE_SERVICE`
5. retry health verification up to 3 times total with short waits

If the watchdog restores health in-place, send a concise operator update summarizing:
- what was broken
- what you changed
- whether text + voice are both healthy again

If health still fails, or if you find repo/deploy/config drift that could recur, follow the Software Factory loop:
- investigate root cause
- create/update a GitHub issue with Outcome / In Scope / Out of Scope / Validation / Deliverables
- implement on a branch
- open PR with required factory sections
- run Claude review on the real PR diff
- fix blockers
- merge and verify deploy/runtime

## Noise control
- If everything is healthy, reply exactly `NO_REPLY`.
- If a problem is found and fixed, send one concise operator update.
- If a problem is found but not fixed, send one concise incident update with the current blocker.
- Use `STATE_FILE` as lightweight dedupe/state if needed to avoid repeated spam about the same unchanged failure.

## Hard rules
- Never print tokens or secrets.
- Never assume service health implies voice presence.
- Never leave a runtime outside the required voice channel if the operation depends on speech.
- Never stop at a manual repair if the root cause can recur; convert recurring incidents into repo/deploy fixes.
