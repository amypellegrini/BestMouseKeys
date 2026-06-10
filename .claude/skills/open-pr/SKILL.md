---
name: open-pr
description: Use whenever the user asks to open a pull request for the current branch. Reviews uncommitted changes, commits them atomically (defers to the `commit` skill), pushes the branch with upstream/protected-branch safety checks, and opens the PR with `gh pr create` against `main`. Refuses to run on `main`.
---

# Open PR

Apply these steps whenever opening a pull request for the current branch.

## Pre-condition — never run on `main`

If the current branch is `main`, refuse. Pull requests are opened from feature branches; there is nothing to open against `main` itself. Surface the current branch name and stop.

The base branch is always `main`. `master`, `develop`, and per-repo base overrides are out of scope — this skill targets `main` only.

## Step 1 — review uncommitted changes

Inspect the working tree with `git status` and `git diff`. Anything not yet committed must be grouped into commits before the PR is opened — work through it in Step 2.

## Step 2 — commit outstanding work

Group related changes into atomic commits — **defer to the `commit` skill** for atomicity and Conventional Commits 1.0.0 format. One concern per commit; never bundle unrelated changes. If the `commit` skill's rules aren't already in context for this conversation, read that skill first.

Skip this step when the working tree is already clean and the branch already carries the commits to be reviewed.

## Step 3 — push the branch

Push the current branch, observing these safety conditions:

- **No upstream tracking ref** — set it as part of the push: `git push --set-upstream <remote> <branch>`.
- **Protected branch** — never push one without explicit authorization in the conversation.

The `commit-and-push` skill encodes the same conditions; when it is installed in the repo, defer to it. `open-pr` does not depend on it being present.

## Step 4 — open the PR

Run `gh pr create` against base `main`:

- **Title** — a concise summary of the branch's intent; Conventional-Commits-style where it fits.
- **Body** — a short summary of what changed and why, plus a test plan when tests were touched.

When `gh pr create` returns, report the PR URL.

> **Issue auto-close link.** When the work was driven by an issue, the PR body should link it so the issue closes on merge (e.g. `Closes #<number>` for GitHub). The exact per-tracker syntax depends on a follow-up — this version of the skill opens the PR *without* the link. Add it by hand for now if the issue should auto-close.
