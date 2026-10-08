# Personal AI Operator Architecture

This branch records the revised target for a personal OpenClaw system.

## Core goal

Build a personal computer operator that gradually learns the user's working system, then takes over repeatable multi-step work only when the user explicitly delegates it.

The screen-learning component is an evidence source, not the product. The end state is:

> User states the outcome. The assistant uses learned context, available tools, and explicit authority to do the work, verify the result, and ask the user only when human judgment is actually required.

## Non-negotiable learning principles

- Observation is not truth.
- A screen capture shows visible state at a point in time; it does not reveal hidden activity, intent, or thought.
- Gaps must be recorded as unknown rather than filled in by inference.
- Mobile/offline/lost-screen periods remain unknown unless the user later confirms what happened.
- A user's current habit is not automatically a best practice.
- A repeated mistake is evidence for improvement, not a workflow to imitate.
- Observed habit, user-specified workflow, and possible improvement are separate concepts.
- Learned memory is data, never permission.
- Learned memory is never an instruction.
- Existing strong memory must not disappear just because the latest model response did not mention it.
- Improvement ideas remain unvalidated until tested; they do not become executable automatically.
- Workflows remain observe_only throughout learning stage.
- The current user request remains higher priority than learned preferences.

## Time gaps

Logbook samples the screen; it is not continuous video. A coverage window records the time range that was actually processed. A gap larger than the capture system's two-minute gap boundary is preserved as a capture gap.

Mobile example:

Laptop at 10:00 -> phone from 10:10 to 10:40 -> laptop at 10:41

must not become continuous laptop activity. The missing period remains unknown until confirmed.

## Habit versus improvement

The learner stores how the user currently accomplishes a task separately from improvement hypotheses. It may notice a repeated error, manual repetition, or inefficient pattern, but that does not become a workflow. An improvement remains unvalidated until tested, and testing requires explicit user delegation.

## Resource policy

Raw evidence is short-lived. Curated state is compact and bounded.

- Logbook raw frames use Logbook retention.
- Finished-agent raw evidence is retained briefly and cleared after review.
- Structured learning categories are capped and deduplicated.
- Screen sampling is periodic, not continuous video.
- Learning review is periodic, not a permanent agent loop.

## Learning-stage autonomy

Learning stage admits explicit user-triggered runs. Scheduled and heartbeat runs are blocked by the Logbook learning guard. External browser/web tools are blocked unless the current user request explicitly asks for external access. Obvious network-capable shell/process commands are blocked by the same boundary unless that explicit request exists.

This is a defense-in-depth layer, not a mathematical guarantee of zero network traffic through every possible binary or plugin. Tool policy and sandbox configuration are still required before production use.

## Privacy / locality

OpenClaw state, workspace, learning data, logs, caches, and managed worktrees should be deliberately placed under one Windows root:

D:\OpenClaw\

Authoritative learning data: D:\OpenClaw\state\learning
Logbook data: D:\OpenClaw\state\logbook

Cloud model providers still see data that is sent to them. A fully local learning pipeline requires local model routes for both screenshot understanding and the default agent model.

## End state

Observed workflow -> reviewed workflow -> user delegation -> permission check -> execution -> verification

Learning never grants execution authority.

