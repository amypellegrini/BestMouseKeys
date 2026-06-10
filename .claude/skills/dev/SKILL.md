---
name: dev
description: Use whenever the user asks to drive a feature end-to-end — `/dev #N` picks up an existing issue, `/dev <description>` drives from scratch (BA handoff first), no arguments asks what to drive. Also responds to "dev agent" / "dev" aliases in natural-language requests. Routes to the `dev` subagent, which composes the DEV workflow (pickup → /tdd loop → commits → open-pr → /check-ci → address-pr-comments → close-issue) with load-bearing gates including repo-readiness (flags missing test harness / CI / issue tracker rather than silently skipping process), plan-mode, and AC-verification.
---

# Dev orchestrator

Slash-command entry point for driving a feature end-to-end — pickup → commits (via TDD) → PR → review handling → close. This skill is a routing layer; the actual workflow, gates, and skill composition are owned by the `dev` subagent (`.claude/agents/dev.md`). Keep this file thin so the two surfaces never drift.

## Routing

Spawn the `dev` subagent via the Agent tool, passing the user's input plus a one-line shape hint. Pick the shape from the arguments:

- `/dev #N` (or a bare issue number / Jira key) → **Pickup**. Pass the issue reference. The subagent will read the issue, validate it against the checklist, summarise it back, branch, and gate on plan-mode before any code.
- `/dev <free-text description>` → **Drive from scratch**. Pass the description verbatim. The subagent will route the BA → DEV handoff (file the issue via `/business-analyst` first if one doesn't exist yet), then drive the resulting issue end-to-end.
- `/dev` (no arguments) → **Ask**. The subagent will ask the user what to drive (pickup an existing issue or start from a description) via `AskUserQuestion` before doing anything else.

If the argument is genuinely ambiguous (e.g. could be a description *or* a stale issue reference like `5`), ask the user via AskUserQuestion before dispatching — don't guess.

## What the subagent owns (do not duplicate here)

- The full DEV workflow composition: `pickup-issue` → repeated `/tdd` (once per AC) → `commit` / `commit-and-push` → `open-pr` → `/check-ci` → `address-pr-comments` → `close-issue`.
- All load-bearing gates: repo-readiness, issue-quality, plan-mode, TDD loop, atomic-commits, review-comment classification, AC-verification, CI, post-PR CI checkpoint.
- Graceful degradation when a required atomised skill isn't installed — surface the install command (`tw-ai <skill>`) and stop.
- Reporting back: per-stage outcomes, gates that paused for approval, skills that ran, missing prerequisites.

## Why the split

The agent definition is the canonical behavioural spec. Both invocation paths — `/dev …` and natural-language ("dev agent, please drive #N") — route to the same instructions, so there is one source of truth and no drift between the slash command and the subagent.

## Cursor

Cursor has no subagent equivalent today. Cursor users invoking this rule should follow the workflow inline by reading `.claude/agents/dev.md` — same composition, same gates, but executed by the primary agent rather than spawned into its own context.
