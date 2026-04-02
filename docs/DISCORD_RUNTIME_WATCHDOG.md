# Discord Runtime Watchdog

Use this pattern when an operation depends on a Discord bot staying healthy in both:
- a **text channel** (for posting alerts, calls, or status)
- a **voice channel** (for presence, TTS, or audible alerts)

This is for **runtime health enforcement**, not just passive monitoring.

## Goal

Continuously verify a Discord runtime contract and automatically repair drift before it blocks the operation.

**health check -> self-heal -> verify -> issue/PR/review/merge if recurrence demands code or deploy fixes**

## When to use it

Use this watchdog when all of the following are true:
- the bot must remain present in a specific Discord voice channel
- the bot must be able to post in a specific text channel
- service/env drift can silently break production behavior
- a missed alert or absent voice presence has operational cost

Good examples:
- trading or betting assistants that must speak alerts live
- call/entry bots that must post in a Discord room in real time
- ops bots whose voice/text presence is part of the runbook

## Health contract

A watchdog should define a strict contract, for example:
- service A is active
- service B is active
- runtime process loaded the required env file
- required token is present in process env
- Discord text-channel API check returns `200`
- Discord voice-state check shows the bot in the expected voice channel
- recent logs do not show fresh auth or reconnect failures

If any of these fail, treat the runtime as **unhealthy**.

## Preferred verification pattern

### 1) Service health
Check that the relevant services are active.

Examples:
```bash
systemctl is-active my-bot.service my-voice-bot.service
systemctl show my-bot.service -p MainPID -p EnvironmentFiles
```

### 2) Process env health
Verify the running process actually loaded the env needed for auth.

Examples:
```bash
PID=$(systemctl show -p MainPID --value my-bot.service)
tr '\0' '\n' </proc/$PID/environ | grep '^DISCORD_TOKEN='
```

### 3) Discord API health
Check both the text and voice path.

Recommended checks:
- `GET /channels/{TEXT_CHANNEL_ID}`
- `GET /guilds/{GUILD_ID}/voice-states/{BOT_USER_ID}`

The voice-state check is critical because a process can be healthy while the bot is absent from the voice room.

### 4) Log health
Scan recent logs for fresh failures such as:
- `TokenInvalid`
- `401 Unauthorized`
- `403 Missing Access`
- `404 Unknown Channel`
- reconnect exhaustion / repeated crash loops

## Self-heal procedure

When unhealthy, use the smallest reliable recovery sequence first:

1. **Resync runtime from source-of-truth repo**
   - fix drift between deployed runtime files and repo state
2. **Restart affected services**
   - text runtime
   - voice runtime
3. **Re-run the full health contract**
4. **Repair targeted drift if still unhealthy**
   - for example, replace one stale runtime file with the repo version
5. **Retry health verification a bounded number of times**
   - avoid infinite restart loops

If self-heal restores service, send one concise operator update with:
- what was broken
- what changed
- whether text + voice are healthy again

## Escalation into Software Factory flow

If the same class of failure can recur because of code, deploy, or config design:
- open/update a canonical issue
- implement the durable fix on a branch
- open PR with factory-required sections
- run Claude review on the real PR diff
- fix blockers
- merge
- verify the runtime after deploy

This turns an operational page into a durable engineering fix.

## Common root causes

Typical failures this watchdog should catch:
- service restarts without loading the required env file
- Discord token present in config source but missing in the process env
- runtime drift between repo and deployed files
- voice bot using stale hardcoded credentials
- deploy pipeline green but voice runtime not actually restarted
- bot still allowed in the guild, but process auth invalid

## Hard rules

- Never print tokens or secrets in operator updates.
- Never assume service health implies voice presence.
- Never treat "bot left the voice channel" as cosmetic if the operation depends on speech.
- Never stop at manual repair if the root cause can recur; convert recurring incidents into repo/deploy fixes.

## Template

A public-safe hourly watchdog prompt template lives at:
- `templates/automation/discord-runtime-watchdog.prompt.md`
