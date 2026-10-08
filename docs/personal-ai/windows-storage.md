# Windows Storage and Resource Plan

## Single-root policy

Use D:\OpenClaw\.

Do not create ad-hoc memory folders elsewhere. Redirect OpenClaw's supported persistent state and workspace to this root.

## Recommended paths

| Path | Purpose |
| --- | --- |
| D:\OpenClaw\state | OpenClaw mutable state, config, sessions, credentials, Logbook DB, authoritative learning state |
| D:\OpenClaw\workspace | Main agent workspace |
| D:\OpenClaw\worktrees | Managed Git worktrees |
| D:\OpenClaw\logs | Stable Gateway log file |
| D:\OpenClaw\cache | Node/OpenClaw compile cache |
| D:\OpenClaw\backups | Operator-created backups |
| D:\OpenClaw\temp | Reserved project temp space |
| D:\OpenClaw\state\learning | Personal-learning source of truth |

## What consumes space

- session/transcript state
- Logbook raw screen frames
- managed worktrees
- logs
- caches
- backups
- temporary files

The design uses short frame retention, bounded curated learning, short raw-agent-evidence retention, rolling logs, and managed worktree cleanup.

## Power / CPU / RAM

Screen observation is periodic. Learning review is periodic. The learner is a service that summarizes evidence; it is not a full second agent that continuously reasons.

Actual cost depends on capture interval, model, screen resolution, model latency, number of active sessions, and whether models run locally or remotely. A local model can consume substantial RAM/VRAM and power; a cloud model reduces local compute but sends model inputs off-device. There is no honest fixed wattage estimate without measuring the actual laptop/model.

## Locality limitation

Setting OPENCLAW_STATE_DIR and OPENCLAW_WORKSPACE_DIR controls OpenClaw's supported state/workspace locations. It cannot guarantee every dependency, OS cache, browser, or installer uses D:.

Set NODE_COMPILE_CACHE on D: and logging.file in openclaw.json on D:.

## Installation rule

Do not enable learning until the machine verifies that state, workspace, worktrees, logs, and cache resolve under D:\OpenClaw\ and the learning-stage safety policy is reviewed.

