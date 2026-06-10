---
name: tdd
description: Use whenever the user asks to run one TDD cycle for a single acceptance criterion or AC fragment. Drives the red → green → refactor → commit loop once, then stops — the caller (`/dev` agent or human) decides whether to invoke again for the next AC. Defers to the `commit` skill for atomicity and Conventional Commits format.
---

# Test-driven development cycle (one AC)

Apply these steps whenever invoked to drive a single acceptance criterion (AC) — or AC fragment — through one TDD cycle. The skill is invoked **once per AC**; the caller (a human or the `dev` agent) decides whether to invoke again for the next AC.

## Scope

One AC per invocation. The cycle is atomic: red → green → refactor → commit, then stop. Looping over multiple ACs is the caller's job, not this skill's.

## Pre-conditions

- A feature branch already exists (created by `pickup-issue` or by hand).
- The implementation plan has already been approved via plan-mode (the `pickup-issue` skill gates this). `/tdd` does not re-ask.
- The driving issue is identifiable — either explicitly passed (e.g. `/tdd <issue> <AC>`) or the current feature branch encodes the issue reference (e.g. `feature/41-…` for a GitHub issue number, `feature/PROJ-123-…` for a Jira work-item key).

## Step 1 — pick the AC

- If an AC is passed explicitly as an argument (text or index), use it verbatim. Explicit arg always overrides inference.
- Otherwise, fetch the driving issue and pick the next AC not yet exercised by a committed test on this branch. Use the CLI matching the repo's configured issue tracker — read `issueTracker` from `.tw-ai/manifest.json`:
  - **GitHub** (`issueTracker: github`, or the field unset — GitHub is the default): `gh issue view <number>`.
  - **Jira** (`issueTracker: jira`): `acli jira workitem view <KEY>`.
- Compare the AC list to the diff against the base branch.
- If the AC feels too large for a single cycle, **stop and ask the caller to fragment it** (pass a sub-bullet or clarifying phrase). The skill does not split internally — keeping the cycle atomic depends on it.

## Step 2 — failing test (red)

- Write the smallest possible test that pins the AC fragment.
- Run the test. Confirm it fails. Read the failure message — is it failing for the **right reason**?
  - Wrong reason (e.g. import error, missing setup): fix the test scaffolding until the failure reflects the missing behaviour, not test infrastructure.
  - Right reason: proceed to Step 3.
- **If the test passes on first run**, treat it as suspect — the AC may be genuinely covered, or the test may not exercise what you think it does. Verify by temporarily breaking the production code in a way the AC predicts (delete the relevant branch, return a wrong value, comment out the call). Re-run the test:
  - The test now fails as expected → the AC is **genuinely already covered**. Revert the break. Stop the cycle and report back to the caller. No commit on this branch for this AC.
  - The test still passes despite the break → the test is **wrong**. It doesn't exercise the AC. Revert the break, rewrite the test so it pins the AC, and resume from the top of this step.

## Step 3 — make it pass (green)

- Implement the **smallest** change that makes the failing test pass. Resist scope creep.
- Run the test again. Confirm it passes.
- Run the broader test suite. Everything that was green stays green.
- If something else broke and the only way to keep it green is to make a non-minimal change, the AC fragment is likely too coarse — stop and ask the caller to split it.

## Step 4 — refactor (while green)

- Refactor only what the just-added code warrants — naming, duplication, signature shape. **Opportunistic rewrites of unrelated code belong in a separate concern** and are out of scope for this cycle.
- Run the test suite after each refactor. Stay green.

## Step 5 — commit

- Defer to the `commit` skill for atomicity and Conventional Commits 1.0.0 format.
- A single cycle may end in one commit (test + impl together) or two (test, then impl) depending on size. Let `commit`'s atomicity rule decide. A substantial refactor becomes its own `refactor:` commit.

## Step 6 — stop

- The cycle is done. Do not move to the next AC. Hand control back to the caller — the `dev` agent will invoke `/tdd` again for the next AC, or a human will.

## Failure modes (summary)

| Symptom | Prescribed response |
|---|---|
| Test passes on first run | Temporarily break the production code (Step 2). If the test catches the break: AC genuinely covered — revert, stop, report. If it doesn't: the test is wrong — rewrite. |
| AC is too large for one cycle | Stop. Ask the caller to fragment. This skill does not split internally. |
| Cannot make impl minimal without breaking other tests | Stop. Ask whether the AC fragment is right-sized or whether earlier work needs revisiting. |
| No uncovered AC identifiable from the diff | Stop and report. The issue may be done, or the AC list may need refinement (a `pickup-issue` / BA concern, not `/tdd`'s). |

## Out of scope

- Looping over multiple ACs (the caller's job).
- Plan-mode discipline (already gated upstream by `pickup-issue`).
- Test framework selection (works with whatever the repo already uses).
- Resuming a half-finished cycle (each invocation runs end-to-end).
- End-of-PR AC coverage cross-check (handled by `close-issue`'s AC-verification gate).
