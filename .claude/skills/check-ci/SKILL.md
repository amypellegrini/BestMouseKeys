---
name: check-ci
description: Use whenever you need to verify the CI status of the current branch's pull request — after opening a PR, after addressing review comments, or before merging. Fetches checks with `gh pr checks`, waits for pending runs to settle, and returns a single verdict (green / failing / no-CI-configured) with failing-run URLs. PR-scoped; reports only — never merges or re-runs jobs.
---

# Check CI

Apply these steps whenever verifying the CI status of the current branch's pull request — typically after `/open-pr`, after `/address-pr-comments`, or before `/close-issue`.

`check-ci` is a verification primitive. It produces a single verdict; the caller decides what to do with it. It is invoked by the `/dev` orchestrator while driving a feature autonomously, so it must wait for in-progress runs to settle and return a terminal answer rather than handing back a half-resolved state.

This skill **reports only** — it never merges, re-runs jobs, or takes any other action.

## Pre-condition — an open PR must exist

`check-ci` is PR-scoped. It reads checks via `gh pr checks`, which resolves the pull request from the current branch. If the current branch has no open PR, stop and report that — open the PR first with `/open-pr`. Verifying a bare branch with no PR is out of scope for this skill.

## Step 1 — fetch checks

Run `gh pr checks` for the current branch's PR. It exits non-zero when checks are failing *or* still pending, so capture both its output and its exit code — do not rely on exit code alone to classify the result.

## Step 2 — wait for pending runs to settle

If any check is pending or in progress, wait — do **not** return a "pending" verdict. Re-poll until every check has reached a terminal state.

Poll `gh pr checks` on a fixed interval (30–60 seconds is reasonable) until no check reports a pending or in-progress state. A polling loop is the primary mechanism here: it behaves predictably for an autonomous agent regardless of TTY, and keeps the interval and any overall timeout under the caller's control. `gh pr checks --watch` is a convenient interactive alternative when a human runs the skill directly.

The caller may be the `/dev` agent driving the feature without a human in the loop; a definitive verdict is what lets it decide the next step without a round-trip.

## Step 3 — classify the result

Once every check has settled, classify into exactly one of three verdicts:

- **green** — every check passed. The caller proceeds.
- **failing** — at least one check failed. The caller must stop and address it.
- **no-CI-configured** — `gh pr checks` reports no checks at all. The target repo has no CI wired up yet. Treat this as **proceed**: surface a note that CI was not verified, but do not block.

There is deliberately no "pending" verdict — Step 2 waits pending runs out.

## Step 4 — surface failing-run URLs

On a **failing** verdict, list each failed check together with its run URL so the caller can drill in. `gh pr checks` includes a URL for each check; surface those rather than making the caller hunt for them.

## Step 5 — return the verdict

Report a single, actionable line: the verdict (`green` / `failing` / `no-CI-configured`), plus the failing-run URLs when the verdict is `failing`. Hand control back to the caller — do not act on the verdict yourself.
