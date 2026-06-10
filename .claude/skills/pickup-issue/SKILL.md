---
name: pickup-issue
description: Use whenever the user asks to start work on a specific GitHub issue ("pick up issue #N", "let's tackle #N", "take this one"). Validates the issue against the project checklist, creates the feature branch, optionally syncs the issue to "In Progress" on the active project board, and gates implementation behind plan-mode approval. Invoked as the first step of the /dev orchestrator's composition; also invocable directly by humans.
---

# Pickup issue

Apply these steps whenever invoked to start work on a specific GitHub issue. The skill validates the issue, creates a feature branch, optionally syncs the issue to "In Progress" on the active project board, and gates implementation behind plan-mode approval.

The `/dev` orchestrator invokes this as its first composed step; humans can also invoke it directly.

## Step 1 — fetch the issue

Run `gh issue view <number>` to read the issue. If the current directory's `origin` points at a different repo than where the issue lives, pass `--repo <owner>/<name>` explicitly — do **not** silently repoint `origin`.

## Step 2 — validate understanding and quality

Before any branch or code work:

- Summarise the issue back to the user in your own words to confirm you understand it correctly.
- Check the issue body for the sections this repo expects — typically Context, Scope (sketch), Acceptance criteria / out-of-scope, Manual verification, Dependencies / related. Flag any that are missing or weak.
- Ask any clarifying questions — do **not** proceed until the user confirms understanding is correct and all questions are resolved.
- If the issue is missing required sections, suggest improvements and ask the user whether to update the issue (via `/business-analyst #N` review) before continuing.

## Step 3 — sync `main` and create the feature branch

- `git pull origin main` to ensure the base is current.
- `git checkout -b feature/<issue-number>-<short-description>` — the issue number prefix is load-bearing; downstream skills (`/tdd`, `close-issue`) infer the driving issue from it.

## Step 4 — sync the issue to "In Progress" on the active project board

GitHub Projects rotate as milestones change. Never hard-code project numbers, IDs, or field IDs — resolve them fresh every time.

- Determine the project owner. Default to the repo's owner: `owner=$(gh repo view --json owner -q .owner.login)`. If projects live on a different user/org (e.g. a personal project tracking issues from an org repo), ask the user which owner to use.
- List open projects: `gh project list --owner "$owner" --format json` (filter to `closed: false` in the JSON).
- If **no open projects** exist, skip this step — the issue stays in the default backlog. Note it in the final report.
- If **exactly one** open project exists, use it.
- If **more than one** open project exists, ask the user via `AskUserQuestion` which is the active roadmap project for this repo before proceeding.
- Fetch the chosen project's field IDs fresh: `gh project field-list <number> --owner "$owner" --format json` — capture the **Status** field ID and the **"In Progress"** option ID.
- Add the issue to the project: `gh project item-add <number> --owner "$owner" --url <issue-url> --format json` — capture the returned item `id`.
- Set the status:
  ```
  gh project item-edit \
    --project-id <project-id> \
    --id <item-id> \
    --field-id <status-field-id> \
    --single-select-option-id <in-progress-option-id>
  ```

## Step 5 — verify the project sync (only when step 4 ran)

Re-fetch the issue: `gh issue view <number> --json projectItems` — confirm the project title matches and the status is **"In Progress"** before proceeding.

## Step 6 — plan-mode gate

You **MUST** enter plan mode before doing any implementation work. Read relevant code, research the codebase, and create a thorough implementation plan. Do **NOT** exit plan mode until the user has reviewed and approved the plan.

This is the single most load-bearing pause in the workflow. The orchestrator (or a human) decides next steps once the plan is approved.

## Step 7 — implement (after plan approval)

Exit plan mode and implement. When invoked via the `/dev` orchestrator, the agent then loops `/tdd` once per acceptance criterion. When invoked directly by a human, the human drives the implementation themselves.

Make atomic commits using Conventional Commits 1.0.0 — defer to the `commit` skill for the rules. Each commit should address a single concern.
