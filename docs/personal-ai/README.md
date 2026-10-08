# Personal AI Operator Architecture

This branch integrates a learning layer into OpenClaw itself. **OpenClaw remains the AI/agent.** The learning layer does not create a second operator or replace OpenClaw's native tools, permissions, approvals, sandboxing, browser, web access, scheduling, or execution model.

## Core goal

Let OpenClaw learn the user's working system while the user works:

- what the user prefers
- what the user is trying to accomplish
- how the user tends to solve recurring problems
- what decisions repeatedly reveal about priorities
- which tools actually work, fail, or have limits
- what the user corrects
- what outcomes succeeded or failed
- what patterns changed over time
- what remains unknown
- what the assistant predicts the user will want next

The learning layer is an **evidence-backed personal model**, not a replacement AI.

## Learning versus authority

These are deliberately separate.

**Learning capability can be high:**
- observe screen evidence
- observe user/tool evidence from OpenClaw sessions
- infer contextual intent as a hypothesis
- identify recurring workflows
- infer decision principles when evidence supports them
- compare experiences over time
- generate predictions and later mark them supported or contradicted
- identify possible improvements
- preserve uncertainty and contradictions
- feed compact learned context back into OpenClaw

**Execution authority remains controlled by OpenClaw:**
- learned memory never grants permission
- a learned workflow is not an executable command
- current user instructions outrank historical preferences
- OpenClaw's existing tool policy, sandbox, approval, and permission systems remain authoritative

This means the system does not need to become stupid in order to remain safe.

## Evidence model

The screen is only one sensor.

Evidence can come from:
- periodic screen observations and Logbook timeline cards
- user messages
- tool results and tool-use evidence exposed to the completed agent turn
- corrections and recovery events
- repeated outcomes across time

The learner treats all captured content as data. It does not treat text seen on a screen, webpage, document, codebase, email, or tool result as a new instruction to itself.

## OpenClaw's own memory

The custom learning model complements OpenClaw's native memory rather than replacing it.

The Windows installer enables OpenClaw session-memory indexing so the actual agent can recall relevant earlier private conversations. The curated learning state is then an additional compact layer for preferences, principles, intent patterns, workflows, tool experience, corrections, predictions, and uncertainty.

This is the important architecture:

**OpenClaw agent + native memory + curated personal-learning context**

not a second agent that the user must manage.

## Personal model

The structured state is compact and bounded rather than a transcript dump.

It contains:
- **preferences** — repeated or confirmed user preferences
- **decision principles** — evidence-backed patterns about what the user optimizes for
- **intent patterns** — contextual interpretations, explicitly marked as inference
- **workflow candidates** — repeated ways the user works
- **tool knowledge** — observed successes, failures, limits, and unknowns
- **experiences** — compact context/goal/action/outcome episodes
- **corrections** — before -> user correction -> lesson
- **progress** — evidence-backed change across time
- **predictions** — hypotheses that can later become supported or contradicted
- **improvements** — unvalidated opportunities, never silently promoted to execution
- **unknowns** — gaps that remain unknown instead of being guessed
- **coverage/gaps** — what the screen-learning sensor actually observed

State is merged deterministically so a later model response cannot erase established knowledge merely by omitting it.

## Time and uncertainty

Logbook is sampled, not continuous video. A capture gap is recorded as a gap.

If the user switches to a phone, works offline, closes the laptop, or otherwise disappears from the available evidence, the learner does not pretend to know what happened.

Inference is allowed where useful, but inference remains explicitly labelled and confidence/evidence-backed.

## Learning loop

The intended loop is:

**evidence -> interpretation -> compact experience -> pattern -> hypothesis -> later evidence -> confirmation/contradiction -> personal model**

Corrections are especially important because they are direct evidence about the user's expectations. Repeated corrections can change the model; one-off behavior should not automatically become a permanent preference.

Predictions are useful because they make learning measurable: the system can form a hypothesis about what the user will prefer or do, then compare it with what actually happens later.

## Learning-stage behavior

Learning stage is observation/understanding focused. It does not need to cripple OpenClaw's normal intelligence.

The learner itself does not register task-execution tools or grant itself authority. OpenClaw's native policies remain responsible for deciding what an agent run may do.

The example learning-stage configuration keeps heartbeat disabled by default, so the computer does not start performing unrelated autonomous work merely because learning is enabled.

## Privacy and locality

The intended Windows root is:

D:\OpenClaw\

Authoritative learning data:
D:\OpenClaw\state\learning

Logbook data:
D:\OpenClaw\state\logbook

Raw evidence is retained briefly and curated state is bounded.

A cloud model provider can receive data that OpenClaw sends to it. Fully local processing requires local model routes for the relevant OpenClaw models.

## End state

Learning is not the creation of a separate AI.

The desired progression is:

**OpenClaw working alongside the user -> understands the user -> predicts better -> user verifies/delegates -> OpenClaw executes using its normal authority model -> OpenClaw verifies outcomes -> experience feeds back into learning.**

Learning never needs to be deliberately made weaker than OpenClaw in order to keep execution authority controlled.
